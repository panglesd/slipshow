(*---------------------------------------------------------------------------
   Copyright (c) 2021 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Cmarkit
module C = Cmarkit_renderer.Context
module String_set = Set.Make (String)

(* Renderer state *)

type state =
  { safe : bool;
    backend_blocks : bool;
    mutable ids : String_set.t;
    mutable footnote_count : int;
    mutable footnotes :
      (* Text, id, ref count, footnote *)
      (string * string * int ref * Block.Footnote.t) Label.Map.t  }

let state : state C.State.t = C.State.make ()
let safe c = (C.State.get c state).safe
let backend_blocks c = (C.State.get c state).backend_blocks
let init_context ?(backend_blocks = false) ~safe c _ =
  let ids = String_set.empty and footnotes = Label.Map.empty in
  let st = { safe; backend_blocks; ids; footnote_count = 0; footnotes } in
  C.State.set c state (Some st)

let unique_id c id =
  let st = C.State.get c state in
  let rec loop ids id c =
    let id' = if c = 0 then id else (String.concat "-" [id; Int.to_string c]) in
    match String_set.mem id' ids with
    | true -> loop ids id (c + 1)
    | false -> st.ids <- String_set.add id' ids; id'
  in
  loop st.ids id 0

let footnote_id label =
  let make_label l = String.map (function ' ' | '\t' -> '-' | c -> c) l in
  "fn-" ^ (make_label (String.sub label 1 (String.length label - 1)))

let footnote_ref_id fnid c = String.concat "-" ["ref"; Int.to_string c; fnid]

let make_footnote_ref_ids c label fn =
  let st = C.State.get c state in
  match Label.Map.find_opt label st.footnotes with
  | Some (text, id, refc, _) -> incr refc; (text, id, footnote_ref_id id !refc)
  | None ->
      st.footnote_count <- st.footnote_count + 1;
      let text = String.concat "" ["["; Int.to_string st.footnote_count;"]"] in
      let id = footnote_id label in
      st.footnotes <- Label.Map.add label (text, id, ref 1, fn) st.footnotes;
      text, id, footnote_ref_id id 1

(* Escaping *)

let buffer_add_html_escaped_uchar b u = match Uchar.to_int u with
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
    if start < len then Buffer.add_substring b s start (i - start);
  in
  let rec loop start i =
    if i > max_idx then flush b start i else
    let next = i + 1 in
    match String.get s i with
    | '\x00' ->
        flush b start i; Buffer.add_utf_8_uchar b Uchar.rep; loop next next
    | '&' -> flush b start i; string b "&amp;"; loop next next
    | '<' -> flush b start i; string b "&lt;"; loop next next
    | '>' -> flush b start i; string b "&gt;"; loop next next
(*    | '\'' -> flush c start i; string c "&apos;"; loop next next *)
    | '\"' -> flush b start i; string b "&quot;"; loop next next
    | c -> loop start next
  in
  loop 0 0

let html_escaped_string c s = buffer_add_html_escaped_string (C.buffer c) s

let buffer_add_pct_encoded_string b s = (* Percent encoded + HTML escaped *)
  let byte = Buffer.add_char and string = Buffer.add_string in
  let unsafe_hexdig_of_int i = match i < 10 with
  | true -> Char.unsafe_chr (i + 0x30)
  | false -> Char.unsafe_chr (i + 0x37)
  in
  let flush b max start i =
    if start <= max then Buffer.add_substring b s start (i - start);
  in
  let rec loop b s max start i =
    if i > max then flush b max start i else
    let next = i + 1 in
    match String.get s i with
    | '%' (* In CommonMark destinations may have percent encoded chars *)
    (* See https://tools.ietf.org/html/rfc3986 *)
    (* unreserved *)
    | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '-' | '.' | '_' | '~'
    (* sub-delims *)
    | '!' | '$' | (*'&' | '\'' | *) '(' | ')' | '*' | '+' | ',' | ';' | '='
    (* gen-delims *)
    | ':' | '/' | '?' | '#' | (* '[' | ']' cmark escapes them | *) '@' ->
        loop b s max start next
    | '&' -> flush b max start i; string b "&amp;"; loop b s max next next
    | '\'' -> flush b max start i; string b "&apos;"; loop b s max next next
    | c ->
        flush b max start i;
        let hi = (Char.code c lsr 4) land 0xF in
        let lo = (Char.code c) land 0xF in
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
  | Some {Attributes.v = value; delimiter = Some d} ->
     let s = Format.sprintf " %s=%c%s%c" key d value d in
     C.string c s
  | Some {Attributes.v = value; delimiter = None} -> C.string c (" " ^ key ^ "=" ^ value);
  | None -> C.string c (" " ^ key)

let add_attrs c attrs =
  let kv_attrs =
    let kv_attrs = Cmarkit.Attributes.kv_attributes attrs in
    List.map
      (fun ((k,_), v) ->
        let v = match v with None -> None | Some (v, _) -> Some v in
        (k,v))
      kv_attrs
  in
  let class' =
    let class' = Cmarkit.Attributes.class' attrs in
    let class' = List.map (fun (c, _) -> c) class' in
    match class' with
    | [] -> []
    | _ ->
       let v = String.concat " " class' in
       ["class", Some {Attributes.v ; delimiter = Some '"'} ]
  in
  let id =
    let id = Cmarkit.Attributes.id attrs in
    match id with
    | Some (id, _) -> ["id", Some {Attributes.v =id; delimiter = Some '"'} ]
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
  if Attributes.is_empty attrs then f() else
  in_block c ~with_newline "div" attrs f

let with_attrs_span c ?(with_newline = true) attrs f =
  if Attributes.is_empty attrs then f() else
  in_block c ~with_newline "span" attrs f

let comment c s =
  C.string c "<!-- "; html_escaped_string c s; C.string c " -->"

let comment_undefined_label c l = match Inline.Link.referenced_label l with
| None -> () | Some def -> comment c ("Undefined label " ^ (Label.key def))

let comment_unknown_def_type c l = match Inline.Link.referenced_label l with
| None -> () | Some def ->
    comment c ("Unknown label definition type for " ^ (Label.key def))

let comment_foonote_image c l = match Inline.Link.referenced_label l with
| None -> () | Some def ->
    comment c ("Footnote " ^ (Label.key def) ^ " referenced as image")

let comment_attribute_image c l = match Inline.Link.referenced_label l with
| None -> () | Some def ->
    comment c ("Attribute " ^ (Label.key def) ^ " referenced as image")

let block_lines c = function (* newlines only between lines *)
| [] -> () | (l, _) :: ls ->
    let line c (l, _) = C.byte c '\n'; C.string c l in
    C.string c l; List.iter (line c) ls

(* Inline rendering *)

let autolink c a attrs =
  let pre = if Inline.Autolink.is_email a then "mailto:" else "" in
  let url = pre ^ (fst (Inline.Autolink.link a)) in
  let url = if Inline.Link.is_unsafe url then "" else url in
  C.string c "<a href=\""; pct_encoded_string c url;
  add_attrs c attrs;
  C.string c "\">";
  html_escaped_string c (fst (Inline.Autolink.link a));
  C.string c "</a>"

let break c b = match Inline.Break.type' b with
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
  C.inline c (Inline.Emphasis.inline e); C.string c "</em>"

let strong_emphasis c e attrs =
  C.string c "<strong";
  add_attrs c attrs;
  C.string c ">";
  C.inline c (Inline.Emphasis.inline e);
  C.string c "</strong>"

let link_dest_and_title c ld =
  let dest = match Link_definition.dest ld with
  (* | None -> "" *)
  | (* Some *) (link, _) when safe c && Inline.Link.is_unsafe link -> ""
  | (* Some *) (link, _) -> link
  in
  let title = match Link_definition.title ld with
  | None -> ""
  | Some title -> String.concat "\n" (List.map (fun (_, (t, _)) -> t) title)
  in
  dest, title

let image ?(close = " >") c i attrs =
  match Inline.Link.reference_definition (C.get_defs c) i with
  | Some (Link_definition.Def ((ld, (attributes, _)), _)) ->
     let attributes = Attributes.merge ~base:attributes ~new_attrs:attrs in
      let plain_text c i =
        let lines = Inline.to_plain_text ~break_on_soft:false i in
        String.concat "\n" (List.map (String.concat "") lines)
      in
      let link, title = link_dest_and_title c ld in
      C.string c "<img src=\""; pct_encoded_string c link;
      C.string c "\" alt=\"";
      html_escaped_string c (plain_text c (Inline.Link.text i));
      C.byte c '\"';
      if title <> ""
      then (C.string c " title=\""; html_escaped_string c title; C.byte c '\"');
      add_attrs c attributes;
      C.string c close
  | Some (Block.Footnote.Def _) -> comment_foonote_image c i
  | Some (Block.Attribute_definition.Def _) -> comment_foonote_image c i
  | None -> comment_undefined_label c i
  | Some _ -> comment_unknown_def_type c i

let link_footnote c l fn =
  let key = Label.key (Option.get (Inline.Link.referenced_label l)) in
  let text, label, ref = make_footnote_ref_ids c key fn in
  let is_full_ref = match Inline.Link.reference l with
  | `Ref (`Full, _, _) -> true | _ -> false
  in
  if is_full_ref then begin
    C.string c "<a href=\"#"; pct_encoded_string c label;
    C.string c "\" id=\""; html_escaped_string c ref;
    C.string c "\" role=\"doc-noteref\">";
    C.inline c (Inline.Link.text l); C.string c "</a>"
  end else begin
    C.string c "<sup><a href=\"#"; pct_encoded_string c label;
    C.string c "\" id=\""; html_escaped_string c ref;
    C.string c "\" role=\"doc-noteref\" class=\"fn-label\">";
    C.string c text; C.string c "</a></sup>"
  end

let link c l attrs = match Inline.Link.reference_definition (C.get_defs c) l with
| Some (Link_definition.Def ((ld, (attributes, _)), _)) ->
    let attributes = Attributes.merge ~base:attributes ~new_attrs:attrs in
    let link, title = link_dest_and_title c ld in
    C.string c "<a href=\""; pct_encoded_string c link;
    C.string c "\"";
    add_attrs c attributes;
    if title <> "" then
      (C.string c " title=\""; html_escaped_string c title; C.string c "\"");
    C.string c ">"; C.inline c (Inline.Link.text l); C.string c "</a>"
| Some (Block.Footnote.Def ((fn, todo), _)) -> link_footnote c l fn
| Some (Block.Attribute_definition.Def ((attrs, _), _)) ->
   let ext_attrs =
     Inline.Ext_attrs
       ((Inline.Attributes_span.make (Inline.Link.text l)
           (Block.Attribute_definition.attrs attrs)),
        Meta.none)
   in
   C.inline c ext_attrs
| None -> C.inline c (Inline.Link.text l); comment_undefined_label c l
| Some _ -> C.inline c (Inline.Link.text l); comment_unknown_def_type c l

let raw_html c h =
  if safe c then comment c "CommonMark raw HTML omitted" else
  let line c (_, (h, _)) = C.byte c '\n'; C.string c h in
  if h <> []
  then (C.string c (fst (snd (List.hd h))); List.iter (line c) (List.tl h))

let strikethrough c s attrs =
  C.string c "<del";
  add_attrs c attrs;
  C.string c ">";
  C.inline c (Inline.Strikethrough.inline s);
  C.string c "</del>"

let math_span c ms =
  let tex_line c l = html_escaped_string c (Block_line.tight_to_string l) in
  let tex_lines c = function (* newlines only between lines *)
  | [] -> () | l :: ls ->
      let line c l = C.byte c '\n'; tex_line c l in
      tex_line c l; List.iter (line c) ls
  in
  let tex = Inline.Math_span.tex_layout ms in
  if tex = [] then () else
  (C.string c (if Inline.Math_span.display ms then "\\[" else "\\(");
   tex_lines c tex;
   C.string c (if Inline.Math_span.display ms then "\\]" else "\\)"))

let attribute_span c as' =
  let content = Inline.Attributes_span.content as' in
  let attrs, _ = Inline.Attributes_span.attrs as' in
  with_attrs_span ~with_newline:false c attrs @@ fun () ->
  C.inline c content

let inline c = function
| Inline.Autolink ((a, (attrs, _)), _) -> autolink c a attrs; true
| Inline.Break (b, _) -> break c b; true
| Inline.Code_span ((cs, (attrs, _)), _) -> code_span c cs attrs; true
| Inline.Emphasis ((e, (attrs, _)), _) -> emphasis c e attrs; true
| Inline.Image ((i, (attrs, _)), _) -> image c i attrs; true
| Inline.Inlines (is, _) -> List.iter (C.inline c) is; true
| Inline.Link ((l, (attrs, _)), _) -> link c l attrs; true
| Inline.Raw_html (html, _) -> raw_html c html; true
| Inline.Strong_emphasis ((e, (attrs, _)), _) -> strong_emphasis c e attrs; true
| Inline.Text ((t, (attrs, _)), _) ->
   (with_attrs_span ~with_newline:false c attrs @@ fun () -> html_escaped_string c t);
   true
| Inline.Ext_strikethrough ((s, (attrs, _)), _) -> strikethrough c s attrs; true
| Inline.Ext_attrs (as', _) -> attribute_span c as'; true
| Inline.Ext_math_span ((ms, (attrs, _)), _) ->
   (with_attrs_span ~with_newline:false c attrs @@ fun () -> math_span c ms);
   true
| _ -> comment c "<!-- Unknown Cmarkit inline -->"; true

(* Block rendering *)

let block_quote c attrs bq =
  in_block c "blockquote" attrs @@ fun () ->
  C.block c (Block.Block_quote.block bq)

let code_block c attrs cb =
  let i = Option.map fst (Block.Code_block.info_string cb) in
  let lang = Option.bind i Block.Code_block.language_of_info_string in
  let line (l, _) = html_escaped_string c l; C.byte c '\n' in
  match lang with
  | Some (lang, _env) when backend_blocks c && lang.[0] = '=' ->
      if lang = "=html" && not (safe c)
      then
        in_block c "div" attrs @@ fun () ->
        block_lines c (Block.Code_block.code cb)
      else ()
  | _ ->
      (in_block c ~with_newline:false "pre" attrs @@ fun () ->
      C.string c "<code";
      begin match lang with
      | None -> ()
      | Some (lang, _env) ->
          C.string c " class=\"language-"; html_escaped_string c lang;
          C.byte c '\"'
      end;
      C.byte c '>';
      List.iter line (Block.Code_block.code cb);
      C.string c "</code>");
      C.byte c '\n'

let heading c attrs h =
  let level = string_of_int (Block.Heading.level h) in
  C.string c "<h"; C.string c level;
  let attrs =
    match Block.Heading.id h with
    | None -> attrs
    | Some (`Auto id | `Id id) ->
       match Attributes.id attrs with
         None ->
          let id = unique_id c id in
          Attributes.set_id attrs (id, Meta.none)
       | Some id -> attrs
  in
  add_attrs c attrs;
  C.byte c '>';
  begin match Attributes.id attrs with
  | None -> ()
  | Some (id, _) ->
      C.string c "<a class=\"anchor\" aria-hidden=\"true\" href=\"#";
      C.string c id; C.string c "\"></a>";
  end;
  C.inline c (Block.Heading.inline h);
  C.string c "</h"; C.string c level; C.string c ">\n"

let paragraph c attrs p =
  in_block c ~with_newline:false "p" attrs (fun () ->
  C.inline c (Block.Paragraph.inline p));
  C.string c "\n"

let item_block ~tight c = function
| Block.Blank_line _ -> ()
| Block.Paragraph ((p, todo), _) when tight -> C.inline c (Block.Paragraph.inline p)
| Block.Blocks (bs, _) ->
    let rec loop c add_nl = function
    | Block.Blank_line _ :: bs -> loop c add_nl bs
    | Block.Paragraph ((p, todo),_) :: bs when tight ->
        C.inline c (Block.Paragraph.inline p); loop c true bs
    | b :: bs -> (if add_nl then C.byte c '\n'); C.block c b; loop c false bs
    | [] -> ()
    in
    loop c true bs
| b -> C.byte c '\n'; C.block c b

let list_item ~tight c (i, _) = match Block.List_item.ext_task_marker i with
| None ->
    C.string c "<li>";
    item_block ~tight c (Block.List_item.block i);
    C.string c "</li>\n"
| Some (mark, _) ->
    C.string c "<li>";
    let close = match Block.List_item.task_status_of_task_marker mark with
    | `Unchecked ->
        C.string c
          "<div class=\"task\"><input type=\"checkbox\" disabled><div>";
        "</div></div></li>\n"
    | `Checked | `Other _ ->
        C.string c
          "<div class=\"task\"><input type=\"checkbox\" disabled checked><div>";
        "</div></div></li>\n"
    | `Cancelled ->
        C.string c
          "<div class=\"task\"><input type=\"checkbox\" disabled><del>";
        "</del></div></li>\n"
    in
    item_block ~tight c (Block.List_item.block i);
    C.string c close

let list c attrs l =
  let tight = Block.List'.tight l in
  with_attrs c attrs @@ fun () ->
  match Block.List'.type' l with
  | `Unordered _ ->
      C.string c "<ul>\n";
      List.iter (list_item ~tight c) (Block.List'.items l);
      C.string c "</ul>\n"
  | `Ordered (start, _) ->
      C.string c "<ol";
      if start = 1 then C.string c ">\n" else
      (C.string c " start=\""; C.string c (string_of_int start);
       C.string c "\">\n");
      List.iter (list_item ~tight c) (Block.List'.items l);
      C.string c "</ol>\n"

let html_block c attrs lines =
  with_attrs c attrs @@ fun () ->
  let line (l, _) = C.string c l; C.byte c '\n' in
  if safe c then (comment c "CommonMark HTML block omitted"; C.byte c '\n') else
  List.iter line lines

let thematic_break c = open_block c "hr"

let math_block c attrs cb =
  let line l = html_escaped_string c (Block_line.to_string l); C.byte c '\n' in
  with_attrs c attrs @@ fun () ->
  C.string c "\\[\n";
  List.iter line (Block.Code_block.code cb);
  C.string c "\\]\n"

let table c attrs t =
  let start c align tag =
    C.byte c '<'; C.string c tag;
    match align with
    | None -> C.byte c '>';
    | Some `Left -> C.string c " class=\"left\">"
    | Some `Center -> C.string c " class=\"center\">"
    | Some `Right -> C.string c " class=\"right\">"
  in
  let close c tag = C.string c "</"; C.string c tag; C.string c ">\n" in
  let rec cols c tag ~align count cs = match align, cs with
  | ((a, _) :: align), (col, _) :: cs ->
      start c (fst a) tag; C.inline c col; close c tag;
      cols c tag ~align (count - 1) cs
  | ((a, _) :: align), [] ->
      start c (fst a) tag; close c tag;
      cols c tag ~align (count - 1) []
  | [], (col, _) :: cs ->
      start c None tag; C.inline c col; close c tag;
      cols c tag ~align:[] (count - 1) cs
  | [], [] ->
      for i = count downto 1 do start c None tag; close c tag done;
  in
  let row c tag ~align count cs =
    C.string c "<tr>\n"; cols c tag ~align count cs; C.string c "</tr>\n";
  in
  let header c count ~align cols = row c "th" ~align count cols in
  let data c count ~align cols = row c "td" ~align count cols in
  let rec rows c col_count ~align = function
  | ((`Header cols, _), _) :: rs ->
      let align, rs = match rs with
      | ((`Sep align, _), _) :: rs -> align, rs
      | _ -> align, rs
      in
      header c col_count ~align cols; rows c col_count ~align rs
  | ((`Data cols, _), _) :: rs ->
      data c col_count ~align cols; rows c col_count ~align rs
  | ((`Sep align, _), _) :: rs -> rows c col_count ~align rs
  | [] -> ()
  in
  with_attrs c attrs @@ fun () ->
  C.string c "<div role=\"region\"><table>\n";
  rows c (Block.Table.col_count t) ~align:[] (Block.Table.rows t);
  C.string c "</table></div>"

let standalone_attributes c attrs =
  with_attrs ~with_newline:false c attrs (fun () -> ());
  if Attributes.is_empty attrs then () else C.string c "\n"

let block c = function
| Block.Block_quote ((bq, (attrs, _)), _) -> block_quote c attrs bq; true
| Block.Blocks (bs, _) -> List.iter (C.block c) bs; true
| Block.Code_block ((cb, (attrs, _)), _) -> code_block c attrs cb; true
| Block.Heading ((h, (attrs, _)), _) -> heading c attrs h; true
| Block.Html_block ((h, (attrs, _)), _) -> html_block c attrs h; true
| Block.List ((l, (attrs, _)), _) -> list c attrs l; true
| Block.Paragraph ((p, (attrs, _)), _) -> paragraph c attrs p; true
| Block.Thematic_break ((_, (attrs, _)), _) -> thematic_break c attrs; true
| Block.Ext_math_block ((cb, (attrs, _)), _) -> math_block c attrs cb; true
| Block.Ext_table ((t, (attrs, _)), _) -> table c attrs t; true
| Block.Ext_standalone_attributes (attrs, _) -> standalone_attributes c attrs; true
| Block.Blank_line _
| Block.Link_reference_definition _
| Block.Ext_footnote_definition _
| Block.Ext_attribute_definition _ -> true
| _ -> comment c "Unknown Cmarkit block"; C.byte c '\n'; true

(* XHTML rendering *)

let xhtml_block c = function
| Block.Thematic_break _ -> C.string c "<hr />\n"; true
| b -> block c b

let xhtml_inline c = function
| Inline.Break (b, _) when Inline.Break.type' b = `Hard ->
    C.string c "<br />\n"; true
| Inline.Image ((i, (attrs, _)), _) ->
    image ~close:" />" c i attrs; true
| i -> inline c i

(* Document rendering *)

let footnotes c fns =
  (* XXX we could do something about recursive footnotes and footnotes in
     footnotes here. *)
  let fns = Label.Map.fold (fun _ fn acc -> fn :: acc) fns [] in
  let fns = List.sort Stdlib.compare fns in
  let footnote c (_, id, refc, fn) =
    C.string c "<li id=\""; html_escaped_string c id; C.string c "\">\n";
    C.block c (Block.Footnote.block fn);
    C.string c "<span>";
    for r = 1 to !refc do
      C.string c "<a href=\"#"; pct_encoded_string c (footnote_ref_id id r);
      C.string c "\" role=\"doc-backlink\" class=\"fn-label\">↩︎︎";
      if !refc > 1 then
        (C.string c "<sup>"; C.string c (Int.to_string r); C.string c "</sup>");
      C.string c "</a>"
    done;
    C.string c "</span>";
    C.string c "</li>"
  in
  C.string c "<section role=\"doc-endnotes\"><ol>\n";
  List.iter (footnote c) fns;
  C.string c "</ol></section>\n"

let doc c d =
  C.block c (Doc.block d);
  let st = C.State.get c state in
  if Label.Map.is_empty st.footnotes then () else footnotes c st.footnotes;
  true

(* Renderer *)

let renderer ?backend_blocks ~safe () =
  let init_context = init_context ?backend_blocks ~safe in
  Cmarkit_renderer.make ~init_context ~inline ~block ~doc ()

let xhtml_renderer ?backend_blocks ~safe () =
  let init_context = init_context ?backend_blocks ~safe in
  let inline = xhtml_inline and block = xhtml_block in
  Cmarkit_renderer.make ~init_context ~inline ~block ~doc ()

let of_doc ?backend_blocks ~safe d =
  Cmarkit_renderer.doc_to_string (renderer ~safe ()) d
