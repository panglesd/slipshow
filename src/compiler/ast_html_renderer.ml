(*---------------------------------------------------------------------------
(* Part of this code is based on the Cmarkit project and
   Copyright (c) 2021 The cmarkit programmers.
   SPDX-License-Identifier: ISC *)
  ---------------------------------------------------------------------------*)
open Ast
module C = Ast_renderer.Context
module String_set = Set.Make (String)
module Label = Cmarkit.Label
(* Renderer state *)

type state = {
  safe : bool;
  backend_blocks : bool;
  files : Files.map;
  mutable ids : String_set.t;
  mutable footnote_count : int;
  mutable footnotes :
    (* Text, id, ref count, footnote *)
    (string * string * int ref (* * Block.Footnote.t *)) Label.Map.t;
}

let state : state C.State.t = C.State.make ()
let safe c = (C.State.get c state).safe
let files c = (C.State.get c state).files
let backend_blocks c = (C.State.get c state).backend_blocks

let init_context ?(backend_blocks = false) ~safe c (ast : Ast.t) =
  let files = ast.files in
  let ids = String_set.empty and footnotes = Label.Map.empty in
  let st =
    { safe; backend_blocks; ids; footnote_count = 0; footnotes; files }
  in
  C.State.set c state (Some st)

let unique_id c id =
  let st = C.State.get c state in
  let rec loop ids id c =
    let id' = if c = 0 then id else String.concat "-" [ id; Int.to_string c ] in
    match String_set.mem id' ids with
    | true -> loop ids id (c + 1)
    | false ->
        st.ids <- String_set.add id' ids;
        id'
  in
  loop st.ids id 0

let footnote_id label =
  let make_label l = String.map (function ' ' | '\t' -> '-' | c -> c) l in
  "fn-" ^ make_label (String.sub label 1 (String.length label - 1))

let footnote_ref_id fnid c = String.concat "-" [ "ref"; Int.to_string c; fnid ]

(* let make_footnote_ref_ids c label fn = *)
(*   let st = C.State.get c state in *)
(*   match Label.Map.find_opt label st.footnotes with *)
(*   | Some (text, id, refc (\* , _ *\)) -> *)
(*       incr refc; *)
(*       (text, id, footnote_ref_id id !refc) *)
(*   | None -> *)
(*       st.footnote_count <- st.footnote_count + 1; *)
(*       let text = *)
(*         String.concat "" [ "["; Int.to_string st.footnote_count; "]" ] *)
(*       in *)
(*       let id = footnote_id label in *)
(*       st.footnotes <- Label.Map.add label (text, id, ref 1, fn) st.footnotes; *)
(*       (text, id, footnote_ref_id id 1) *)

(* Escaping *)

let buffer_add_html_escaped_uchar b u =
  match Uchar.to_int u with
  | 0x0000 -> Buffer.add_utf_8_uchar b Uchar.rep
  | 0x0026 (* & *) -> Buffer.add_string b "&amp;"
  | 0x003C (* < *) -> Buffer.add_string b "&lt;"
  | 0x003E (* > *) -> Buffer.add_string b "&gt;"
  (* | 0x0027 (* ' *) -> Buffer.add_string b "&apos;" *)
  | 0x0022 (* '\"' *) -> Buffer.add_string b "&quot;"
  | _ -> Buffer.add_utf_8_uchar b u

let html_escaped_uchar c s = buffer_add_html_escaped_uchar (C.buffer c) s

let buffer_add_html_escaped_string b s =
  let string = Buffer.add_string in
  let len = String.length s in
  let max_idx = len - 1 in
  let flush b start i =
    if start < len then Buffer.add_substring b s start (i - start)
  in
  let rec loop start i =
    if i > max_idx then flush b start i
    else
      let next = i + 1 in
      match String.get s i with
      | '\x00' ->
          flush b start i;
          Buffer.add_utf_8_uchar b Uchar.rep;
          loop next next
      | '&' ->
          flush b start i;
          string b "&amp;";
          loop next next
      | '<' ->
          flush b start i;
          string b "&lt;";
          loop next next
      | '>' ->
          flush b start i;
          string b "&gt;";
          loop next next
      (*    | '\'' -> flush c start i; string c "&apos;"; loop next next *)
      | '\"' ->
          flush b start i;
          string b "&quot;";
          loop next next
      | _c -> loop start next
  in
  loop 0 0

let html_escaped_string c s = buffer_add_html_escaped_string (C.buffer c) s

let buffer_add_pct_encoded_string b s =
  (* Percent encoded + HTML escaped *)
  let byte = Buffer.add_char and string = Buffer.add_string in
  let unsafe_hexdig_of_int i =
    match i < 10 with
    | true -> Char.unsafe_chr (i + 0x30)
    | false -> Char.unsafe_chr (i + 0x37)
  in
  let flush b max start i =
    if start <= max then Buffer.add_substring b s start (i - start)
  in
  let rec loop b s max start i =
    if i > max then flush b max start i
    else
      let next = i + 1 in
      match String.get s i with
      | '%' (* In CommonMark destinations may have percent encoded chars *)
      (* See https://tools.ietf.org/html/rfc3986 *)
      (* unreserved *)
      | 'A' .. 'Z'
      | 'a' .. 'z'
      | '0' .. '9'
      | '-' | '.' | '_' | '~'
      (* sub-delims *)
      | '!' | '$' (*'&' | '\'' | *)
      | '(' | ')' | '*' | '+' | ',' | ';' | '='
      (* gen-delims *)
      | ':' | '/' | '?' | '#' (* '[' | ']' cmark escapes them | *)
      | '@' ->
          loop b s max start next
      | '&' ->
          flush b max start i;
          string b "&amp;";
          loop b s max next next
      | '\'' ->
          flush b max start i;
          string b "&apos;";
          loop b s max next next
      | c ->
          flush b max start i;
          let hi = (Char.code c lsr 4) land 0xF in
          let lo = Char.code c land 0xF in
          byte b '%';
          byte b (unsafe_hexdig_of_int hi);
          byte b (unsafe_hexdig_of_int lo);
          loop b s max next next
  in
  loop b s (String.length s - 1) 0 0

let pct_encoded_string c s = buffer_add_pct_encoded_string (C.buffer c) s

(* Rendering functions *)

let add_attr c (key, value) =
  match value with
  | Some { Attributes.v = value; delimiter = Some d } ->
      let s = Format.sprintf " %s=%c%s%c" key d value d in
      C.string c s
  | Some { Attributes.v = value; delimiter = None } ->
      C.string c (" " ^ key ^ "=" ^ value)
  | None -> C.string c (" " ^ key)

let add_attrs c attrs =
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
        [ ("class", Some { Attributes.v; delimiter = Some '"' }) ]
  in
  let id =
    let id = Cmarkit.Attributes.id attrs in
    match id with
    | Some (id, _) ->
        [ ("id", Some { Attributes.v = id; delimiter = Some '"' }) ]
    | None -> []
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

let with_attrs c ?(with_newline = true) attrs f =
  if Attributes.is_empty attrs then f ()
  else in_block c ~with_newline "div" attrs f

let with_attrs_span c ?with_newline attrs f =
  if Attributes.is_empty attrs then f ()
  else in_block c ?with_newline "span" attrs f

let comment c s =
  C.string c "<!-- ";
  html_escaped_string c s;
  C.string c " -->"

let comment_undefined_label c l =
  match Inline.Link.referenced_label l with
  | None -> ()
  | Some def -> comment c ("Undefined label " ^ Label.key def)

let comment_unknown_def_type c l =
  match Inline.Link.referenced_label l with
  | None -> ()
  | Some def -> comment c ("Unknown label definition type for " ^ Label.key def)

let comment_foonote_image c l =
  match Inline.Link.referenced_label l with
  | None -> ()
  | Some def -> comment c ("Footnote " ^ Label.key def ^ " referenced as image")

let comment_attribute_image c l =
  match Inline.Link.referenced_label l with
  | None -> ()
  | Some def -> comment c ("Attribute " ^ Label.key def ^ " referenced as image")

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

(* Inline rendering *)

let autolink c a attrs =
  let pre = if Inline.Autolink.is_email a then "mailto:" else "" in
  let url = pre ^ fst (Inline.Autolink.link a) in
  C.string c "<a href=\"";
  pct_encoded_string c url;
  add_attrs c attrs;
  C.string c "\">";
  html_escaped_string c (fst (Inline.Autolink.link a));
  C.string c "</a>"

let break c b =
  match Inline.Break.type' b with
  | `Hard -> C.string c "<br>\n"
  | `Soft -> C.byte c '\n'

let code_span c cs attrs =
  C.string c "<code";
  add_attrs c attrs;
  C.string c ">";
  html_escaped_string c (Inline.Code_span.code cs);
  C.string c "</code>"

let emphasis c e attrs =
  C.string c "<em";
  add_attrs c attrs;
  C.string c ">";
  C.inline c e.Inline.Emphasis.inline;
  C.string c "</em>"

let strong_emphasis c e attrs =
  C.string c "<strong";
  add_attrs c attrs;
  C.string c ">";
  C.inline c e.Inline.Emphasis.inline;
  C.string c "</strong>"

let link_dest_and_title _c ld =
  let dest =
    match Cmarkit.Link_definition.dest ld with
    (* | None -> "" *)
    (* Some *)
    (* Some *)
    | link, _ -> link
  in
  let title =
    match Cmarkit.Link_definition.title ld with
    | None -> ""
    | Some title -> String.concat "\n" (List.map (fun (_, (t, _)) -> t) title)
  in
  (dest, title)

let image ?(close = " >") c i attrs =
  match Inline.Link.reference_definition (C.get_defs c) i with
  | Some (Cmarkit.Link_definition.Def ((ld, (attributes, _)), _)) ->
      let attributes = Attributes.merge ~base:attributes ~new_attrs:attrs in
      let plain_text _c i =
        let lines = Inline.to_plain_text ~break_on_soft:false i in
        String.concat "\n" (List.map (String.concat "") lines)
      in
      let link, title = link_dest_and_title c ld in
      C.string c "<img src=\"";
      pct_encoded_string c link;
      C.string c "\" alt=\"";
      html_escaped_string c (plain_text c i.Inline.Link.text);
      C.byte c '\"';
      if title <> "" then (
        C.string c " title=\"";
        html_escaped_string c title;
        C.byte c '\"');
      add_attrs c attributes;
      C.string c close
  | Some (Cmarkit.Block.Footnote.Def _) -> comment_foonote_image c i
  | Some (Cmarkit.Block.Attribute_definition.Def _) -> comment_foonote_image c i
  | None -> comment_undefined_label c i
  | Some _ -> comment_unknown_def_type c i

(* let link_footnote c l fn = *)
(*   let key = Label.key (Option.get (Inline.Link.referenced_label l)) in *)
(*   let text, label, ref = make_footnote_ref_ids c key fn in *)
(*   let is_full_ref = *)
(*     match Inline.Link.reference l with `Ref (`Full, _, _) -> true | _ -> false *)
(*   in *)
(*   if is_full_ref then begin *)
(*     C.string c "<a href=\"#"; *)
(*     pct_encoded_string c label; *)
(*     C.string c "\" id=\""; *)
(*     html_escaped_string c ref; *)
(*     C.string c "\" role=\"doc-noteref\">"; *)
(*     C.inline c (Inline.Link.text l); *)
(*     C.string c "</a>" *)
(*   end *)
(*   else begin *)
(*     C.string c "<sup><a href=\"#"; *)
(*     pct_encoded_string c label; *)
(*     C.string c "\" id=\""; *)
(*     html_escaped_string c ref; *)
(*     C.string c "\" role=\"doc-noteref\" class=\"fn-label\">"; *)
(*     C.string c text; *)
(*     C.string c "</a></sup>" *)
(*   end *)

let link c l attrs =
  match Ast.Inline.Link.reference_definition (C.get_defs c) l with
  | Some (Cmarkit.Link_definition.Def ((ld, (attributes, _)), _)) ->
      let attributes = Attributes.merge ~base:attributes ~new_attrs:attrs in
      let link, title = link_dest_and_title c ld in
      C.string c "<a href=\"";
      pct_encoded_string c link;
      C.string c "\"";
      add_attrs c attributes;
      if title <> "" then (
        C.string c " title=\"";
        html_escaped_string c title;
        C.string c "\"");
      C.string c ">";
      C.inline c l.Inline.Link.text;
      C.string c "</a>"
  | Some (Cmarkit.Block.Footnote.Def ((_fn, _todo), _)) ->
      comment c "Footnotes are unsupported"
  | Some (Cmarkit.Block.Attribute_definition.Def ((attrs, _), _)) ->
      let ext_attrs =
        Inline.Attrs_span
          ( {
              Inline.Attributes_span.content = l.Inline.Link.text;
              attrs = Cmarkit.Block.Attribute_definition.attrs attrs;
            },
            Meta.none )
      in
      C.inline c ext_attrs
  | None ->
      C.inline c l.Inline.Link.text;
      comment_undefined_label c l
  | Some _ ->
      C.inline c l.Inline.Link.text;
      comment_unknown_def_type c l

let raw_html c h =
  if safe c then comment c "CommonMark raw HTML omitted"
  else
    let line c (_, (h, _)) =
      C.byte c '\n';
      C.string c h
    in
    if h <> [] then (
      C.string c (fst (snd (List.hd h)));
      List.iter (line c) (List.tl h))

let strikethrough c s attrs =
  C.string c "<del";
  add_attrs c attrs;
  C.string c ">";
  C.inline c s;
  C.string c "</del>"

let math_span c ms =
  let tex_line c l =
    html_escaped_string c (Cmarkit.Block_line.tight_to_string l)
  in
  let tex_lines c = function
    (* newlines only between lines *)
    | [] -> ()
    | l :: ls ->
        let line c l =
          C.byte c '\n';
          tex_line c l
        in
        tex_line c l;
        List.iter (line c) ls
  in
  let tex = Inline.Math_span.tex_layout ms in
  if tex = [] then ()
  else (
    C.string c (if Inline.Math_span.display ms then "\\[" else "\\(");
    tex_lines c tex;
    C.string c (if Inline.Math_span.display ms then "\\]" else "\\)"))

let attribute_span c as' =
  let content = as'.Inline.Attributes_span.content in
  let attrs, _ = as'.Inline.Attributes_span.attrs in
  with_attrs_span ~with_newline:false c attrs @@ fun () -> C.inline c content

let src uri files =
  match uri with
  | Asset.Uri.Link l -> `Link l
  | Path p -> (
      match Fpath.Map.find_opt p (files : Ast.Files.map) with
      | None -> `Link (Fpath.to_string p)
      | Some { content; mode = `Base64; _ } ->
          let mime_type = Magic_mime.lookup (Fpath.filename p) in
          `Source (content, mime_type))

let src_to_link = function
  | `Link l -> l
  | `Source (content, mime_type) ->
      let base64 = Base64.encode_string content in
      Format.sprintf "data:%s;base64,%s" mime_type base64

let media ?(close = " >") ~media_name c ~uri ~files i attrs =
  let src = src uri files |> src_to_link in
  let plain_text i =
    let lines = Inline.to_plain_text ~break_on_soft:false i in
    String.concat "\n" (List.map (String.concat "") lines)
  in
  C.byte c '<';
  C.string c media_name;
  C.string c " src=\"";
  pct_encoded_string c src;
  C.string c "\" alt=\"";
  html_escaped_string c (plain_text i.Inline.Link.text);
  C.byte c '\"';
  if false then C.string c " controls";
  add_attrs c attrs;
  C.string c close

(* Inspired from Cmarkit's image rendering *)
let pdf c ~uri ~files i attrs =
  match uri with
  | Asset.Uri.Link l ->
      Logs.warn (fun m -> m "pdf does not work with urls: ignoring %s" l)
  | Path p ->
      let attrs =
        Attributes.add_class attrs ("slipshow__carousel", Meta.none)
      in
      let src =
        match Fpath.Map.find_opt p (files : Ast.Files.map) with
        | None ->
            Logs.warn (fun m -> m "No pdf found: %a" Fpath.pp p);
            Fpath.to_string p
        | Some { content; mode = `Base64; _ } ->
            let base64 = Base64.encode_string content in
            Format.sprintf "%s" base64
      in
      let plain_text i =
        let lines = Inline.to_plain_text ~break_on_soft:false i in
        String.concat "\n" (List.map (String.concat "") lines)
      in
      C.string c "<span slipshow-pdf";
      C.string c " pdf-src=\"";
      pct_encoded_string c src;
      C.string c "\" alt=\"";
      html_escaped_string c (plain_text i.Inline.Link.text);
      C.byte c '\"';
      add_attrs c attrs;
      C.string c ">";
      C.string c "</span>"

let svg c ~uri ~files i attrs =
  let src = src uri files in
  match src with
  | `Link _ -> media ~media_name:"svg" c ~uri ~files i attrs
  | `Source (content, _mime_type) ->
      let attrs =
        Attributes.add_class attrs ("slipshow-svg-container", Meta.none)
      in
      with_attrs_span c attrs @@ fun () -> C.string c content

let pure_embed c uri files attrs =
  match uri with
  | Asset.Uri.Link _ -> Logs.err (fun m -> m "Could not embed a pure embed")
  | Path p -> (
      match Fpath.Map.find_opt p (files : Ast.Files.map) with
      | None -> Logs.err (fun m -> m "Could not embed a pure embed v2")
      | Some { content; mode = `Base64; _ } ->
          C.string c "<span x-data=\"";
          html_escaped_string c content;
          C.string c "\" ";
          add_attrs c attrs;
          C.string c "></span>")

let inline c = function
  | Inline.Autolink ((a, (attrs, _)), _) ->
      autolink c a attrs;
      true
  | Break (b, _) ->
      break c b;
      true
  | Code_span ((cs, (attrs, _)), _) ->
      code_span c cs attrs;
      true
  | Emphasis ((e, (attrs, _)), _) ->
      emphasis c e attrs;
      true
  | Inlines (is, _) ->
      List.iter (C.inline c) is;
      true
  | Link ((l, (attrs, _)), _) ->
      link c l attrs;
      true
  | Raw_html (html, _) ->
      raw_html c html;
      true
  | Strong_emphasis ((e, (attrs, _)), _) ->
      strong_emphasis c e attrs;
      true
  | Text ((t, (attrs, _)), _) ->
      ( in_block ~with_newline:false c "span" attrs @@ fun () ->
        html_escaped_string c t );
      true
  | Strikethrough ((s, (attrs, _)), _) ->
      strikethrough c s attrs;
      true
  | Attrs_span (as', _) ->
      attribute_span c as';
      true
  | Math_span ((ms, (attrs, _)), _) ->
      (with_attrs_span ~with_newline:false c attrs @@ fun () -> math_span c ms);
      true
  | Image { uri = uri, _; id = _; origin = (l, (attrs, _)), _ } ->
      media ~media_name:"img" c ~uri ~files:(files c) l attrs;
      true
  | Video { uri = uri, _; id = _; origin = (l, (attrs, _)), _ } ->
      media ~media_name:"video" c ~uri ~files:(files c) l attrs;
      true
  | Audio { uri = uri, _; id = _; origin = (l, (attrs, _)), _ } ->
      media ~media_name:"audio" c ~uri ~files:(files c) l attrs;
      true
  | Pdf { uri = uri, _; id = _; origin = (l, (attrs, _)), _ } ->
      pdf c ~uri ~files:(files c) l attrs;
      true
  | Svg { uri = uri, _; id = _; origin = (l, (attrs, _)), _ } ->
      svg c ~uri ~files:(files c) l attrs;
      true
  | Hand_drawn { uri = uri, _; id = _; origin = (_, (attrs, _)), _ } ->
      let attrs =
        Attributes.add_class attrs ("slipshow-hand-drawn", Meta.none)
      in
      pure_embed c uri (files c) attrs;
      true

(* Block rendering *)

let block_quote c attrs bq =
  in_block c "blockquote" attrs @@ fun () ->
  C.block c bq.Block.Block_quote.block

let code_block c attrs cb =
  let i = Option.map fst (Block.Code_block.info_string cb) in
  let lang = Option.bind i Block.Code_block.language_of_info_string in
  let line (l, _) =
    html_escaped_string c l;
    C.byte c '\n'
  in
  match lang with
  | Some (lang, _env) when backend_blocks c && lang.[0] = '=' ->
      if lang = "=html" && not (safe c) then
        in_block c "div" attrs @@ fun () ->
        block_lines c (Block.Code_block.code cb)
      else ()
  | _ ->
      ( in_block c ~with_newline:false "pre" attrs @@ fun () ->
        C.string c "<code";
        begin match lang with
        | None -> ()
        | Some (lang, _env) ->
            C.string c " class=\"language-";
            html_escaped_string c lang;
            C.byte c '\"'
        end;
        C.byte c '>';
        List.iter line (Block.Code_block.code cb);
        C.string c "</code>" );
      C.byte c '\n'

let heading c attrs h =
  let level = string_of_int h.Block.Heading.level in
  C.string c "<h";
  C.string c level;
  add_attrs c attrs;
  C.byte c '>';
  begin match Attributes.id attrs with
  | None -> ()
  | Some (id, _) ->
      C.string c "<a class=\"anchor\" aria-hidden=\"true\" href=\"#";
      C.string c id;
      C.string c "\"></a>"
  end;
  C.inline c h.Block.Heading.inline;
  C.string c "</h";
  C.string c level;
  C.string c ">\n"

let paragraph c attrs p =
  in_block c ~with_newline:false "p" attrs (fun () ->
      C.inline c p.Block.Paragraph.inline);
  C.string c "\n"

let item_block ~tight c = function
  | Block.Blank_line _ -> ()
  | Paragraph ((p, _todo), _) when tight -> C.inline c p.Block.Paragraph.inline
  | Blocks (bs, _) ->
      let rec loop c add_nl = function
        | Block.Blank_line _ :: bs -> loop c add_nl bs
        | Paragraph ((p, _todo), _) :: bs when tight ->
            C.inline c p.Block.Paragraph.inline;
            loop c true bs
        | b :: bs ->
            if add_nl then C.byte c '\n';
            C.block c b;
            loop c false bs
        | [] -> ()
      in
      loop c true bs
  | b ->
      C.byte c '\n';
      C.block c b

let list_item ~tight c (i, _) =
  match i.Block.List_item.ext_task_marker with
  | None ->
      C.string c "<li>";
      item_block ~tight c i.Block.List_item.block;
      C.string c "</li>\n"
  | Some (mark, _) ->
      C.string c "<li>";
      let close =
        match Cmarkit.Block.List_item.task_status_of_task_marker mark with
        | `Unchecked ->
            C.string c
              "<div class=\"task\"><input type=\"checkbox\" disabled><div>";
            "</div></div></li>\n"
        | `Checked | `Other _ ->
            C.string c
              "<div class=\"task\"><input type=\"checkbox\" disabled \
               checked><div>";
            "</div></div></li>\n"
        | `Cancelled ->
            C.string c
              "<div class=\"task\"><input type=\"checkbox\" disabled><del>";
            "</del></div></li>\n"
      in
      item_block ~tight c i.Block.List_item.block;
      C.string c close

let list c attrs l =
  let tight = l.Block.List'.tight in
  with_attrs c attrs @@ fun () ->
  match l.Block.List'.type' with
  | `Unordered _ ->
      C.string c "<ul>\n";
      List.iter (list_item ~tight c) l.Block.List'.items;
      C.string c "</ul>\n"
  | `Ordered (start, _) ->
      C.string c "<ol";
      if start = 1 then C.string c ">\n"
      else (
        C.string c " start=\"";
        C.string c (string_of_int start);
        C.string c "\">\n");
      List.iter (list_item ~tight c) l.Block.List'.items;
      C.string c "</ol>\n"

let html_block c attrs lines =
  with_attrs c attrs @@ fun () ->
  let line (l, _) =
    C.string c l;
    C.byte c '\n'
  in
  if safe c then (
    comment c "CommonMark HTML block omitted";
    C.byte c '\n')
  else List.iter line lines

let thematic_break c = open_block c "hr"

let math_block c attrs cb =
  let line l =
    html_escaped_string c (Cmarkit.Block_line.to_string l);
    C.byte c '\n'
  in
  with_attrs c attrs @@ fun () ->
  C.string c "\\[\n";
  List.iter line (Block.Code_block.code cb);
  C.string c "\\]\n"

let table c attrs t =
  let start c align tag =
    C.byte c '<';
    C.string c tag;
    match align with
    | None -> C.byte c '>'
    | Some `Left -> C.string c " class=\"left\">"
    | Some `Center -> C.string c " class=\"center\">"
    | Some `Right -> C.string c " class=\"right\">"
  in
  let close c tag =
    C.string c "</";
    C.string c tag;
    C.string c ">\n"
  in
  let rec cols c tag ~align count cs =
    match (align, cs) with
    | (a, _) :: align, (col, _) :: cs ->
        start c (fst a) tag;
        C.inline c col;
        close c tag;
        cols c tag ~align (count - 1) cs
    | (a, _) :: align, [] ->
        start c (fst a) tag;
        close c tag;
        cols c tag ~align (count - 1) []
    | [], (col, _) :: cs ->
        start c None tag;
        C.inline c col;
        close c tag;
        cols c tag ~align:[] (count - 1) cs
    | [], [] ->
        for _i = count downto 1 do
          start c None tag;
          close c tag
        done
  in
  let row c tag ~align count cs =
    C.string c "<tr>\n";
    cols c tag ~align count cs;
    C.string c "</tr>\n"
  in
  let header c count ~align cols = row c "th" ~align count cols in
  let data c count ~align cols = row c "td" ~align count cols in
  let rec rows c col_count ~align = function
    | ((`Header cols, _), _) :: rs ->
        let align, rs =
          match rs with
          | ((`Sep align, _), _) :: rs -> (align, rs)
          | _ -> (align, rs)
        in
        header c col_count ~align cols;
        rows c col_count ~align rs
    | ((`Data cols, _), _) :: rs ->
        data c col_count ~align cols;
        rows c col_count ~align rs
    | ((`Sep align, _), _) :: rs -> rows c col_count ~align rs
    | [] -> ()
  in
  with_attrs c attrs @@ fun () ->
  C.string c "<div role=\"region\"><table>\n";
  rows c t.Block.Table.col_count ~align:[] t.Block.Table.rows;
  C.string c "</table></div>"

let standalone_attributes c attrs =
  with_attrs ~with_newline:false c attrs (fun () -> ());
  if Attributes.is_empty attrs then () else C.string c "\n"

let div c b attrs =
  let should_include_div =
    let attrs_is_not_empty = not @@ Attributes.is_empty attrs in
    let contains_multiple_blocks =
      let is_multiple l =
        l
        |> List.filter (function Block.Blank_line _ -> false | _ -> true)
        |> List.length |> ( <= ) 2
      in
      match b with Block.Blocks (l, _) when is_multiple l -> true | _ -> false
    in
    attrs_is_not_empty || contains_multiple_blocks
  in
  if should_include_div then in_block c "div" attrs (fun () -> C.block c b)
  else C.block c b;
  true

let carousel c l attrs =
  let attrs = Attributes.add_class attrs ("slipshow__carousel", Meta.none) in
  let children_attrs =
    Attributes.make ~class':[ ("slipshow__carousel_children", Meta.none) ] ()
  in
  in_block c "div" attrs (fun () ->
      List.iteri
        (fun i b ->
          let attrs =
            if i = 0 then
              Attributes.add_class children_attrs
                ("slipshow__carousel_active", Meta.none)
            else children_attrs
          in
          in_block c "div" attrs @@ fun () -> C.block c b)
        l);
  true

let slide c content title attrs =
  let () =
    in_block c "div"
      (Attributes.add_class attrs ("slipshow-rescaler", Meta.none))
    @@ fun () ->
    in_block c "div" (Attributes.make ~class':[ ("slide", Meta.none) ] ())
    @@ fun () ->
    (match title with
    | None -> ()
    | Some (title, (title_attrs, _)) ->
        in_block c "div"
          (Attributes.add_class title_attrs ("slide-title", Meta.none))
          (fun () -> C.inline c title));
    in_block c "div" (Attributes.make ~class':[ ("slide-body", Meta.none) ] ())
    @@ fun () -> C.block c content
  in
  true

let slip c slip attrs =
  let () =
    in_block c "div"
      (Attributes.add_class attrs ("slipshow-rescaler", Meta.none))
    @@ fun () ->
    in_block c "div" (Attributes.make ~class':[ ("slip", Meta.none) ] ())
    @@ fun () ->
    in_block c "div" (Attributes.make ~class':[ ("slip-body", Meta.none) ] ())
    @@ fun () -> C.block c slip
  in
  true

let slip_script c cb attrs =
  let attrs =
    Attributes.add ("type", Meta.none)
      (Some ({ v = "slip-script"; delimiter = None }, Meta.none))
      attrs
  in
  in_block c "script" attrs (fun () -> block_lines c (Block.Code_block.code cb));
  true

let mermaid_js c cb attrs =
  let attrs = Attributes.add_class attrs ("mermaid", Meta.none) in
  in_block c "pre" attrs (fun () -> block_lines c (Block.Code_block.code cb));
  true

let block c = function
  | Block.Block_quote ((bq, (attrs, _)), _) ->
      block_quote c attrs bq;
      true
  | Blocks (bs, _) ->
      List.iter (C.block c) bs;
      true
  | Code_block ((cb, (attrs, _)), _) ->
      code_block c attrs cb;
      true
  | Heading ((h, (attrs, _)), _) ->
      heading c attrs h;
      true
  | Html_block ((h, (attrs, _)), _) ->
      html_block c attrs h;
      true
  | List ((l, (attrs, _)), _) ->
      list c attrs l;
      true
  | Paragraph ((p, (attrs, _)), _) ->
      paragraph c attrs p;
      true
  | Thematic_break ((_, (attrs, _)), _) ->
      thematic_break c attrs;
      true
  | Math_block ((cb, (attrs, _)), _) ->
      math_block c attrs cb;
      true
  | Table ((t, (attrs, _)), _) ->
      table c attrs t;
      true
  | Standalone_attributes (attrs, _) ->
      standalone_attributes c attrs;
      true
  | Blank_line _ | Link_reference_definition _ | Attribute_definition _ -> true
  | Included ((b, (attrs, _)), _) | Div ((b, (attrs, _)), _) -> div c b attrs
  | Carousel ((l, (attrs, _)), _) -> carousel c l attrs
  | Slide (({ content; title }, (attrs, _)), _) -> slide c content title attrs
  | Slip ((s, (attrs, _)), _) -> slip c s attrs
  | SlipScript ((cb, (attrs, _)), _) -> slip_script c cb attrs
  | MermaidJS ((cb, (attrs, _)), _) -> mermaid_js c cb attrs
(* (\* XHTML rendering *\) *)

(* let xhtml_block c = function *)
(*   | Block.Thematic_break _ -> *)
(*       C.string c "<hr />\n"; *)
(*       true *)
(*   | b -> block c b *)

(* let xhtml_inline c = function *)
(*   | Inline.Break (b, _) when Inline.Break.type' b = `Hard -> *)
(*       C.string c "<br />\n"; *)
(*       true *)
(*   | Inline.Image ((i, (attrs, _)), _) -> *)
(*       image ~close:" />" c i attrs; *)
(*       true *)
(*   | i -> inline c i *)

(* (\* Document rendering *\) *)

(* let footnotes c fns = *)
(*   (\* XXX we could do something about recursive footnotes and footnotes in *)
(*      footnotes here. *\) *)
(*   let fns = Label.Map.fold (fun _ fn acc -> fn :: acc) fns [] in *)
(*   let fns = List.sort Stdlib.compare fns in *)
(*   let footnote c (_, id, refc, fn) = *)
(*     C.string c "<li id=\""; *)
(*     html_escaped_string c id; *)
(*     C.string c "\">\n"; *)
(*     C.block c (Block.Footnote.block fn); *)
(*     C.string c "<span>"; *)
(*     for r = 1 to !refc do *)
(*       C.string c "<a href=\"#"; *)
(*       pct_encoded_string c (footnote_ref_id id r); *)
(*       C.string c "\" role=\"doc-backlink\" class=\"fn-label\">↩︎︎"; *)
(*       if !refc > 1 then ( *)
(*         C.string c "<sup>"; *)
(*         C.string c (Int.to_string r); *)
(*         C.string c "</sup>"); *)
(*       C.string c "</a>" *)
(*     done; *)
(*     C.string c "</span>"; *)
(*     C.string c "</li>" *)
(*   in *)
(*   C.string c "<section role=\"doc-endnotes\"><ol>\n"; *)
(*   List.iter (footnote c) fns; *)
(*   C.string c "</ol></section>\n" *)

let doc c d =
  C.block c d.doc;
  (* let st = C.State.get c state in *)
  (* if Label.Map.is_empty st.footnotes then () else footnotes c st.footnotes; *)
  true

(* Renderer *)

let renderer ?backend_blocks ~safe () =
  let init_context = init_context ?backend_blocks ~safe in
  Ast_renderer.make ~init_context ~inline ~block ~doc ()

(* let xhtml_renderer ?backend_blocks ~safe () = *)
(*   let init_context = init_context ?backend_blocks ~safe in *)
(*   let inline = xhtml_inline and block = xhtml_block in *)
(*   Cmarkit_renderer.make ~init_context ~inline ~block ~doc () *)

let of_doc ?backend_blocks ~safe d =
  Ast_renderer.doc_to_string (renderer ?backend_blocks ~safe ()) d
