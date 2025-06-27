open Cmarkit

type t = Doc.t
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
    - Images are inlined.
    - Attributes are suffixed with [-at-unpause]
    - BlockS are grouped on divs by [---]

    The second stage is doing the following:
    - [blockquote] attributed elements are turned into block quotes
    - [slip] attributed elements are turned into block quotes
    - [slide] attributed elements are turned into block quotes *)

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
    do_ (path_stack |> Stack.to_seq |> List.of_seq) p
end

let resolve_image ps ~read_file s =
  let uri =
    match Asset.Uri.of_string s with
    | Link s -> Asset.Uri.Link s
    | Path p -> Path (Path_entering.relativize ps p)
  in
  Asset.of_uri ~read_file uri

module Stage1 = struct
  let turn_block_quotes_into_divs m ((bq, (attrs, meta2)), meta) =
    let b = Block.Block_quote.block bq in
    let b =
      match Mapper.map_block m b with None -> Block.empty | Some b -> b
    in
    let attrs = Mapper.map_attrs m attrs in
    Mapper.ret (Ast.Div ((b, (attrs, meta2)), meta))

  let handle_slip_scripts_creation m ((cb, (attrs, meta)), meta2) =
    match Block.Code_block.info_string cb with
    | None -> Mapper.default
    | Some (info, _) -> (
        match Block.Code_block.language_of_info_string info with
        | Some ("slip-script", _) ->
            Mapper.ret
              (Ast.SlipScript ((cb, (Mapper.map_attrs m attrs, meta)), meta2))
        | _ -> Mapper.default)

  let remove_quotes src =
    (* This is a horrible hack due to the fact that our current attribute
       parsing leaves the quotes...

       It was not spotted until now since leftover quotes are
       interpreted as quotes by HTML, but as we use more attributes in
       cmarkit, it's going to be really annoying.

       Needs to be fixed in cmarkit... *)
    if src.[0] = '"' && src.[String.length src - 1] = '"' then
      String.sub src 1 (String.length src - 2)
    else src

  let handle_includes read_file current_path m (attrs, meta) =
    match (Attributes.find "include" attrs, Attributes.find "src" attrs) with
    | Some (_, None), Some (_, Some (src, _)) -> (
        let src = remove_quotes src in
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
              Cmarkit.Doc.of_string ~heading_auto_ids:true ~strict:false
                contents
            in
            Path_entering.in_path current_path (Fpath.parent (Fpath.v src))
            @@ fun () ->
            match Mapper.map_block m (Doc.block md) with
            | None -> Mapper.default
            | Some mapped_blocks ->
                let attrs = Mapper.map_attrs m attrs in
                Mapper.ret
                  (Ast.Included ((mapped_blocks, (attrs, meta)), Meta.none))))
    | _ -> Mapper.default

  let handle_image_inlining read_file current_path i ((l, (attrs, meta2)), meta)
      =
    let text = Inline.Link.text l in
    let reference =
      match Inline.Link.reference l with
      | `Ref _ as r -> r
      | `Inline ((ld, attrs), meta) ->
          let label, layout, defined_label, (dest, meta_dest), title =
            Link_definition.
              (label ld, layout ld, defined_label ld, dest ld, title ld)
          in
          let dest =
            match resolve_image current_path ~read_file dest with
            | Asset.Remote s -> s
            | Asset.Local { mime_type; content } ->
                let mime_type = Option.value ~default:"" mime_type in
                let base64 = Base64.encode_string content in
                Format.sprintf "data:%s;base64,%s" mime_type base64
          in
          let dest = (dest, meta_dest) in
          let ld =
            Link_definition.make ~layout ~defined_label ?label ~dest ?title ()
          in
          `Inline ((ld, attrs), meta)
    in
    let l = Inline.Link.make text reference in
    let attrs = Mapper.map_attrs i attrs in
    Mapper.ret (Inline.Image ((l, (attrs, meta2)), meta))

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
      | Some blocks -> Some (Ast.Div ((blocks, (attrs, am)), Meta.none))
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

  let execute read_file =
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
      | Inline.Image img -> handle_image_inlining read_file current_path i img
      | _ -> Mapper.default
    in
    let attrs = function
      | `Kv (("up", m), v) -> Some (`Kv (("up-at-unpause", m), v))
      | `Kv (("center", m), v) -> Some (`Kv (("center-at-unpause", m), v))
      | `Kv (("down", m), v) -> Some (`Kv (("down-at-unpause", m), v))
      | `Kv (("exec", m), v) -> Some (`Kv (("exec-at-unpause", m), v))
      | `Kv (("scroll", m), v) -> Some (`Kv (("scroll-at-unpause", m), v))
      | `Kv (("enter", m), v) -> Some (`Kv (("enter-at-unpause", m), v))
      | x -> Some x
    in
    Ast.Mapper.make ~block ~inline ~attrs ()
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
    | Ast.Included ((inc, attrs), meta) ->
        Some (Ast.Included ((inc, no_attrs), meta), attrs)
    | Ast.Div ((div, attrs), meta) ->
        Some (Ast.Div ((div, no_attrs), meta), attrs)
    | Ast.Slide ((slide, attrs), meta) ->
        Logs.err (fun m ->
            m
              "Slides should not appear here, this is an error on slipshow's \
               side. Please report!");
        Some (Ast.Slide ((slide, no_attrs), meta), attrs)
    | Ast.Slip ((slip, attrs), meta) ->
        Logs.err (fun m ->
            m
              "Slips should not appear here, this is an error on slipshow's \
               side. Please report!");
        Some (Ast.Slip ((slip, no_attrs), meta), attrs)
    | Ast.SlipScript ((slscr, attrs), meta) ->
        Some (Ast.SlipScript ((slscr, no_attrs), meta), attrs)
    | _ -> None

  let execute =
    let block m c =
      let map block (attrs, meta2) =
        let b =
          match Mapper.map_block m block with
          | None -> Block.empty
          | Some b -> b
        in
        let attrs =
          if Attributes.mem "no-enter" attrs then attrs
          else Attributes.add ("enter-at-unpause", Meta.none) None attrs
        in
        let attrs = Mapper.map_attrs m attrs in
        (b, (attrs, meta2))
      in
      match get_attribute c with
      | None -> Mapper.default
      | Some (block, (attrs, meta2)) when Attributes.mem "blockquote" attrs ->
          let block, attrs = map block (attrs, meta2) in
          let block = Block.Block_quote.make block in
          Mapper.ret @@ Block.Block_quote ((block, attrs), Meta.none)
      | Some (block, (attrs, meta2)) when Attributes.mem "slide" attrs ->
          let block, attrs = map block (attrs, meta2) in
          Mapper.ret @@ Ast.Slide ((block, attrs), Meta.none)
      | Some (block, (attrs, meta2)) when Attributes.mem "slip" attrs ->
          let block, (attrs, meta) = map block (attrs, meta2) in
          Mapper.ret @@ Ast.Slip ((block, (attrs, meta)), Meta.none)
      | Some _ -> Mapper.default
    in
    Ast.Mapper.make ~block ()
end

let of_cmarkit ~read_file md =
  let md1 = Cmarkit.Mapper.map_doc (Stage1.execute read_file) md in
  Cmarkit.Mapper.map_doc Stage2.execute md1

let compile ?(read_file = fun _ -> Ok None) s =
  let md = Cmarkit.Doc.of_string ~heading_auto_ids:true ~strict:false s in
  let md = of_cmarkit ~read_file md in
  let open Cmarkit in
  Doc.make
  @@ Ast.Slip
       ( ( Doc.block md,
           ( Attributes.(empty |> add ("slipshow-entry-point", Meta.none) None),
             Meta.none ) ),
         Meta.none )

let to_cmarkit =
  let block m = function
    | Ast.Div ((bq, _), meta)
    | Ast.Slide ((bq, _), meta)
    | Ast.Slip ((bq, _), meta)
    | Ast.Included ((bq, _), meta) ->
        let b =
          match Mapper.map_block m bq with None -> Block.empty | Some b -> b
        in
        Mapper.ret (Block.Blocks ([ b ], meta))
    | Ast.SlipScript _ -> Mapper.delete
    | _ -> Mapper.default
  in
  let inline _i = function _ -> Mapper.default in
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

let to_cmarkit sd = Cmarkit.Mapper.map_doc to_cmarkit sd
