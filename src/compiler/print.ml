module Inline = struct
  open Cmarkit.Inline

  let break = fun fmt () -> Format.fprintf fmt "@ "

  let rec print fmt (i : t) =
    match i with
    | Autolink _ -> Format.fprintf fmt "Autolink"
    | Break _ -> Format.fprintf fmt "Break"
    | Code_span _ -> Format.fprintf fmt "Code_span"
    | Emphasis _ -> Format.fprintf fmt "Emphasis"
    | Image _ -> Format.fprintf fmt "Image"
    | Inlines (i, _) -> Fmt.list ~sep:break print fmt i
    | Link _ -> Format.fprintf fmt "Link"
    | Raw_html _ -> Format.fprintf fmt "Raw_html"
    | Strong_emphasis _ -> Format.fprintf fmt "Strong_emphasis"
    | Text _ -> Format.fprintf fmt "Text"
    | Ext_strikethrough _ -> Format.fprintf fmt "Ext_strikethrough"
    | Ext_math_span _ -> Format.fprintf fmt "Ext_math_span"
    | Ext_attrs _ -> Format.fprintf fmt "Ext_attrs"
    | Ast.Video _ -> Format.fprintf fmt "Video"
    | _ -> assert false
end

module Block = struct
  open Cmarkit.Block

  let break = fun fmt () -> Format.fprintf fmt "@\n"

  let f_bls =
    Fmt.list ~sep:break (fun fmt x ->
        Fmt.string fmt (Cmarkit.Block_line.to_string x))

  let rec print fmt (b : t) =
    match b with
    | Blank_line (_bl, _) -> Format.fprintf fmt "Blank_line"
    | Block_quote ((bq, _), _) ->
        let quoted_block = Block_quote.block bq in
        Format.fprintf fmt "Block_quote:@\n@[<v 2>%a@]" print quoted_block
    | Blocks (bs, _) ->
        let f_bs = Fmt.list ~sep:break print in
        Format.fprintf fmt "Blocks:@\n@[<v 2>%a@]" f_bs bs
    | Code_block ((cb, _), _) ->
        let text = Code_block.code cb in
        Format.fprintf fmt "Code_block:@\n@[<v 2>%a@]" f_bls text
    | Heading ((h, _), _) ->
        let l = Heading.level h in
        let t = Heading.inline h in
        Format.fprintf fmt "Heading %d:@\n@[<v 2>%a@]" l Inline.print t
    | Html_block ((hb, _), _) ->
        Format.fprintf fmt "Code_block:@\n@[<v 2>%a@]" f_bls hb
    | Link_reference_definition ((_ld, _), _) ->
        Format.fprintf fmt "Reference_definition"
    | List ((l, _), _) ->
        let items = List'.items l in
        let f_li fmt (li, _) =
          let b = List_item.block li in
          Format.fprintf fmt "List_item:@\n@[<v 2>%a@]" print b
        in
        Format.fprintf fmt "List:@\n@[<v 2>%a@]" (Fmt.list ~sep:break f_li)
          items
    | Paragraph ((p, _), _) ->
        let i = Paragraph.inline p in
        Format.fprintf fmt "Paragraph:@\n@[<v 2>%a@]" Inline.print i
    | Thematic_break ((_tb, _), _) -> Format.fprintf fmt "Thematic_break"
    | Ext_table _ -> Format.fprintf fmt "Ext_table: TODO"
    | Ext_footnote_definition _ -> Format.fprintf fmt "Footnote_def: TODO"
    | Ext_standalone_attributes _ ->
        Format.fprintf fmt "Standalone_attributes: TODO"
    | Ext_attribute_definition _ ->
        Format.fprintf fmt "Attribute_definition: TODO"
    | Ext_math_block _ -> Format.fprintf fmt "Math_block: TODO"
    | Ast.Included ((i, _), _) -> Format.fprintf fmt "Included: %a" print i
    | Ast.Div ((b, _), _) -> Format.fprintf fmt "Div:@\n@[<v 2>%a@]" print b
    | Ast.Slide (({ content; title = _ }, _), _) ->
        Format.fprintf fmt "Slide: title = TODO; content = @[<v 2>%a@]" print
          content
    | Ast.Slip ((content, _), _) ->
        Format.fprintf fmt "Slip:@\n@[<v 2>%a@]" print content
    | Ast.SlipScript _ -> Format.fprintf fmt "Slip_script: TODO"
    | _ -> assert false
end

let doc fmt (t : Cmarkit.Doc.t) =
  let block = Cmarkit.Doc.block t in
  Format.fprintf fmt "@[<v 2>%a@]" Block.print block
