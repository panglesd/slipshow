module RenderAttrs = struct
  module C = Cmarkit_renderer.Context
  open Cmarkit

  let add_attr c (key, value) =
    match value with
    | Some { Cmarkit.Attributes.v = value; delimiter = Some d } ->
        let s = Format.sprintf " %s=%c%s%c" key d value d in
        C.string c s
    | Some { Cmarkit.Attributes.v = value; delimiter = None } ->
        C.string c (" " ^ key ^ "=" ^ value)
    | None -> C.string c (" " ^ key)

  let add_attrs c ?(include_id = true) attrs =
    let kv_attrs =
      let kv_attrs = Cmarkit.Attributes.kv_attributes attrs in
      List.map
        (fun ((k, _), v) ->
          let v = match v with None -> None | Some (v, _) -> Some v in
          (k, v))
        kv_attrs
    in
    let class' =
      let class' = Cmarkit.Attributes.class' attrs in
      let class' = List.map (fun (c, _) -> c) class' in
      match class' with
      | [] -> []
      | _ ->
          let v = String.concat " " class' in
          [ ("class", Some { Cmarkit.Attributes.v; delimiter = Some '"' }) ]
    in
    let id =
      let id = Cmarkit.Attributes.id attrs in
      match id with
      | Some (id, _) when include_id ->
          let attr = { Cmarkit.Attributes.v = id; delimiter = Some '"' } in
          [ ("id", Some attr) ]
      | _ -> []
    in
    let attrs = id @ class' @ kv_attrs in
    List.iter (add_attr c) attrs

  let open_block ?(with_newline = true) c tag attrs =
    C.string c "<";
    C.string c tag;
    add_attrs c attrs;
    C.string c ">";
    if with_newline then C.string c "\n"

  let close_block ?(with_newline = true) c tag =
    C.string c "</";
    C.string c tag;
    C.string c ">";
    if with_newline then C.string c "\n"

  let in_block c ?(with_newline = true) tag attrs f =
    open_block ~with_newline c tag attrs;
    f ();
    close_block ~with_newline c tag

  let with_attrs_span c ?(with_newline = true) attrs f =
    if Attributes.is_empty attrs then f ()
    else in_block c ~with_newline "span" attrs f

  let block_lines c = function
    (* newlines only between lines *)
    | [] -> ()
    | (l, _) :: ls ->
        let line c (l, _) =
          C.byte c '\n';
          C.string c l
        in
        C.string c l;
        List.iter (line c) ls
end

let to_string = function
  (* Standard Cmarkit nodes *)
  | Cmarkit.Block.Blank_line _ -> "Blank line"
  | Cmarkit.Block.Block_quote _ -> "Block_quote"
  | Cmarkit.Block.Blocks _ -> "Blocks"
  | Cmarkit.Block.Code_block _ -> "Code_block"
  | Cmarkit.Block.Heading _ -> "Heading"
  | Cmarkit.Block.Html_block _ -> "Html_block"
  | Cmarkit.Block.Link_reference_definition _ -> "Link_reference_definition"
  | Cmarkit.Block.List _ -> "List"
  | Cmarkit.Block.Paragraph _ -> "Paragraph"
  | Cmarkit.Block.Thematic_break _ -> "Thematic_break"
  (* Extension Cmarkit nodes *)
  | Cmarkit.Block.Ext_math_block _ -> "Ext_math_block"
  | Cmarkit.Block.Ext_table _ -> "Ext_table"
  | Cmarkit.Block.Ext_footnote_definition _ -> "Ext_footnote_definition"
  | Cmarkit.Block.Ext_standalone_attributes _ -> "Ext_standalone_attributes"
  | Cmarkit.Block.Ext_attribute_definition _ -> "Ext_attribute_definition"
  (* Slipshow nodes *)
  | Ast.Included _ -> "Included"
  | Ast.Div _ -> "Div"
  | Ast.Slide _ -> "Slide"
  | Ast.Slip _ -> "Slip"
  | Ast.SlipScript _ -> "SlipScript"
  | _ -> "other"

let link_dest_and_title ld =
  let dest = match Cmarkit.Link_definition.dest ld with link, _ -> link in
  let title =
    match Cmarkit.Link_definition.title ld with
    | None -> ""
    | Some title -> String.concat "\n" (List.map (fun (_, (t, _)) -> t) title)
  in
  (dest, title)

module C = Cmarkit_renderer.Context

let video ?(close = " >") c i attrs =
  let open Cmarkit in
  match Inline.Link.reference_definition (C.get_defs c) i with
  | Some (Link_definition.Def ((ld, (attributes, _)), _)) ->
      let attributes = Attributes.merge ~base:attributes ~new_attrs:attrs in
      let plain_text i =
        let lines = Inline.to_plain_text ~break_on_soft:false i in
        String.concat "\n" (List.map (String.concat "") lines)
      in
      let link, title = link_dest_and_title ld in
      C.string c "<video src=\"";
      Cmarkit_html.pct_encoded_string c link;
      C.string c "\" alt=\"";
      Cmarkit_html.html_escaped_string c (plain_text (Inline.Link.text i));
      C.byte c '\"';
      if false then C.string c " controls";
      if title <> "" then (
        C.string c " title=\"";
        Cmarkit_html.html_escaped_string c title;
        C.byte c '\"');
      RenderAttrs.add_attrs c attributes;
      C.string c close
  | _ -> assert false

let custom_html_renderer =
  let open Cmarkit_renderer in
  let open Cmarkit in
  let open Cmarkit_html in
  let default = renderer ~safe:false () in
  let custom_html =
    let inline c = function
      | Inline.Text ((t, (attrs, _)), _) ->
          (* Put text inside spans to be able to apply styles on them *)
          Context.string c "<span";
          add_attrs c attrs;
          Context.byte c '>';
          html_escaped_string c t;
          Context.string c "</span>";
          true
      | Ast.Video ((l, (attrs, _)), _) ->
          video c l attrs;
          true
      | _ -> false (* let the default HTML renderer handle that *)
    in
    let block c = function
      | Ast.Included ((b, (attrs, _)), _) | Ast.Div ((b, (attrs, _)), _) ->
          let should_include_div =
            let attrs_is_not_empty = not @@ Attributes.is_empty attrs in
            let contains_multiple_blocks =
              let is_multiple l =
                l
                |> List.filter_map (function
                     | Block.Blank_line _ -> None
                     | x -> Some x)
                |> List.length |> ( <= ) 2
              in
              match b with
              | Block.Blocks (l, _) when is_multiple l -> true
              | _ -> false
            in
            attrs_is_not_empty || contains_multiple_blocks
          in
          if should_include_div then
            RenderAttrs.in_block c "div" attrs (fun () -> Context.block c b)
          else Context.block c b;
          true
      | Ast.Slide (({ content; title }, (attrs, _)), _) ->
          let () =
            RenderAttrs.in_block c "div"
              (Attributes.add_class attrs ("slipshow-rescaler", Meta.none))
            @@ fun () ->
            RenderAttrs.in_block c "div"
              (Attributes.make ~class':[ ("slide", Meta.none) ] ())
            @@ fun () ->
            (match title with
            | None -> ()
            | Some (title, (title_attrs, _)) ->
                RenderAttrs.in_block c "div"
                  (Attributes.add_class title_attrs ("slide-title", Meta.none))
                  (fun () -> Context.inline c title));
            RenderAttrs.in_block c "div"
              (Attributes.make ~class':[ ("slide-body", Meta.none) ] ())
            @@ fun () -> Context.block c content
          in
          true
      | Ast.Slip ((slip, (attrs, _)), _) ->
          let () =
            RenderAttrs.in_block c "div"
              (Attributes.add_class attrs ("slipshow-rescaler", Meta.none))
            @@ fun () ->
            RenderAttrs.in_block c "div"
              (Attributes.make ~class':[ ("slip", Meta.none) ] ())
            @@ fun () ->
            RenderAttrs.in_block c "div"
              (Attributes.make ~class':[ ("slip-body", Meta.none) ] ())
            @@ fun () -> Context.block c slip
          in
          true
      | Ast.SlipScript ((cb, (attrs, _)), _) ->
          let attrs =
            Attributes.add ("type", Meta.none)
              (Some ({ v = "slip-script"; delimiter = None }, Meta.none))
              attrs
          in
          RenderAttrs.in_block c "script" attrs (fun () ->
              RenderAttrs.block_lines c (Block.Code_block.code cb));
          true
      | _ -> false
    in
    make ~inline ~block ()
  in
  compose default custom_html
