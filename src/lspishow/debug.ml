module Ast_printer = struct
  open Cmarkit
  open Format
  open Slipshow.Ast

  (** Prints the location of a Meta.t node *)
  let pp_loc ppf meta =
    let loc = Meta.textloc meta in
    if Textloc.is_none loc then fprintf ppf "<no location>"
    else
      let loc = Diagnostic.linoloc_of_textloc loc in
      fprintf ppf "%d:%d -> %d:%d" loc.start.line loc.start.character
        loc.end_.line loc.end_.character

  (** Prints the location of attributes if they exist *)
  let pp_attrs ppf (attrs, meta) =
    if not (Attributes.is_empty attrs) then
      fprintf ppf "@ (Attrs : %a)" pp_loc meta

  (** Recursively prints Inline.t nodes with their locations and attributes *)
  let rec pp_inline ppf inline =
    let meta = Utils.Inline.meta inline in
    fprintf ppf "@[<hv 2>(";
    (match inline with
    (* Standard Cmarkit Inlines *)
    | Inline.Autolink ((_al, attrs), _) ->
        fprintf ppf "Autolink%a" pp_attrs attrs
    | Inline.Break (b, _) ->
        let t =
          match Inline.Break.type' b with `Hard -> "Hard" | `Soft -> "Soft"
        in
        fprintf ppf "Break(%s)" t
    | Inline.Code_span ((_cs, attrs), _) ->
        fprintf ppf "Code_span%a" pp_attrs attrs
    | Inline.Emphasis ((e, attrs), _) ->
        fprintf ppf "Emphasis%a@ %a" pp_attrs attrs pp_inline
          (Inline.Emphasis.inline e)
    | Inline.Image ((l, attrs), _) ->
        fprintf ppf "Image%a@ %a" pp_attrs attrs pp_inline (Inline.Link.text l)
    | Inline.Inlines (is, _) ->
        fprintf ppf "Inlines@ @[<v>%a@]" (pp_print_list pp_inline) is
    | Inline.Link ((l, attrs), _) ->
        fprintf ppf "Link%a@ %a" pp_attrs attrs pp_inline (Inline.Link.text l)
    | Inline.Raw_html _ -> fprintf ppf "Raw_html"
    | Inline.Strong_emphasis ((e, attrs), _) ->
        fprintf ppf "Strong_emphasis%a@ %a" pp_attrs attrs pp_inline
          (Inline.Emphasis.inline e)
    | Inline.Text ((txt, attrs), _) ->
        fprintf ppf "Text%a %S" pp_attrs attrs txt
    (* Cmarkit Extension Inlines *)
    | Inline.Ext_strikethrough ((strk, attrs), _) ->
        fprintf ppf "Ext_strikethrough%a@ %a" pp_attrs attrs pp_inline
          (Inline.Strikethrough.inline strk)
    | Inline.Ext_math_span ((ms, attrs), _) ->
        let t = if Inline.Math_span.display ms then "Display" else "Inline" in
        fprintf ppf "Ext_math_span(%s)%a" t pp_attrs attrs
    | Inline.Ext_attrs (attr_span, _) ->
        fprintf ppf "Ext_attrs%a@ %a" pp_attrs
          (Inline.Attributes_span.attrs attr_span)
          pp_inline
          (Inline.Attributes_span.content attr_span)
    (* Slipshow Inlines *)
    | S_inline (Image _) -> fprintf ppf "S_inline(Image)"
    | S_inline (Svg _) -> fprintf ppf "S_inline(Svg)"
    | S_inline (Video _) -> fprintf ppf "S_inline(Video)"
    | S_inline (Audio _) -> fprintf ppf "S_inline(Audio)"
    | S_inline (Pdf _) -> fprintf ppf "S_inline(Pdf)"
    | S_inline (Hand_drawn _) -> fprintf ppf "S_inline(Hand_drawn)"
    (* Catch-all for open variants *)
    | _ -> fprintf ppf "Unknown_inline");

    fprintf ppf "@ : %a)@]" pp_loc meta

  (** Recursively prints Block.t nodes with their locations and attributes *)
  let rec pp_block ppf block =
    let meta = Utils.Block.meta block in
    fprintf ppf "@[<hv 2>(";
    (match block with
    (* Standard Cmarkit Blocks *)
    | Block.Blank_line _ -> fprintf ppf "Blank_line"
    | Block.Block_quote ((bq, attrs), _) ->
        fprintf ppf "Block_quote%a@ %a" pp_attrs attrs pp_block
          (Block.Block_quote.block bq)
    | Block.Blocks (bs, _) ->
        fprintf ppf "Blocks@ @[<v>%a@]" (pp_print_list pp_block) bs
    | Block.Code_block ((_cb, attrs), _) ->
        fprintf ppf "Code_block%a" pp_attrs attrs
    | Block.Heading ((h, attrs), _) ->
        fprintf ppf "Heading(lvl %d)%a@ %a" (Block.Heading.level h) pp_attrs
          attrs pp_inline (Block.Heading.inline h)
    | Block.Html_block ((_hb, attrs), _) ->
        fprintf ppf "Html_block%a" pp_attrs attrs
    | Block.Link_reference_definition ((_ld, attrs), _) ->
        fprintf ppf "Link_reference_definition%a" pp_attrs attrs
    | Block.List ((l, attrs), _) ->
        fprintf ppf "List%a@ @[<v>%a@]" pp_attrs attrs
          (pp_print_list (fun fmt (item, _) ->
               pp_block fmt (Block.List_item.block item)))
          (Block.List'.items l)
    | Block.Paragraph ((p, attrs), _) ->
        fprintf ppf "Paragraph%a@ %a" pp_attrs attrs pp_inline
          (Block.Paragraph.inline p)
    | Block.Thematic_break ((_tb, attrs), _) ->
        fprintf ppf "Thematic_break%a" pp_attrs attrs
    (* Cmarkit Extension Blocks *)
    | Block.Ext_math_block ((_mb, attrs), _) ->
        fprintf ppf "Ext_math_block%a" pp_attrs attrs
    | Block.Ext_table ((_t, attrs), _) ->
        fprintf ppf "Ext_table%a" pp_attrs attrs
    | Block.Ext_footnote_definition ((_fn, attrs), _) ->
        fprintf ppf "Ext_footnote_definition%a" pp_attrs attrs
    | Block.Ext_standalone_attributes attrs ->
        fprintf ppf "Ext_standalone_attributes%a" pp_attrs attrs
    | Block.Ext_attribute_definition ((_def, attrs), _) ->
        fprintf ppf "Ext_attribute_definition%a" pp_attrs attrs
    (* Slipshow Blocks *)
    | S_block (Included ((b, attrs), _)) ->
        fprintf ppf "Included%a@ %a" pp_attrs attrs pp_block b
    | S_block (Div ((b, attrs), _)) ->
        fprintf ppf "Div%a@ %a" pp_attrs attrs pp_block b
    | S_block (Slide (({ content; title }, attrs), _)) ->
        fprintf ppf "Slide%a@ Title: %a@ Content: %a" pp_attrs attrs
          (pp_print_option (fun fmt (t, _) -> pp_inline fmt t))
          title pp_block content
    | S_block (Slip ((b, attrs), _)) ->
        fprintf ppf "Slip%a@ %a" pp_attrs attrs pp_block b
    | S_block (SlipScript ((_s, attrs), _)) ->
        fprintf ppf "SlipScript%a" pp_attrs attrs
    | S_block (MermaidJS ((_s, attrs), _)) ->
        fprintf ppf "MermaidJS%a" pp_attrs attrs
    | S_block (Carousel ((l, attrs), _)) ->
        fprintf ppf "Carousel%a@ @[<v>%a@]" pp_attrs attrs
          (pp_print_list pp_block) l
    (* Catch-all for open variants *)
    | _ -> fprintf ppf "Unknown_block");

    fprintf ppf "@ : %a)@]" pp_loc meta

  (** Main entry point for the Bol type *)
  let pp_bol ppf = function
    | `Block b -> pp_block ppf b
    | `Inline i -> pp_inline ppf i

  (** Convenience function to print a document directly to a string *)
  let show_block block = Format.asprintf "%a" pp_block block
end
