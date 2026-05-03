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
    - [=mermaid] code blocks are turned into slip scripts,
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

    The fourth stage is populating the media files map, and the ID map.

    The fifth stage is iterating on the attributes to generate warnings for
    wrongly designed action attributes. *)

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
  | Link _ as l -> l
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
        | Some ("=mermaid", _) ->
            Mapper.ret
              (Ast.mermaid_js ((cb, (Mapper.map_attrs m attrs, meta)), meta2))
        | _ -> Mapper.default)

  let handle_includes ~htbl_include read_file current_path m (attrs, meta) =
    match
      ( Attributes.find Special_attrs.include_ attrs,
        Attributes.find Special_attrs.src attrs )
    with
    | Some (_, None), Some (_, Some ({ v = src; _ }, filepath_meta)) -> (
        let relativized_path =
          Path_entering.relativize current_path (Fpath.v src)
        in
        match read_file relativized_path with
        | Error (`Msg err) ->
            let locs = [ Meta.textloc filepath_meta ] in
            Diagnosis.add
              (MissingFile
                 {
                   file = Fpath.to_string relativized_path;
                   error_msg = err;
                   locs;
                 });
            Mapper.default
        | Ok None -> Mapper.default
        | Ok (Some contents) -> (
            Hashtbl.add htbl_include (Fpath.to_string relativized_path) contents;
            let md =
              let file = Some (Fpath.to_string relativized_path) in
              Cmarkit_proxy.of_string ~file contents
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
    if has_attrs Special_attrs.video then `Video
    else if has_attrs Special_attrs.audio then `Audio
    else if has_attrs Special_attrs.image then `Image
    else if has_attrs Special_attrs.svg then `Svg
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

  let execute ~htbl_include defs read_file =
    let current_path = Path_entering.make () in
    let block m = function
      | Block.Blocks bs -> handle_dash_separated_blocks m bs
      | Block.Block_quote bq -> turn_block_quotes_into_divs m bq
      | Block.Code_block cb -> handle_slip_scripts_creation m cb
      | Block.Ext_standalone_attributes sa ->
          handle_includes ~htbl_include read_file current_path m sa
      | _ -> Mapper.default
    in
    let inline i = function
      | Inline.Base (Image img) -> handle_image_inlining i defs current_path img
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
    let htbl_include = Hashtbl.create 3 in
    let res =
      Cmarkit.Mapper.map_doc (execute ~htbl_include defs read_file) md
    in
    (res, htbl_include)
end

module Stage2 = struct
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
                    | `Class c, Some (_, v_meta) ->
                        Diagnosis.add
                          (General
                             {
                               msg = "Children classes cannot have a value";
                               labels = [ ("", Meta.textloc v_meta) ];
                               notes = [];
                               code = "ChildrenAttrs";
                             });
                        Attributes.add (c, meta) value acc))
              Attributes.empty kvs
          in
          let bs = List.map (Ast.Utils.Block.merge_attribute new_attrs) bs in
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
            (Attributes.mem Special_attrs.no_enter attrs
            || Attributes.mem Actions_arguments.Enter.on attrs)
            || not may_enter
          then attrs
          else Attributes.add (Actions_arguments.Enter.on, Meta.none) None attrs
        in
        let attrs = Mapper.map_attrs m attrs in
        (b, (attrs, meta2))
      in
      match Ast.Utils.Block.get_attribute c with
      | None -> Mapper.default
      | Some (block, (attrs, meta2))
        when Attributes.mem Special_attrs.blockquote attrs ->
          let block, attrs = map ~may_enter:false block (attrs, meta2) in
          let block = Block.Block_quote.make block in
          Mapper.ret @@ Block.Block_quote ((block, attrs), Meta.none)
      | Some (block, (attrs, meta2))
        when Attributes.mem Special_attrs.slide attrs ->
          let block, attrs = map ~may_enter:true block (attrs, meta2) in
          let block, title = extract_title block in
          Mapper.ret
          @@ Ast.slide (({ content = block; title }, attrs), Meta.none)
      | Some (block, (attrs, meta2))
        when Attributes.mem Special_attrs.slip attrs ->
          let block, (attrs, meta) = map ~may_enter:true block (attrs, meta2) in
          Mapper.ret @@ Ast.slip ((block, (attrs, meta)), Meta.none)
      | Some (block, (attrs, meta2))
        when Attributes.mem Special_attrs.carousel attrs ->
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
    let block f (x, id_list) c =
      let acc =
        match Ast.Utils.Block.get_attribute c with
        | None -> (x, id_list)
        | Some (_, (attrs, meta)) -> (
            match Attributes.id attrs with
            | None -> (x, id_list)
            | Some id -> (x, (id, `Block c, meta) :: id_list))
      in
      let res = Ast.Folder.continue_block f c acc in
      Folder.ret res
    in
    let inline f (acc, id_list) i =
      let id_list =
        match Ast.Utils.Inline.get_attribute i with
        | None -> id_list
        | Some (_, (attrs, meta)) -> (
            match Attributes.id attrs with
            | None -> id_list
            | Some id -> (id, `Inline i, meta) :: id_list)
      in
      let acc =
        match i with
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
                    fpath_map_add_to_list p (id, (origin, meta)) acc
                | _ -> acc))
        | _ -> acc
      in
      let acc = Ast.Folder.continue_inline f i (acc, id_list) in
      Folder.ret acc
    in
    Ast.Folder.make ~block ~inline ()

  let execute ~(fm : Frontmatter.t) ~read_file md =
    let fm = fm in
    let external_ids =
      fm.local.external_ids
      |> List.map (fun x -> ((x, Meta.none), `External, Meta.none))
    in
    let asset_map, id_list =
      Cmarkit.Folder.fold_doc execute (Fpath.Map.empty, external_ids) md
    in
    let id_list = List.rev id_list in
    let module Map = Map.Make (String) in
    let id_map =
      List.fold_left
        (fun acc (((id, _meta1), _b1, _meta_attrs) as value) ->
          Map.update id
            (function
              | None -> Some [ value ] | Some same -> Some (value :: same))
            acc)
        Map.empty id_list
    in
    let id_map =
      Map.filter_map
        (fun id list ->
          match list with
          | [] -> assert false
          | [ x ] -> Some x
          | x :: _ :: _ ->
              let occurrences =
                List.map
                  (fun ((_id, meta1), _b1, _meta_attrs) -> Meta.textloc meta1)
                  list
              in
              Diagnosis.add @@ DuplicateID { id; occurrences };
              Some x)
        id_map
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
          | Error (`Msg error_msg) ->
              let locs =
                List.map (fun (_id, (_node, meta)) -> Meta.textloc meta) used_by
              in
              Diagnosis.add
                (MissingFile { file = Fpath.to_string path; error_msg; locs });
              None)
        asset_map
    in
    ({ Ast.doc = md; files }, id_map)
end

module Stage5 = struct
  module M = Map.Make (String)

  let check_attribute ~id_map block_or_inline (attrs, _meta) =
    List.iter (fun check -> check id_map attrs block_or_inline) Check.all_checks

  let folder ~id_map =
    let block _f () c =
      let () =
        match Ast.Utils.Block.get_attribute c with
        | None -> ()
        | Some (_, attrs) -> check_attribute ~id_map (`Block c) attrs
      in
      Folder.default
    in
    let inline _f () i =
      let () =
        match Ast.Utils.Inline.get_attribute i with
        | None -> ()
        | Some (_, attrs) -> check_attribute ~id_map (`Inline i) attrs
      in
      Folder.default
    in
    Ast.Folder.make ~block ~inline ()

  let execute ~id_map ast =
    let () = Cmarkit.Folder.fold_doc (folder ~id_map) () ast.Ast.doc in
    ast
end

let of_cmarkit ~read_file ~(fm : Frontmatter.t) md =
  let defs = Cmarkit.Doc.defs md in
  let md1, htbl_include = Stage1.execute defs read_file md in
  let md2 = Stage2.execute md1 in
  let md3 = Stage3.execute md2 in
  let md4, id_map = Stage4.execute ~read_file ~fm md3 in
  (Stage5.execute ~id_map md4, htbl_include, fm)

let compile ?file ?(read_file = fun _ -> Ok None) s =
  Diagnosis.with_ @@ fun () ->
  let open Cmarkit in
  let frontmatter, s, loc_offset =
    match Frontmatter.extract s with
    | None -> (Frontmatter.empty, s, (0, 0))
    | Some { frontmatter = txt_fm; rest; rest_offset; fm_offset } ->
        let file = Option.value ~default:"-" file in
        let to_asset = Asset.of_string ~read_file in
        let frontmatter =
          Frontmatter.of_string ~to_asset file fm_offset txt_fm
        in
        (frontmatter, rest, rest_offset)
  in
  let md =
    let doc = Cmarkit_proxy.of_string ~loc_offset ~file s in
    let bq = Block.Block_quote.make (Doc.block doc) in
    let block =
      let toplevel_attributes =
        frontmatter.local.toplevel_attributes
        |> Option.value ~default:Frontmatter.Toplevel_attributes.default
      in
      Block.Block_quote ((bq, (toplevel_attributes, Meta.none)), Meta.none)
    in
    Doc.make block
  in
  of_cmarkit ~read_file md ~fm:frontmatter

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
    | MermaidJS cb -> Mapper.ret (Block.Code_block cb)
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
        `Map (Mapper.map_inline m (Inline.Base (Image origin)))
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
