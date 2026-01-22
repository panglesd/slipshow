open Cmarkit

type file_reader = Fpath.t -> (string option, [ `Msg of string ]) result

(** The compilation from "pure" markdown cmarkit values to compiled slipshow
    values (as extended cmarkit values) is done in several stages. The reason is
    that otherwise, the order in which we do thing on a specific node is quite
    tricky to get right... Also, I remember CMarkit mappers were limiting in
    what they allow to do: You cannot recurse on the children and then
    post-process the result
    ([let to_post_process = Tast_iterator.default_iterator.node my_iterator node
      in ...])

    The first stage is doing the following:
    - Block quotes are turned into Divs,
    - [slip-script] code blocks are turned into slip scripts,
    - [includes] are included, with the first stage runned on them,
    - Images src are relativized,
    - Images are turned into audio/video depending on the attributes/extension
    - Attributes are suffixed with [-at-unpause]
    - BlockS are grouped on divs by [---]

    The second stage is doing the following:
    - [children:...] attributes are passed to children

    The third stage is doing the following:
    - [blockquote] attributed elements are turned into block quotes
    - [slip] attributed elements are turned into slips
    - [slide] attributed elements are turned into slides
    - [carousel] attributed elements are turned into carousels

    The fourth stage is populating the media files map, and the ID map. *)

module Log_errors : sig
  val with_ : (unit -> 'a) -> 'a * Errors.t list
  val add : Errors.t -> unit
end = struct
  let errors_acc = ref []
  let add x = errors_acc := x :: !errors_acc

  let with_ f =
    let old_errors = !errors_acc in
    errors_acc := [];
    let clean_up () =
      let errors = !errors_acc in
      errors_acc := old_errors;
      errors
    in
    try
      let res = f () in
      (res, clean_up ())
    with exn ->
      let _ = clean_up in
      raise exn
end

module Path_entering : sig
  (** Path are relative to the file we are reading. When we include a file we
      need to interpret the path as relative to it.

      Since we only have access to fold and maps, but not to "lift maps", we use
      some state. *)

  type t

  val make : unit -> t
  val in_path : t -> Fpath.t -> (unit -> 'a) -> 'a
  val relativize : t -> Fpath.t -> Fpath.t
end = struct
  type t = Fpath.t Stack.t

  let make = Stack.create

  let in_path path_stack p f =
    Stack.push p path_stack;
    let res = f () in
    ignore @@ Stack.pop path_stack;
    res

  let relativize path_stack p =
    let rec do_ l acc =
      match l with [] -> acc | p :: q -> do_ q (Fpath.( // ) p acc)
    in
    do_ (path_stack |> Stack.to_seq |> List.of_seq) p |> Fpath.normalize
end

module Id : sig
  val gen : unit -> string
end = struct
  let i = ref 0

  let gen () =
    let res = "__slipshow__id__" ^ string_of_int !i in
    incr i;
    res
end

let classify_image p =
  match Fpath.get_ext p with
  | ".3gp" | ".mpg" | ".mpeg" | ".mp4" | ".m4v" | ".m4p" | ".ogv" | ".ogg"
  | ".mov" | ".webm" ->
      `Video
  | ".aac" | ".flac" | ".mp3" | ".oga" | ".wav" -> `Audio
  | ".pdf" -> `Pdf
  | ".apng" | ".avif" | ".gif" | ".jpeg" | ".jpg" | ".jpe" | ".jig" | ".jfif"
  | ".png" | ".webp" ->
      (* https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types#image_types *)
      `Image
  | ".svg" -> `Svg
  | ".draw" -> `Draw
  | _ -> `Image

let resolve_file ps s =
  match Asset.Uri.of_string s with
  | Link s -> Asset.Uri.Link s
  | Path p -> Path (Path_entering.relativize ps p)

module Stage1 = struct
  let turn_block_quotes_into_divs m ((bq, (attrs, meta2)), meta) =
    let b = Block.Block_quote.block bq in
    let b =
      match Mapper.map_block m b with None -> Block.empty | Some b -> b
    in
    let attrs = Mapper.map_attrs m attrs in
    Mapper.ret (Ast.div ((b, (attrs, meta2)), meta))

  let handle_slip_scripts_creation m ((cb, (attrs, meta)), meta2) =
    match Block.Code_block.info_string cb with
    | None -> Mapper.default
    | Some (info, _) -> (
        match Block.Code_block.language_of_info_string info with
        | Some ("slip-script", _) ->
            Mapper.ret
              (Ast.slipscript ((cb, (Mapper.map_attrs m attrs, meta)), meta2))
        | _ -> Mapper.default)

  let handle_includes read_file current_path m (attrs, meta) =
    match (Attributes.find "include" attrs, Attributes.find "src" attrs) with
    | Some (_, None), Some (_, Some ({ v = src; _ }, _)) -> (
        let relativized_path =
          Path_entering.relativize current_path (Fpath.v src)
        in
        match read_file relativized_path with
        | Error (`Msg err) ->
            Logs.warn (fun m ->
                m "Could not read %a: %s" Fpath.pp relativized_path err);
            Mapper.default
        | Ok None -> Mapper.default
        | Ok (Some contents) -> (
            let md =
              Cmarkit.Doc.of_string ~heading_auto_ids:false ~strict:false
                contents
            in
            Path_entering.in_path current_path (Fpath.parent (Fpath.v src))
            @@ fun () ->
            match Mapper.map_block m (Doc.block md) with
            | None -> Mapper.default
            | Some mapped_blocks ->
                let attrs = Mapper.map_attrs m attrs in
                Mapper.ret
                  (Ast.included ((mapped_blocks, (attrs, meta)), Meta.none))))
    | _ -> Mapper.default

  let get_link_definition (defs : Cmarkit.Label.defs) l =
    match Inline.Link.reference_definition defs l with
    | Some (Cmarkit.Link_definition.Def ld) -> Some ld
    | _ -> None

  let classify_link_definition (ld : Cmarkit.Link_definition.t) attrs =
    let has_attrs x = Cmarkit.Attributes.find x attrs |> Option.is_some in
    if has_attrs "video" then `Video
    else if has_attrs "audio" then `Audio
    else if has_attrs "image" then `Image
    else if has_attrs "svg" then `Svg
    (* else if has_attrs "pdf" then `Pdf *)
    (* else if has_attrs "draw" then `Draw
       We don't want to pollute too much the namespace.  *)
      else
      let d, _meta = Cmarkit.Link_definition.dest ld in
      match Fpath.of_string d with
      | Error _ -> `Image
      | Ok p -> classify_image p

  let update_link_definition current_path (ld, meta) =
    let label, layout, defined_label, (dest, meta_dest), title =
      Link_definition.(label ld, layout ld, defined_label ld, dest ld, title ld)
    in
    let uri = resolve_file current_path dest in
    let dest = (Asset.Uri.to_string uri, meta_dest) in
    ( (uri, meta),
      Link_definition.make ~layout ~defined_label ?label ~dest ?title () )

  let handle_image_inlining m defs current_path ((l, (attrs, meta2)), meta) =
    let text = Inline.Link.text l in
    let ( let* ) x f = match x with None -> Mapper.default | Some x -> f x in
    let* kind, ld, uri =
      match get_link_definition defs l with
      | None -> None
      | Some ((ld, (attrs_ld, meta2)), meta) ->
          let attrs =
            Cmarkit.Attributes.merge ~base:attrs ~new_attrs:attrs_ld
          in
          let kind = classify_link_definition ld attrs in
          let attrs_ld = Mapper.map_attrs m attrs_ld in
          let dest, ld = update_link_definition current_path (ld, meta) in
          Some (kind, ((ld, (attrs_ld, meta2)), meta), dest)
    in
    let reference = `Inline ld in
    let l = Inline.Link.make text reference in
    let attrs = Mapper.map_attrs m attrs in
    let origin = ((l, (attrs, meta2)), meta) in
    match kind with
    | `Image -> Mapper.ret @@ Ast.image { uri; origin; id = Id.gen () }
    | `Svg -> Mapper.ret @@ Ast.svg { uri; origin; id = Id.gen () }
    | `Video -> Mapper.ret @@ Ast.video { uri; origin; id = Id.gen () }
    | `Audio -> Mapper.ret @@ Ast.audio { uri; origin; id = Id.gen () }
    | `Draw -> Mapper.ret @@ Ast.hand_drawn { uri; origin; id = Id.gen () }
    | `Pdf -> Mapper.ret @@ Ast.pdf { uri; origin; id = Id.gen () }

  let handle_dash_separated_blocks m (blocks, meta) =
    let div ((attrs, am), blocks) =
      let attrs = Mapper.map_attrs m attrs in
      let blocks =
        match blocks with
        | [ b ] -> Mapper.map_block m b
        | blocks -> Mapper.map_block m @@ Block.Blocks (blocks, Meta.none)
      in
      match blocks with
      | None -> None
      | Some blocks -> Some (Ast.div ((blocks, (attrs, am)), Meta.none))
    in
    let find_biggest blocks =
      let find_biggest biggest block =
        let max x = function None -> Some x | Some y -> Some (Int.max x y) in
        match block with
        | Block.Thematic_break ((tb, _), _)
          when String.for_all
                 (fun c -> c = '-')
                 (Block.Thematic_break.layout tb) ->
            max (String.length (Block.Thematic_break.layout tb)) biggest
        | _ -> biggest
      in
      List.fold_left find_biggest None blocks
    in
    let rec collect_until_dash ?(first = false) ~separator (acc_attrs, acc1)
        global_acc blocks =
      let add_to_global_acc (acc_attrs, acc1) global_acc =
        if global_acc = [] && acc1 = [] && first then []
          (* We do not add empty first element to give a chance to add attributes to the (new) first element *)
        else (acc_attrs, List.rev acc1) :: global_acc
      in
      match blocks with
      | Block.Thematic_break ((tb, tb_attrs), _tb_meta) :: rest
        when String.equal separator (Block.Thematic_break.layout tb) ->
          let global_acc = add_to_global_acc (acc_attrs, acc1) global_acc in
          collect_until_dash ~separator (tb_attrs, []) global_acc rest
      | e :: rest ->
          collect_until_dash ~separator (acc_attrs, e :: acc1) global_acc rest
      | [] -> List.rev ((acc_attrs, List.rev acc1) :: global_acc)
    in
    match find_biggest blocks with
    | None -> Mapper.default
    | Some n ->
        let separator = String.make n '-' in
        let res =
          collect_until_dash ~first:true ~separator
            ((Attributes.empty, Meta.none), [])
            [] blocks
        in
        let res = List.filter_map div res in
        Mapper.ret @@ Block.Blocks (res, meta)

  let execute defs read_file =
    let current_path = Path_entering.make () in
    let block m = function
      | Block.Blocks bs -> handle_dash_separated_blocks m bs
      | Block.Block_quote bq -> turn_block_quotes_into_divs m bq
      | Block.Code_block cb -> handle_slip_scripts_creation m cb
      | Block.Ext_standalone_attributes sa ->
          handle_includes read_file current_path m sa
      | _ -> Mapper.default
    in
    let inline i = function
      | Inline.Image img -> handle_image_inlining i defs current_path img
      | _ -> Mapper.default
    in
    let attrs = function
      | `Kv (("up", m), v) -> Some (`Kv (("up-at-unpause", m), v))
      | `Kv (("center", m), v) -> Some (`Kv (("center-at-unpause", m), v))
      | `Kv (("down", m), v) -> Some (`Kv (("down-at-unpause", m), v))
      | `Kv (("exec", m), v) -> Some (`Kv (("exec-at-unpause", m), v))
      | `Kv (("scroll", m), v) -> Some (`Kv (("scroll-at-unpause", m), v))
      | `Kv (("enter", m), v) -> Some (`Kv (("enter-at-unpause", m), v))
      | `Kv (("emph", m), v) -> Some (`Kv (("emph-at-unpause", m), v))
      | `Kv (("focus", m), v) -> Some (`Kv (("focus-at-unpause", m), v))
      | `Kv (("reveal", m), v) -> Some (`Kv (("reveal-at-unpause", m), v))
      | `Kv (("static", m), v) -> Some (`Kv (("static-at-unpause", m), v))
      | `Kv (("unemph", m), v) -> Some (`Kv (("unemph-at-unpause", m), v))
      | `Kv (("unfocus", m), v) -> Some (`Kv (("unfocus-at-unpause", m), v))
      | `Kv (("unreveal", m), v) -> Some (`Kv (("unreveal-at-unpause", m), v))
      | `Kv (("unstatic", m), v) -> Some (`Kv (("unstatic-at-unpause", m), v))
      (* TODO: Improve this (eg by moving it to another phase) *)
      | `Kv (("children:up", m), v) ->
          Some (`Kv (("children:up-at-unpause", m), v))
      | `Kv (("children:center", m), v) ->
          Some (`Kv (("children:center-at-unpause", m), v))
      | `Kv (("children:down", m), v) ->
          Some (`Kv (("children:down-at-unpause", m), v))
      | `Kv (("children:exec", m), v) ->
          Some (`Kv (("children:exec-at-unpause", m), v))
      | `Kv (("children:scroll", m), v) ->
          Some (`Kv (("children:scroll-at-unpause", m), v))
      | `Kv (("children:enter", m), v) ->
          Some (`Kv (("children:enter-at-unpause", m), v))
      | `Kv (("children:emph", m), v) ->
          Some (`Kv (("children:emph-at-unpause", m), v))
      | `Kv (("children:focus", m), v) ->
          Some (`Kv (("children:focus-at-unpause", m), v))
      | `Kv (("children:reveal", m), v) ->
          Some (`Kv (("children:reveal-at-unpause", m), v))
      | `Kv (("children:static", m), v) ->
          Some (`Kv (("children:static-at-unpause", m), v))
      | `Kv (("children:unemph", m), v) ->
          Some (`Kv (("children:unemph-at-unpause", m), v))
      | `Kv (("children:unfocus", m), v) ->
          Some (`Kv (("children:unfocus-at-unpause", m), v))
      | `Kv (("children:unreveal", m), v) ->
          Some (`Kv (("children:unreveal-at-unpause", m), v))
      | `Kv (("children:unstatic", m), v) ->
          Some (`Kv (("children:unstatic-at-unpause", m), v))
      | x -> Some x
    in
    Ast.Mapper.make ~block ~inline ~attrs ()

  let execute defs read_file md =
    Cmarkit.Mapper.map_doc (execute defs read_file) md
end

module Stage2 = struct
  (** Get the attributes of a cmarkit node, returns them and the element
      stripped of its attributes *)
  let get_attribute =
    let no_attrs = (Attributes.empty, Meta.none) in
    function
    (* Standard Cmarkit nodes *)
    | Block.Blank_line _ -> None
    | Block.Block_quote ((bq, attrs), meta) ->
        Some (Block.Block_quote ((bq, no_attrs), meta), attrs)
    | Block.Blocks _ -> None
    | Block.Code_block ((cb, attrs), meta) ->
        Some (Block.Code_block ((cb, no_attrs), meta), attrs)
    | Block.Heading ((h, attrs), meta) ->
        Some (Block.Heading ((h, no_attrs), meta), attrs)
    | Block.Html_block ((hb, attrs), meta) ->
        Some (Block.Html_block ((hb, no_attrs), meta), attrs)
    | Block.Link_reference_definition _ -> None
    | Block.List ((l, attrs), meta) ->
        Some (Block.List ((l, no_attrs), meta), attrs)
    | Block.Paragraph ((p, attrs), meta) ->
        Some (Block.Paragraph ((p, no_attrs), meta), attrs)
    | Block.Thematic_break ((tb, attrs), meta) ->
        Some (Block.Thematic_break ((tb, no_attrs), meta), attrs)
    (* Extension Cmarkit nodes *)
    | Block.Ext_math_block ((mb, attrs), meta) ->
        Some (Block.Ext_math_block ((mb, no_attrs), meta), attrs)
    | Block.Ext_table ((table, attrs), meta) ->
        Some (Block.Ext_table ((table, no_attrs), meta), attrs)
    | Block.Ext_footnote_definition _ -> None
    | Block.Ext_standalone_attributes _ -> None
    | Block.Ext_attribute_definition _ -> None
    (* Slipshow nodes *)
    | Ast.S_block b -> (
        match b with
        | Included ((inc, attrs), meta) ->
            Some (Ast.included ((inc, no_attrs), meta), attrs)
        | Div ((div, attrs), meta) ->
            Some (Ast.div ((div, no_attrs), meta), attrs)
        | Slide ((slide, attrs), meta) ->
            Logs.err (fun m ->
                m
                  "Slides should not appear here, this is an error on \
                   slipshow's side. Please report!");
            Some (Ast.slide ((slide, no_attrs), meta), attrs)
        | Slip ((slip, attrs), meta) ->
            Logs.err (fun m ->
                m
                  "Slips should not appear here, this is an error on \
                   slipshow's side. Please report!");
            Some (Ast.slip ((slip, no_attrs), meta), attrs)
        | SlipScript ((slscr, attrs), meta) ->
            Some (Ast.slipscript ((slscr, no_attrs), meta), attrs)
        | Carousel ((c, attrs), meta) ->
            Some (Ast.carousel ((c, no_attrs), meta), attrs))
    | _ -> None

  (** Get the attributes of a cmarkit node, returns them and the element
      stripped of its attributes *)
  let merge_attribute new_attrs b =
    let merge base =
      Attributes.merge ~base ~new_attrs
      (* Old attributes take precendence over "new" one *)
    in
    match b with
    (* Standard Cmarkit nodes *)
    | Block.Blank_line _ | Block.Blocks _ -> b
    | Block.Block_quote ((bq, (attrs, meta_a)), meta) ->
        Block.Block_quote ((bq, (merge attrs, meta_a)), meta)
    | Block.Code_block ((cb, (attrs, meta_a)), meta) ->
        Block.Code_block ((cb, (merge attrs, meta_a)), meta)
    | Block.Heading ((h, (attrs, meta_a)), meta) ->
        Block.Heading ((h, (merge attrs, meta_a)), meta)
    | Block.Html_block ((hb, (attrs, meta_a)), meta) ->
        Block.Html_block ((hb, (merge attrs, meta_a)), meta)
    | Block.Link_reference_definition _ -> b
    | Block.List ((l, (attrs, meta_a)), meta) ->
        Block.List ((l, (merge attrs, meta_a)), meta)
    | Block.Paragraph ((p, (attrs, meta_a)), meta) ->
        Block.Paragraph ((p, (merge attrs, meta_a)), meta)
    | Block.Thematic_break ((tb, (attrs, meta_a)), meta) ->
        Block.Thematic_break ((tb, (merge attrs, meta_a)), meta)
    (* Extension Cmarkit nodes *)
    | Block.Ext_math_block ((mb, (attrs, meta_a)), meta) ->
        Block.Ext_math_block ((mb, (merge attrs, meta_a)), meta)
    | Block.Ext_table ((table, (attrs, meta_a)), meta) ->
        Block.Ext_table ((table, (merge attrs, meta_a)), meta)
    | Block.Ext_footnote_definition _ -> b
    | Block.Ext_standalone_attributes _ -> b
    | Block.Ext_attribute_definition _ -> b
    (* Slipshow nodes *)
    | Ast.S_block b -> (
        match b with
        | Included ((inc, (attrs, meta_a)), meta) ->
            Ast.included ((inc, (merge attrs, meta_a)), meta)
        | Div ((div, (attrs, meta_a)), meta) ->
            Ast.div ((div, (merge attrs, meta_a)), meta)
        | Slide ((slide, (attrs, meta_a)), meta) ->
            Logs.err (fun m ->
                m
                  "Slides should not appear here, this is an error on \
                   slipshow's side. Please report!");
            Ast.slide ((slide, (merge attrs, meta_a)), meta)
        | Slip ((slip, (attrs, meta_a)), meta) ->
            Logs.err (fun m ->
                m
                  "Slips should not appear here, this is an error on \
                   slipshow's side. Please report!");
            Ast.slip ((slip, (merge attrs, meta_a)), meta)
        | SlipScript ((slscr, (attrs, meta_a)), meta) ->
            Ast.slipscript ((slscr, (merge attrs, meta_a)), meta)
        | Carousel ((c, (attrs, meta_a)), meta) ->
            Ast.carousel ((c, (merge attrs, meta_a)), meta))
    | _ -> b

  let execute =
    let block m c =
      match c with
      | Ast.S_block (Div ((Block.Blocks (bs, m_bs), (attrs, m_attrs)), m_div))
        ->
          let kvs = Attributes.kv_attributes attrs in
          let rem_prefix ~prefix s =
            if String.starts_with ~prefix s then
              Some
                (String.sub s (String.length prefix)
                   (String.length s - String.length prefix))
            else None
          in
          let categorize key =
            match rem_prefix ~prefix:"." key with
            | Some c -> `Class c
            | None -> `Kv key
          in
          let new_attrs =
            List.fold_left
              (fun acc ((key, meta), value) ->
                match rem_prefix ~prefix:"children:" key with
                | None -> acc
                | Some key -> (
                    match (categorize key, value) with
                    | `Class c, None -> Attributes.add_class acc (c, meta)
                    | `Kv c, _ -> Attributes.add (c, meta) value acc
                    | `Class c, Some _ ->
                        Logs.warn (fun m ->
                            m "Children classes cannot have a value");
                        Attributes.add (c, meta) value acc))
              Attributes.empty kvs
          in
          let bs = List.map (merge_attribute new_attrs) bs in
          let bs =
            match Mapper.map_block m (Block.Blocks (bs, m_bs)) with
            | None -> Block.Blocks ([], m_bs)
            | Some l -> l
          in
          Mapper.ret (Ast.div ((bs, (attrs, m_attrs)), m_div))
      | _ -> Mapper.default
    in
    Ast.Mapper.make ~block ()

  let execute md = Cmarkit.Mapper.map_doc execute md
end

module Stage3 = struct
  let rec extract_title block =
    match block with
    | Ast.S_block (Div ((h, attrs), meta)) ->
        let block, title = extract_title h in
        (Ast.div ((block, attrs), meta), title)
    | Block.Heading ((h, attrs), _) when Block.Heading.level h = 1 ->
        (Block.Blocks ([], Meta.none), Some (Block.Heading.inline h, attrs))
    | Block.Blocks (Block.Heading ((h, attrs), _) :: blocks, meta)
      when Block.Heading.level h = 1 ->
        (Block.Blocks (blocks, meta), Some (Block.Heading.inline h, attrs))
    | Block.Blocks ((Block.Blank_line _ as bl) :: blocks, meta) ->
        let block, title = extract_title (Block.Blocks (blocks, meta)) in
        let blocks =
          match block with
          | Block.Blocks (bs, _) -> bl :: bs
          | _ -> bl :: [ block ]
        in
        (Block.Blocks (blocks, meta), title)
    | _ -> (block, None)

  let execute =
    let block m c =
      let map ~may_enter block (attrs, meta2) =
        let b =
          match Mapper.map_block m block with
          | None -> Block.empty
          | Some b -> b
        in
        let attrs =
          if
            (Attributes.mem "no-enter" attrs
            || Attributes.mem "enter-at-unpause" attrs)
            || not may_enter
          then attrs
          else Attributes.add ("enter-at-unpause", Meta.none) None attrs
        in
        let attrs = Mapper.map_attrs m attrs in
        (b, (attrs, meta2))
      in
      match Stage2.get_attribute c with
      | None -> Mapper.default
      | Some (block, (attrs, meta2)) when Attributes.mem "blockquote" attrs ->
          let block, attrs = map ~may_enter:false block (attrs, meta2) in
          let block = Block.Block_quote.make block in
          Mapper.ret @@ Block.Block_quote ((block, attrs), Meta.none)
      | Some (block, (attrs, meta2)) when Attributes.mem "slide" attrs ->
          let block, attrs = map ~may_enter:true block (attrs, meta2) in
          let block, title = extract_title block in
          Mapper.ret
          @@ Ast.slide (({ content = block; title }, attrs), Meta.none)
      | Some (block, (attrs, meta2)) when Attributes.mem "slip" attrs ->
          let block, (attrs, meta) = map ~may_enter:true block (attrs, meta2) in
          Mapper.ret @@ Ast.slip ((block, (attrs, meta)), Meta.none)
      | Some (block, (attrs, meta2)) when Attributes.mem "carousel" attrs ->
          let block, attrs = map ~may_enter:false block (attrs, meta2) in
          let children =
            match block with
            | Ast.S_block (Div ((Block.Blocks (l, _), _), _)) -> l
            | _ -> [ block ]
          in
          let children =
            List.filter_map
              (function Block.Blank_line _ -> None | x -> Some x)
              children
          in
          Mapper.ret @@ Ast.carousel ((children, attrs), Meta.none)
      | Some _ -> Mapper.default
    in
    Ast.Mapper.make ~block ()

  let execute md = Cmarkit.Mapper.map_doc execute md
end

module Stage4 = struct
  let fpath_map_add_to_list x data m =
    let add = function None -> Some [ data ] | Some l -> Some (data :: l) in
    Fpath.Map.update x add m

  let execute =
    let block f (x, acc) c =
      let acc =
        match Stage2.get_attribute c with
        | None -> (x, acc)
        | Some (_, (attrs, meta)) -> (
            match Attributes.id attrs with
            | None ->
                (* Logs.warn (fun m -> m "There is no id here"); *)
                (x, acc)
            | Some ((_id, _) as id') ->
                (* Logs.warn (fun m -> m "There is an id here: %s" id); *)
                (x, (id', c, meta) :: acc))
      in
      (* let acc = Folder.fold_block f acc c in *)
      let open Block in
      let res =
        match c with
        | Blank_line _ | Code_block _ | Html_block _
        | Ext_standalone_attributes _ | Link_reference_definition _
        | Thematic_break _ | Ext_math_block _ | Ext_attribute_definition _ ->
            acc
        | Heading ((h, _attrs), _) ->
            Folder.fold_inline f acc (Block.Heading.inline h)
        | Block_quote ((bq, _attrs), _) ->
            Folder.fold_block f acc (Cmarkit.Block.Block_quote.block bq)
        | Blocks (bs, _) -> List.fold_left (Folder.fold_block f) acc bs
        | List ((l, _attrs), _) ->
            let fold_list_item m acc (i, _) =
              Folder.fold_block m acc (Block.List_item.block i)
            in
            List.fold_left (fold_list_item f) acc (List'.items l)
        | Paragraph ((p, _attrs), _) ->
            Folder.fold_inline f acc (Block.Paragraph.inline p)
        | Ext_table ((t, _attrs), _) ->
            let fold_row acc ((r, _), _) =
              match r with
              | `Header is | `Data is ->
                  List.fold_left
                    (fun acc (i, _) -> Folder.fold_inline f acc i)
                    acc is
              | `Sep _ -> acc
            in
            List.fold_left fold_row acc (Table.rows t)
        | Ext_footnote_definition ((_fn, _attrs), _) -> acc (* TODO *)
        | Ast.S_block b -> (
            match b with
            | Ast.Slide (({ content = b; title = Some (title, _) }, _), _) ->
                let acc = Folder.fold_inline f acc title in
                Folder.fold_block f acc b
            | Slide (({ content = b; title = None }, _), _)
            | Div ((b, _), _)
            | Included ((b, _), _)
            | Slip ((b, _), _) ->
                Folder.fold_block f acc b
            | SlipScript _ -> acc
            | Carousel ((l, _), _) ->
                List.fold_left (fun acc x -> Folder.fold_block f acc x) acc l)
        | _ -> assert false
      in
      Folder.ret res
    in
    let inline _f (acc, x) = function
      | Ast.S_inline i -> (
          match i with
          | Video media
          | Pdf media
          | Audio media
          | Hand_drawn media
          | Svg media
          | Image media -> (
              match media with
              | { uri = Path p, meta; id; origin } ->
                  Folder.ret
                  @@ (fpath_map_add_to_list p (id, (origin, meta)) acc, x)
              | _ -> Folder.default))
      | _ -> Folder.default
    in
    Ast.Folder.make ~block ~inline ()

  let execute ~read_file md =
    let asset_map, id_list =
      Cmarkit.Folder.fold_doc execute (Fpath.Map.empty, []) md
    in
    let () =
      let module Map = Map.Make (String) in
      let _map =
        List.fold_left
          (fun acc (((id, meta1), b1, meta_attrs) as value) ->
            Map.update id
              (function
                | None -> Some value
                | Some ((_, meta2), b2, meta_attrs2) as same ->
                    let tl1 = Meta.textloc meta1 in
                    ignore b1;
                    ignore b2;
                    let () =
                      let tl3 = Meta.textloc meta_attrs in
                      Logs.warn (fun m ->
                          m "Error: Attributes at location: %a"
                            Cmarkit.Textloc.pp_ocaml tl3)
                    in
                    let () =
                      let tl3 = Meta.textloc meta_attrs2 in
                      Logs.warn (fun m ->
                          m "Error: Attributes at location: %a"
                            Cmarkit.Textloc.pp_ocaml tl3)
                    in
                    (* let () = *)
                    (*   match b2 with *)
                    (*   | Block.Heading (_, meta3) -> *)
                    (*       let tl3 = Meta.textloc meta3 in *)
                    (*       Logs.warn (fun m -> *)
                    (*           m "Error: Heading at location: %a" *)
                    (*             Cmarkit.Textloc.pp_ocaml tl3) *)
                    (*   | _ -> () *)
                    (* in *)
                    (* let () = *)
                    (*   match b1 with *)
                    (*   | Block.Heading (_, meta3) -> *)
                    (*       let tl3 = Meta.textloc meta3 in *)
                    (*       Logs.warn (fun m -> *)
                    (*           m "Error: Heading at location: %a" *)
                    (*             Cmarkit.Textloc.pp_ocaml tl3) *)
                    (*   | _ -> () *)
                    (* in *)
                    let tl2 = Meta.textloc meta2 in
                    let error =
                      {
                        Errors.error =
                          DuplicateID { id; previous_occurrence = tl1 };
                        loc = tl2;
                      }
                    in
                    Log_errors.add error;
                    Logs.warn (fun m ->
                        m "Error: duplicated id: %s:\n- %a\n- %a" id
                          Cmarkit.Textloc.pp_ocaml tl1 Cmarkit.Textloc.pp_ocaml
                          tl2);
                    same)
              acc)
          Map.empty id_list
      in
      ()
    in
    let files =
      Fpath.Map.filter_map
        (fun path used_by ->
          let read_file : file_reader = read_file in
          let mode = `Base64 in
          match read_file path with
          | Ok (Some content) ->
              let used_by = List.map fst used_by in
              Some { Ast.Files.content; mode; used_by; path }
          | Ok None -> None
          | Error (`Msg s) ->
              List.iter
                (fun (_id, (_node, meta)) ->
                  let textloc = Meta.textloc meta in
                  Logs.warn (fun m ->
                      m
                        "Could not read file: %a at %a. Considering it as an \
                         URL. (%s)"
                        Fpath.pp path Textloc.pp_ocaml textloc s))
                used_by;
              None)
        asset_map
    in
    { Ast.doc = md; files }
end

let of_cmarkit ~read_file md =
  let defs = Cmarkit.Doc.defs md in
  let md1 = Stage1.execute defs read_file md in
  let md2 = Stage2.execute md1 in
  let md3 = Stage3.execute md2 in
  Stage4.execute ~read_file md3

let compile ?file ~attrs ?(read_file = fun _ -> Ok None) s =
  Log_errors.with_ @@ fun () ->
  let open Cmarkit in
  let md =
    let doc =
      match file with
      | None -> Doc.of_string ~heading_auto_ids:true ~strict:false s
      | Some file ->
          Doc.of_string ~file ~locs:true ~heading_auto_ids:true ~strict:false s
    in
    let bq = Block.Block_quote.make (Doc.block doc) in
    let block = Block.Block_quote ((bq, (attrs, Meta.none)), Meta.none) in
    Doc.make block
  in
  of_cmarkit ~read_file md

let to_cmarkit =
  let ( let* ) x f = Option.bind x f in
  let ( let+ ) x f = Option.map f x in

  let block m = function
    | Ast.Slide (({ content; title }, _), meta) ->
        let title =
          let* title, attrs = title in
          let+ title = Mapper.map_inline m title in
          Block.Heading ((Block.Heading.make ~level:1 title, attrs), Meta.none)
        in
        let title = Option.to_list title in
        let b =
          match Mapper.map_block m content with
          | None -> Block.empty
          | Some b -> b
        in
        Mapper.ret (Block.Blocks (title @ [ b ], meta))
    | Div ((bq, _), meta) | Slip ((bq, _), meta) | Included ((bq, _), meta) ->
        let b =
          match Mapper.map_block m bq with None -> Block.empty | Some b -> b
        in
        Mapper.ret (Block.Blocks ([ b ], meta))
    | SlipScript _ -> Mapper.delete
    | Carousel ((l, _), meta) ->
        `Map (Mapper.map_block m (Block.Blocks (l, meta)))
  in
  let block m = function Ast.S_block b -> block m b | _ -> Mapper.default in
  let inline m = function
    | Ast.Video { origin; _ }
    | Audio { origin; _ }
    | Pdf { origin; _ }
    | Hand_drawn { origin; _ }
    | Svg { origin; _ }
    | Image { origin; _ } ->
        `Map (Mapper.map_inline m (Inline.Image origin))
  in
  let inline m = function
    | Ast.S_inline i -> inline m i
    | _ -> Mapper.default
  in
  let attrs = function
    | `Kv (("up-at-unpause", m), v) -> Some (`Kv (("up", m), v))
    | `Kv (("center-at-unpause", m), v) -> Some (`Kv (("center", m), v))
    | `Kv (("enter-at-unpause", m), v) -> Some (`Kv (("enter", m), v))
    | `Kv (("down-at-unpause", m), v) -> Some (`Kv (("down", m), v))
    | `Kv (("exec-at-unpause", m), v) -> Some (`Kv (("exec", m), v))
    | `Kv (("scroll-at-unpause", m), v) -> Some (`Kv (("scroll", m), v))
    | x -> Some x
  in
  Ast.Mapper.make ~block ~inline ~attrs ()

let to_cmarkit { Ast.doc = sd; _ } = Cmarkit.Mapper.map_doc to_cmarkit sd
