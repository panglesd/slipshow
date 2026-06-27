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
  | ".html" -> `Html
  | _ -> `Image

let resolve_file parent s =
  match Asset.Uri.of_string s with
  | Link _ as l -> l
  | Path p -> Path (Fpath.normalize @@ Fpath.( // ) parent p)

module Stage1 = struct
  let turn_block_quotes_into_divs m ((bq, (attrs, meta2)), meta) =
    let b = Block.Block_quote.block bq in
    let b =
      match Mapper.map_block m b with None -> Block.empty | Some b -> b
    in
    let attrs = Mapper.map_attrs m attrs in
    Ast.div ((b, (attrs, meta2)), meta)

  let has_attrs attrs x = Cmarkit.Attributes.find x attrs |> Option.is_some

  let handle_code_blocks m ((cb, (attrs, meta)), meta2) =
    let attrs = Mapper.map_attrs m attrs in
    let attrs = (attrs, meta) in
    let html () =
      let h = Block.Code_block.code cb in
      Block.Html_block ((h, attrs), meta2)
    in
    if has_attrs (fst attrs) Special_attrs.as_html then html ()
    else
      match Block.Code_block.info_string cb with
      | None -> Block.Code_block ((cb, attrs), meta2)
      | Some (info, _) -> (
          match Block.Code_block.language_of_info_string info with
          | Some ("slip-script", _) -> Ast.slipscript ((cb, attrs), meta2)
          | Some ("=mermaid", _) -> Ast.mermaid_js ((cb, attrs), meta2)
          | Some ("=html", _) -> html ()
          | _ -> Block.Code_block ((cb, attrs), meta2))

  let handle_code_span m ((cs, (attrs, meta)), meta2) =
    let attrs = Mapper.map_attrs m attrs in
    if has_attrs attrs Special_attrs.as_html then
      let code = Inline.Code_span.code_layout cs in
      let html = Inline.Raw_html (code, meta2) in
      let span = Inline.Attributes_span.make html (attrs, meta) in
      Inline.Ext_attrs (span, meta2)
    else Inline.Code_span ((cs, (attrs, meta)), meta2)

  let handle_md_includes m ~htbl_include current_path (attrs, meta)
      filepath_meta src =
    let relativized_path = Fpath.normalize @@ Fpath.( // ) current_path src in
    let old_value =
      Hashtbl.find_opt htbl_include relativized_path |> Option.value ~default:[]
    in
    let new_value = Meta.textloc filepath_meta :: old_value in
    Hashtbl.replace htbl_include relativized_path new_value;
    let attrs = Mapper.map_attrs m attrs in
    `Map (Some (Ast.included ((relativized_path, (attrs, meta)), meta)))

  let handle_includes m ~htbl_include current_path (attrs, meta) =
    match
      ( Attributes.find Special_attrs.include_ attrs,
        Attributes.find Special_attrs.src attrs )
    with
    | Some (_, None), Some (_, Some ({ v = src; _ }, filepath_meta)) ->
        let src = Fpath.v src in
        if Fpath.has_ext ".html" src || Fpath.has_ext ".svg" src then
          let relativized_path =
            Fpath.normalize @@ Fpath.( // ) current_path src
          in
          let attrs = Mapper.map_attrs m attrs in
          `Map
            (Some (Ast.included_html ((relativized_path, (attrs, meta)), meta)))
        else
          handle_md_includes m ~htbl_include current_path (attrs, meta)
            filepath_meta src
    | _ -> `Default

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
    else if has_attrs Special_attrs.as_html then `Html
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
    let res =
      match kind with
      | `Image -> Ast.image { uri; origin; id = Id.gen () }
      | `Svg -> Ast.svg { uri; origin; id = Id.gen () }
      | `Video -> Ast.video { uri; origin; id = Id.gen () }
      | `Audio -> Ast.audio { uri; origin; id = Id.gen () }
      | `Draw -> Ast.hand_drawn { uri; origin; id = Id.gen () }
      | `Pdf -> Ast.pdf { uri; origin; id = Id.gen () }
      | `Html -> Ast.html { uri; origin; id = Id.gen () }
    in
    Mapper.ret res

  let handle_dash_separated_blocks (m : Mapper.t) (blocks, meta) =
    let div ((attrs, am), blocks) =
      let attrs = Mapper.map_attrs m attrs in
      let blocks =
        match blocks with
        | [] -> Mapper.map_block m @@ Block.Blocks (blocks, Meta.none)
        | [ b ] -> Mapper.map_block m b
        | fb :: _ as blocks ->
            let to_textloc b =
              b |> Ast.Utils.Block.meta |> Cmarkit.Meta.textloc
            in
            let textloc =
              List.map to_textloc blocks
              |> List.fold_left Cmarkit.Textloc.span (to_textloc fb)
            in
            Mapper.map_block m @@ Block.Blocks (blocks, Meta.make ~textloc ())
      in
      match blocks with
      | None -> None
      | Some blocks ->
          let textloc =
            blocks |> Ast.Utils.Block.meta |> Cmarkit.Meta.textloc
          in
          Some (Ast.div ((blocks, (attrs, am)), Meta.make ~textloc ()))
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
    let res =
      match find_biggest blocks with
      | None -> List.filter_map (Mapper.map_block m) blocks
      | Some n ->
          let separator = String.make n '-' in
          let res =
            collect_until_dash ~first:true ~separator
              ((Attributes.empty, Meta.none), [])
              [] blocks
          in
          List.filter_map div res
    in
    match res with [] -> None | res -> Some (Block.Blocks (res, meta))

  let map_attrs = function
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

  let execute ~htbl_include current_path defs =
    let ret x = `Map x in
    let block m = function
      | Block.Blocks bs -> ret @@ handle_dash_separated_blocks m bs
      | Block.Block_quote bq -> ret @@ Some (turn_block_quotes_into_divs m bq)
      | Block.Code_block cb -> ret @@ Some (handle_code_blocks m cb)
      | Block.Ext_standalone_attributes sa ->
          handle_includes m ~htbl_include current_path sa
      | _ -> Mapper.default
    in
    let attrs = map_attrs in
    let inline m = function
      | Inline.Image img -> handle_image_inlining m defs current_path img
      | Inline.Code_span cs -> Mapper.ret (handle_code_span m cs)
      | _ -> Mapper.default
    in
    Ast.Mapper.make ~block ~inline ~attrs ()

  let execute current_path defs md fm =
    let htbl_include = Hashtbl.create 3 in
    let res = Mapper.map_doc (execute ~htbl_include current_path defs) md in
    let fm =
      let toplevel_attributes =
        match fm.Frontmatter.global.toplevel_attributes with
        | None -> None
        | Some (attrs, meta) ->
            Some (Cmarkit.Attributes.map map_attrs attrs, meta)
      in
      {
        fm with
        Frontmatter.global = { fm.Frontmatter.global with toplevel_attributes };
      }
    in
    (res, htbl_include, fm)
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
                          (ChildrenClassWithValue { loc = Meta.textloc v_meta });
                        Attributes.add_class acc (c, meta)))
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
          let textloc = block |> Ast.Utils.Block.meta |> Cmarkit.Meta.textloc in
          let block, attrs = map ~may_enter:false block (attrs, meta2) in
          let block = Block.Block_quote.make block in
          Mapper.ret @@ Block.Block_quote ((block, attrs), Meta.make ~textloc ())
      | Some (block, (attrs, meta2))
        when Attributes.mem Special_attrs.slide attrs ->
          let textloc = block |> Ast.Utils.Block.meta |> Cmarkit.Meta.textloc in
          let block, attrs = map ~may_enter:true block (attrs, meta2) in
          let block, title = extract_title block in
          Mapper.ret
          @@ Ast.slide
               (({ content = block; title }, attrs), Meta.make ~textloc ())
      | Some (block, (attrs, meta2))
        when Attributes.mem Special_attrs.slip attrs ->
          let textloc = block |> Ast.Utils.Block.meta |> Cmarkit.Meta.textloc in
          let block, (attrs, meta) = map ~may_enter:true block (attrs, meta2) in
          Mapper.ret @@ Ast.slip ((block, (attrs, meta)), Meta.make ~textloc ())
      | Some (block, (attrs, meta2))
        when Attributes.mem Special_attrs.carousel attrs ->
          let textloc = block |> Ast.Utils.Block.meta |> Cmarkit.Meta.textloc in
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
          Mapper.ret @@ Ast.carousel ((children, attrs), Meta.make ~textloc ())
      | Some _ -> Mapper.default
    in
    Ast.Mapper.make ~block ()

  let execute md = Cmarkit.Mapper.map_doc execute md
end

module Stage4 = struct
  let fpath_map_add_to_list path user fpath_map =
    let h () =
      (* let read_file : file_reader = read_file in *)
      let mode = `Base64 in
      (* let res = read_file path in *)
      (* let res = res |> Result.map (fun x -> x |> Option.map fst) in *)
      { Ast.Files.content = (); mode; used_by = [ user ]; path }
    in
    let add = function
      | None -> Some (h ())
      | Some file -> Some { file with used_by = user :: file.Ast.Files.used_by }
    in
    Fpath.Map.update path add fpath_map

  let execute =
    let block f (files, id_list) c =
      let files =
        match c with
        | Ast.S_block (IncludedHTML ((p, _), meta)) ->
            fpath_map_add_to_list p (Id.gen (), Meta.textloc meta) files
        | _ -> files
      in
      let acc =
        match Ast.Utils.Block.get_attribute c with
        | None -> (files, id_list)
        | Some (_, (attrs, meta)) -> (
            match Attributes.id attrs with
            | None -> (files, id_list)
            | Some id -> (files, { Id_map.id; elem = `Block c; meta } :: id_list)
            )
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
            | Some id -> { Id_map.id; elem = `Inline i; meta } :: id_list)
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
            | Html media
            | Image media -> (
                match media with
                | { uri = Path p, meta; id; origin = _ } ->
                    fpath_map_add_to_list p (id, Meta.textloc meta) acc
                | _ -> acc))
        | _ -> acc
      in
      let acc = Ast.Folder.continue_inline f i (acc, id_list) in
      Folder.ret acc
    in
    Ast.Folder.make ~block ~inline ()

  let execute ~(fm : Frontmatter.t) md =
    let files = Fpath.Map.empty in
    let external_ids =
      fm.global.external_ids
      |> List.map (fun x ->
          { Id_map.id = (x, Meta.none); elem = `External; meta = Meta.none })
    in
    let asset_map, id_list =
      Cmarkit.Folder.fold_doc execute (files, external_ids) md
    in
    let id_list = List.rev id_list in
    let id_map =
      List.fold_left
        (fun acc ({ Id_map.id = id, _meta1; _ } as value) ->
          Id_map.SMap.update id
            (function
              | None -> Some (Id_map.Unionable_set.singleton value)
              | Some same -> Some (Id_map.Unionable_set.add value same))
            acc)
        Id_map.SMap.empty id_list
    in
    let files = asset_map in
    (md, files, id_map)
end

let action_plan _ = failwith "TODO: Action plan"

let of_cmarkit ~path ~(fm : Frontmatter.t) ~source md =
  let defs = Doc.defs md in
  let block = Doc.block md in
  let md =
    let b =
      match fm.local.attributes with
      | None -> block
      | Some attributes ->
          Ast.S_block (Ast.Div ((block, attributes), Meta.none))
    in
    Doc.make ~nl:(Doc.nl md) ~defs b
  in
  let current_path = Fpath.parent path in
  let (ast, deps, id_map, files, option), warnings =
    Diagnosis.with_ @@ fun () ->
    let md1, htbl_include, fm = Stage1.execute current_path defs md fm in
    let md2 = Stage2.execute md1 in
    let md3 = Stage3.execute md2 in
    let md4, files, id_map = Stage4.execute ~fm md3 in
    let deps = htbl_include |> Hashtbl.to_seq |> Fpath.Map.of_seq in
    (md4, deps, id_map, files, fm.global)
  in
  { Ast.ast; deps; id_map; source; files; option; warnings; path }

let _add_file read_file file content =
 fun p -> if Fpath.equal p file then Ok (Some content) else read_file p

let unit ?locs ~read_file file =
  let locs =
    match locs with
    | Some locs -> locs
    | None ->
        [
          Textloc.v ~file:(Fpath.to_string file) ~first_byte:0 ~last_byte:1
            ~first_line:(0, 0) ~last_line:(0, 0);
        ]
  in
  let source, s =
    match read_file file with
    | Error (`Msg s) ->
        Diagnosis.add
          (MissingFile { file = Fpath.to_string file; error_msg = s; locs });
        (None, "")
    | Ok None ->
        let error_msg = "Unable to read a slipshow file" in
        Diagnosis.add
          (MissingFile { file = Fpath.to_string file; error_msg; locs });
        (None, "")
    | Ok (Some s' as s) -> (s, s')
  in
  let doc, frontmatter = Cmarkit_proxy.of_string ~read_file ~file s in
  of_cmarkit ~source ~path:file doc ~fm:frontmatter

let rec add_to_compile ?locs ~units file units_cache ~read_file =
  if Fpath.Map.mem file units then units
  else
    let u =
      match Fpath.Map.find_opt file units_cache with
      | Some u -> u
      | None -> unit ~read_file ?locs file
    in
    let units = Fpath.Map.add file u units in
    Fpath.Map.fold
      (fun dep locs units ->
        add_to_compile ~locs ~units dep units_cache ~read_file)
      u.deps units

let compile_all ~read_file units_cache file =
  let units = Fpath.Map.empty in
  let units = add_to_compile file ~units units_cache ~read_file in
  let files, options =
    Ast.Folder.fold_just_units
      (fun unit (files, option) ->
        let files = Ast.Files.combine files unit.files in
        let option = Frontmatter.Global.combine option unit.Ast.option in
        let () =
          (* Rethrow the few warnings raised during the unit phase (currently,
               only "children:#id is not supported") warnings not to miss
               them *)
          List.iter Diagnosis.add unit.warnings
        in
        (files, option))
      (Fpath.Map.empty, Frontmatter.Global.empty)
      file units
  in
  let toplevel_attributes =
    Option.value ~default:Frontmatter.Toplevel_attributes.default
      options.toplevel_attributes
  in
  let internal = Fpath.v "internal" in
  let u =
    let doc =
      let block =
        let open Cmarkit.Block in
        Block_quote
          ( ( Block_quote.make
                (Ext_standalone_attributes
                   ( Cmarkit.Attributes.make
                       ~kv_attributes:
                         [
                           (("include", Meta.none), None);
                           ( ("src", Meta.none),
                             Some
                               ( { v = Fpath.to_string file; delimiter = None },
                                 Cmarkit.Meta.none ) );
                         ]
                       (),
                     Meta.none )),
              toplevel_attributes ),
            Meta.none )
      in
      Cmarkit.Doc.make block
    in
    of_cmarkit ~path:internal ~fm:Frontmatter.empty ~source:None doc
  in
  let units = Fpath.Map.add internal u units in
  let action_plan, id_map = Action_plan.execute u units in
  let files : Ast.Files.read Ast.Files.map =
    Fpath.Map.mapi
      (fun path file ->
        let content =
          match read_file path with
          | Ok content -> content
          | Error (`Msg error_msg) ->
              let locs = List.map snd file.Ast.Files.used_by in
              Diagnosis.add
                (MissingFile { file = Fpath.to_string path; error_msg; locs });
              None
        in
        { file with content })
      files
  in
  { Ast.units; files; id_map; entry_point = internal; options; action_plan }

let compile_all ~read_file units file =
  Diagnosis.with_ @@ fun () -> compile_all ~read_file units file

(* let add_to_compile file c ~read_file = *)
(*   Diagnosis.with_ @@ fun () -> add_to_compile file c ~read_file *)

(* let included_files ~read_file file s = *)
(*   Diagnosis.with_ @@ fun () -> *)
(*   let doc, fm = Cmarkit_proxy.of_string ~read_file ~file s in *)
(*   let defs = Doc.defs doc in *)
(*   let _fm, _md1, htbl_include = Stage1.execute ~fm defs read_file doc in *)
(*   htbl_include |> Hashtbl.to_seq_keys |> List.of_seq *)

let to_cmarkit units =
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
    | Included ((path, _), _meta) ->
        let b =
          match Fpath.Map.find_opt path units with
          | None -> None
          | Some b ->
              let b = Doc.block b.Ast.ast in
              Mapper.map_block m b
        in
        `Map b
    | IncludedHTML ((_, _), _meta) -> `Map None
    | Div ((bq, _), meta) | Slip ((bq, _), meta) ->
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
    | Html { origin; _ }
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

let to_cmarkit
    {
      Ast.units;
      entry_point;
      options = _;
      files = _;
      id_map = _;
      action_plan = _;
    } =
  match Fpath.Map.find_opt entry_point units with
  | None -> failwith "Fail during markdown output"
  | Some sd -> Cmarkit.Mapper.map_doc (to_cmarkit units) sd.ast
