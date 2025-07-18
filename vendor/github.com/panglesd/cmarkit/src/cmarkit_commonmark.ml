(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Cmarkit
module C = Cmarkit_renderer.Context

(* Renderer state *)

type indent =
[ `I of int | `L of int * string * int * Uchar.t option | `Q of int
| `Fn of int * Label.t ]

type state =
  { include_attributes : bool;
    nl : string; (* newline to output. *)
    mutable sot : bool; (* start of text *)
    mutable indents : indent list; (* indentation stack. *) }

let state : state C.State.t = C.State.make ()
let get_state c = C.State.get c state
let init_context ~include_attributes c d =
  C.State.set c state
    (Some
       { include_attributes ;
         nl = Cmarkit.Doc.nl d;
         sot = true;
         indents = [] })

let include_attributes c =
  let state = get_state c in
  state.include_attributes

(* Escaping *)

module Char_set = Set.Make (Char)

let esc_angles = Char_set.of_list ['<'; '>']
let esc_parens = Char_set.of_list ['(';')' ]
let esc_quote = Char_set.singleton '\''
let esc_dquote = Char_set.singleton '\"'
let esc_link_label = Char_set.of_list ['['; ']'; '\\']

let buffer_add_dec_esc b c =
  Buffer.add_string b "&#";
  Buffer.add_string b (Int.to_string (Char.code c));
  Buffer.add_char b ';'

let buffer_add_bslash_esc b c =
  Buffer.add_char b '\\'; Buffer.add_char b c

let buffer_add_escaped_string ?(esc_ctrl = true) b cs s =
  let flush b max start i =
    if start <= max then Buffer.add_substring b s start (i - start)
  in
  let rec loop b s max start i =
    if i > max then flush b max start i else
    let next = i + 1 in
    let c = String.get s i in
    if Char_set.mem c cs then
      (flush b max start i; buffer_add_bslash_esc b c; loop b s max next next)
    else if esc_ctrl && Cmarkit_base.Ascii.is_control c then
      (flush b max start i; buffer_add_dec_esc b c; loop b s max next next)
    else loop b s max start next
  in
  loop b s (String.length s - 1) 0 0

let escaped_string ?esc_ctrl c cs s =
  buffer_add_escaped_string ?esc_ctrl (C.buffer c) cs s

let buffer_add_escaped_text b s =
  let esc_first b s = match s.[0] with
  | '-' | '+' | '_' | '=' as c ->
      Buffer.add_char b '\\'; Buffer.add_char b c; true
  | _ -> false
  in
  let esc_amp s max next =
    next <= max && (Cmarkit_base.Ascii.is_letter s.[next] || s.[next] = '#')
  in
  let esc_tilde s max prev next =
    not (Char.equal prev '~') && next <= max && s.[next] = '~'
  in
  let esc_item_marker s i =
    if i = 0 || i > 9 (* marker has from 1-9 digits *) then false else
    let k = ref (i - 1) in
    while !k >= 0 && Cmarkit_base.Ascii.is_digit s.[!k] do decr k done;
    !k < 0
  in
  let flush b max start i =
    if start <= max then Buffer.add_substring b s start (i - start)
  in
  let rec loop b s max start prev i =
    if i > max then flush b max start i else
    let next = i + 1 in
    let c = String.get s i in
    if Cmarkit_base.Ascii.is_control c then
      (flush b max start i; buffer_add_dec_esc b c; loop b s max next c next)
    else match c with
    | '#' | '`' when not (Char.equal prev c) ->
        flush b max start i; buffer_add_bslash_esc b c; loop b s max next c next
    | '~' when esc_tilde s max prev next ->
        flush b max start i; buffer_add_bslash_esc b c; loop b s max next c next
    | '&' when esc_amp s max next ->
        flush b max start i; buffer_add_bslash_esc b c; loop b s max next c next
    | '!' when i = max ->
        flush b max start i; buffer_add_bslash_esc b c; loop b s max next c next
    | '.' | ')' when esc_item_marker s i ->
        flush b max start i; buffer_add_bslash_esc b c; loop b s max next c next
    | '\\' | '<' | '>' | '[' | ']' | '*' | '_' | '$' | '|' ->
        flush b max start i; buffer_add_bslash_esc b c; loop b s max next c next
    | _ ->
        loop b s max start c next
  in
  let max = String.length s - 1 in
  if max < 0 then () else
  if esc_first b s then loop b s max 1 s.[0] 1 else loop b s max 0 '\x00' 0

let escaped_text c s = buffer_add_escaped_text (C.buffer c) s

(* Newlines, indentation and multi-line layouts of raw data. *)

let string_node_option c = function None -> () | Some (s, _) -> C.string c s
let nchars c n char = for i = 1 to n do C.byte c char done

let newline c =
  (* Block generally introduce newlines, except the first one. *)
  let st = get_state c in if st.sot then st.sot <- false else C.string c st.nl

let push_indent c n = let st = get_state c in st.indents <- n :: st.indents
let pop_indent c =
  let st = get_state c in
  match st.indents with [] -> () | ns -> st.indents <- (List.tl ns)

let rec indent c =
  let rec loop c acc = function
  | [] -> acc
  | `I n as i :: is ->
      nchars c n ' '; loop c (i :: acc) is
  | `Q n as i :: is ->
      nchars c n ' '; C.byte c '>';  C.byte c ' '; loop c (i :: acc) is
  | `L (before, m, after, task) :: is ->
      nchars c before ' '; C.string c m; nchars c after ' ';
      let after = match task with
      | None -> after
      | Some u -> C.byte c '['; C.utf_8_uchar c u; C.string c "] "; after + 4
      in
      (* On the next call we'll just indent for the list item *)
      loop c (`I (before + String.length m + after) :: acc) is
  | `Fn (before, label) :: is ->
      nchars c before ' ';
      C.byte c '['; link_label_lines c (Label.text label);
      C.string c "]:";
      (* On the next call we'll just indent to ^ for the footnote  *)
      loop c (`I (before + 1) :: acc) is
  in
  let st = get_state c in
  st.indents <- loop c [] (List.rev st.indents)

and link_label_lines c lines =
  escaped_tight_block_lines c esc_link_label lines

and escaped_tight_block_lines c cs = function
| [] -> () | l :: ls ->
    let tight c (blanks, (l, _)) = C.string c blanks; escaped_string c cs l in
    let line c l = newline c; indent c; tight c l in
    tight c l; List.iter (line c) ls

let block_lines c = function
| [] -> () | (l, _) :: ls ->
    let line c (l, _) = newline c; indent c; C.string c l in
    C.string c l; List.iter (line c) ls

let tight_block_lines c = function
| [] -> () | l :: ls ->
    let tight c (blanks, (l, _)) = C.string c blanks; C.string c l in
    let line c l = newline c; indent c; tight c l in
    tight c l; List.iter (line c) ls

(* Inline rendering *)

let attributes ?(inline = false) c attrs =
  if not (include_attributes c) then () else begin
  let kv_attrs =
    let kv_attrs = Cmarkit.Attributes.kv_attributes attrs in
    List.map
      (fun ((k,_), v) ->
        let v = match v with None -> None | Some (v, _) -> Some v in
        `Kv (k,v))
      kv_attrs
  in
  let class' =
    let class' = Cmarkit.Attributes.class' attrs in
    List.map (fun (c, _) -> `Class c) class'
  in
  let id =
    let id = Cmarkit.Attributes.id attrs in
    match id with
    | Some (id, _) -> [`Id id]
    | _ -> []
  in
  let attrs = id @ class' @ kv_attrs in
  if attrs = [] then () else
    begin
      if not inline then
        (newline c; indent c);
      let attrs =
        List.map
          (function
           | `Id v -> "#"^v
           | `Class v -> "." ^ v
           | `Kv (k, Some {Attributes.v; delimiter = Some delim}) -> Format.sprintf "%s=%c%s%c" k delim v delim
           | `Kv (k, Some {Attributes.v; delimiter = None}) -> k^"="^v
           | `Kv (k, None) -> k
          ) attrs
      in
      let s = String.concat " " attrs in
      C.string c "{";
      C.string c s;
      C.string c "}"
    end
  end

let autolink c a _TODO =
  C.byte c '<'; C.string c (fst (Inline.Autolink.link a)); C.byte c '>'

let break c b =
  let layout_before = fst (Inline.Break.layout_before b) in
  let layout_after = fst (Inline.Break.layout_after b) in
  let before, after = match Inline.Break.type' b with
  | `Soft -> layout_before, layout_after
  | `Hard -> (if layout_before = "" then "  " else layout_before), layout_after
  in
  C.string c before; newline c; indent c; C.string c after

let code_span c cs attrs =
  nchars c (Inline.Code_span.backtick_count cs) '`';
  tight_block_lines c (Inline.Code_span.code_layout cs);
  nchars c (Inline.Code_span.backtick_count cs) '`';
  attributes ~inline:true c attrs

let emphasis c e attrs =
  let delim = Inline.Emphasis.delim e and i = Inline.Emphasis.inline e in
  let delim = if not (delim = '*' || delim = '_') then '*' else delim in
  C.byte c delim; C.inline c i; C.byte c delim;
  attributes ~inline:true c attrs

let strong_emphasis c e attrs =
  let delim = Inline.Emphasis.delim e and i = Inline.Emphasis.inline e in
  let delim = if not (delim = '*' || delim = '_') then '*' else delim in
  C.byte c delim;  C.byte c delim; C.inline c i; C.byte c delim; C.byte c delim;
  attributes ~inline:true c attrs

let link_title c open_delim title = match title with
| None -> ()
| Some lines ->
    let open', close, escapes = match open_delim with
    | '\"' as delim -> delim, delim, esc_dquote
    | '\'' as delim -> delim, delim, esc_quote
    | '(' -> '(', ')', esc_parens
    | _ -> '\"', '\"', esc_dquote
    in
    C.byte c open'; escaped_tight_block_lines c escapes lines; C.byte c close

let link_definition c ld =
  let layout = Link_definition.layout ld in
  block_lines c layout.before_dest;
  begin match Link_definition.dest ld with
  (* | None -> () *)
  | (* Some *) (dest, _) ->
      if layout.angled_dest
      then (C.byte c '<'; escaped_string c esc_angles dest; C.byte c '>')
      else (escaped_string c esc_parens dest)
  end;
  if layout.after_dest = [] &&
     (* Option.is_some (Link_definition.dest ld) && *)
     Option.is_some (Link_definition.title ld)
  then C.byte c ' ' (* at least a space is needed *);
  block_lines c layout.after_dest;
  link_title c layout.title_open_delim (Link_definition.title ld);
  block_lines c layout.after_title

let link c l attrs = (match Inline.Link.reference l with
| `Inline ((ld, _), _) ->
    C.byte c '['; C.inline c (Inline.Link.text l); C.byte c ']';
    C.byte c '('; link_definition c ld; C.byte c ')'
| `Ref (`Shortcut, label, _) ->
    C.byte c '['; link_label_lines c (Label.text label); C.byte c ']';
| `Ref (`Collapsed, label, _) ->
    C.byte c '['; link_label_lines c (Label.text label); C.byte c ']';
    C.string c "[]"
| `Ref (`Full, label, _)  ->
    C.byte c '['; C.inline c (Inline.Link.text l); C.byte c ']';
    C.byte c '['; link_label_lines c (Label.text label); C.byte c ']');
  attributes ~inline:true c attrs

let attrs_span c span =
  let content = Inline.Attributes_span.content span
  and (attrs, _) = Inline.Attributes_span.attrs span in
  if not (include_attributes c) then C.inline c content else begin
    C.byte c '['; C.inline c content; C.byte c ']';
    attributes ~inline:true c attrs
  end

let inlines c is = List.iter (C.inline c) is
let image c l attrs = C.byte c '!'; link c l attrs
let raw_html c h = tight_block_lines c h
let text c t attrs =
  escaped_text c t;
  attributes ~inline:true c attrs

let strikethrough c s attrs =
  let i = Inline.Strikethrough.inline s in
  C.string c "~~"; C.inline c i; C.string c "~~";
  attributes ~inline:true c attrs

let math_span c ms attrs =
  let sep = if Inline.Math_span.display ms then "$$" else "$" in
  C.string c sep;
  tight_block_lines c (Inline.Math_span.tex_layout ms);
  C.string c sep;
  attributes ~inline:true c attrs

let inline c = function
| Inline.Autolink ((a, (attrs, _)), _) -> autolink c a attrs; true
| Inline.Break (b, _) -> break c b; true
| Inline.Code_span ((cs, (attrs, _)), _) -> code_span c cs attrs; true
| Inline.Emphasis ((e, (attrs, _)), _) -> emphasis c e attrs; true
| Inline.Image ((i, (attrs, _)), _) -> image c i attrs; true
| Inline.Inlines (is, _) -> inlines c is; true
| Inline.Link ((l, (attrs, _)), _) -> link c l attrs; true
| Inline.Raw_html (html, _) -> raw_html c html; true
| Inline.Strong_emphasis ((e, (attrs, _)), _) -> strong_emphasis c e attrs; true
| Inline.Text ((t, (attrs, _)), _) -> text c t attrs; true
| Inline.Ext_strikethrough ((s, (attrs, _)), _) -> strikethrough c s attrs; true
| Inline.Ext_math_span ((m, (attrs, _)), _) -> math_span c m attrs; true
| Inline.Ext_attrs (span, _) -> attrs_span c span; true
| _ -> C.string c "<!-- Unknown Cmarkit inline -->"; true

(* Block rendering *)

let blank_line c l = newline c; indent c; C.string c l

let block_quote c bq attrs =
  attributes c attrs;
  push_indent c (`Q (Block.Block_quote.indent bq));
  C.block c (Block.Block_quote.block bq); pop_indent c

let code_block c cb attrs =
  attributes c attrs;
 match Block.Code_block.layout cb with
| `Indented ->
    newline c; push_indent c (`I 4); indent c;
    block_lines c (Block.Code_block.code cb);
    pop_indent c
| `Fenced f ->
    let opening, closing = match fst f.opening_fence with
    | "" ->
        let char, len = Block.Code_block.make_fence cb in
        let f = String.make len char in
        f, Some f
    | opening -> opening, Option.map fst f.closing_fence
    in
    let info_string = Block.Code_block.info_string cb in
    let code = Block.Code_block.code cb in
    newline c; push_indent c (`I f.indent); indent c;
    C.string c opening; string_node_option c info_string;
    if code <> [] then (newline c; indent c; block_lines c code);
    (match closing with
    | None -> () | Some close -> newline c; indent c; C.string c close);
    pop_indent c

let heading c h attrs =
  attributes c attrs;
  newline c; indent c;
  match (Block.Heading.layout h) with
  | `Atx { indent; after_opening; closing } ->
      let inline = Block.Heading.inline h in
      nchars c indent ' ';
      nchars c (Block.Heading.level h) '#';
      (if after_opening = "" && not (Cmarkit.Inline.is_empty inline)
       then C.byte c ' ' else C.string c after_opening);
      C.inline c inline;
      C.string c closing
  | `Setext l ->
      let u = match Block.Heading.level h with 1 -> '=' | 2 -> '-' | _ -> '-' in
      nchars c l.leading_indent ' ';
      C.inline c (Block.Heading.inline h);
      C.string c l.trailing_blanks;
      newline c; indent c;
      nchars c l.underline_indent ' ';
      nchars c (fst l.underline_count) u;
      C.string c l.underline_blanks

let html_block c h attrs =
  attributes c attrs; newline c; indent c; block_lines c h

let link_reference_definition c ld attrs =
  attributes c attrs;
  newline c; indent c; nchars c (Link_definition.layout ld).indent ' ';
  C.byte c '[';
  begin match Link_definition.label ld with
  | None -> ()
  | Some label -> escaped_tight_block_lines c esc_link_label (Label.text label)
  end;
  C.string c "]:";
  link_definition c ld

let unordered_item c marker (i, _) =
  let before = Block.List_item.before_marker i in
  let after = Block.List_item.after_marker i in
  let task = Option.map fst (Block.List_item.ext_task_marker i) in
  push_indent c (`L (before, marker, after, task));
  C.block c (Block.List_item.block i);
  pop_indent c

let ordered_item c sep num (i, _) =
  let before = Block.List_item.before_marker i in
  let marker = fst (Block.List_item.marker i) in
  let marker = if marker = "" then Int.to_string num ^ sep else marker in
  let after = Block.List_item.after_marker i in
  let task = Option.map fst (Block.List_item.ext_task_marker i) in
  push_indent c (`L (before, marker, after, task));
  C.block c (Block.List_item.block i);
  pop_indent c;
  num + 1

let list c l attrs =
  attributes c attrs;
match Block.List'.type' l with
| `Unordered marker ->
    let marker = match marker with '*' | '-' | '+' -> marker | _ -> '*' in
    let marker = String.make 1 marker in
    List.iter (unordered_item c marker) (Block.List'.items l)
| `Ordered (start, sep) ->
    let sep = if sep <> '.' && sep <> ')' then '.' else sep in
    let sep = String.make 1 sep in
    ignore (List.fold_left (ordered_item c sep) start (Block.List'.items l))

let paragraph c p attrs =
  attributes c attrs;
  newline c; indent c;
  nchars c (Block.Paragraph.leading_indent p) ' ';
  C.inline c (Block.Paragraph.inline p);
  C.string c (Block.Paragraph.trailing_blanks p)

let thematic_break c t attrs =
  attributes c attrs;
  let ind = Block.Thematic_break.indent t in
  let break = Block.Thematic_break.layout t in
  let break = if break = "" then "---" else break in
  newline c; indent c; nchars c ind ' '; C.string c break

let table c t attrs =
  attributes c attrs;
  let col c (i, (before, after)) =
    C.byte c '|'; C.string c before; C.inline c i; C.string c after
  in
  let sep c ((align, len), _) =
    C.byte c '|';
    match align with
    | None -> nchars c len '-'
    | Some `Left -> C.byte c ':'; nchars c len '-'
    | Some `Center -> C.byte c ':'; nchars c len '-'; C.byte c ':'
    | Some `Right -> nchars c len '-'; C.byte c ':'
  in
  let row c = function
  | (`Header cols, _), blanks | (`Data cols, _), blanks ->
      newline c; indent c;
      (if cols = [] then C.byte c '|' else List.iter (col c) cols);
      C.byte c '|'; C.string c blanks
  | (`Sep seps, _), blanks ->
      newline c; indent c;
      (if seps = [] then C.byte c '|' else List.iter (sep c) seps);
      C.byte c '|'; C.string c blanks
  in
  push_indent c (`I (Block.Table.indent t));
  List.iter (row c) (Block.Table.rows t);
  pop_indent c

let footnote c fn attrs =
  attributes c attrs;
  push_indent c (`Fn (Block.Footnote.indent fn, Block.Footnote.label fn));
  C.block c (Block.Footnote.block fn);
  pop_indent c

let standalone_attributes c attrs = attributes c attrs

let attribute_def c ad attrs =
  attributes c attrs;
  push_indent c (`Fn (Block.Attribute_definition.indent ad,
                      Block.Attribute_definition.label ad));
  let (attrs, _) = Block.Attribute_definition.attrs ad in
  standalone_attributes c attrs;
  pop_indent c

let block c = function
| Block.Blank_line (l, _) -> blank_line c l; true
| Block.Block_quote ((b, (attrs, _)), _) -> block_quote c b attrs; true
| Block.Blocks (bs, _) -> List.iter (C.block c) bs; true
| Block.Code_block ((cb, (attrs, _)), _) -> code_block c cb attrs; true
| Block.Heading ((h, (attrs, _)), _) -> heading c h attrs; true
| Block.Html_block ((h, (attrs, _)), _) -> html_block c h attrs; true
| Block.Link_reference_definition ((ld, (attrs, _)), _) ->
    link_reference_definition c ld attrs; true
| Block.List ((l, (attrs, _)), _) -> list c l attrs; true
| Block.Paragraph ((p, (attrs, _)), _) -> paragraph c p attrs; true
| Block.Thematic_break ((t, (attrs, _)), _) -> thematic_break c t attrs; true
| Block.Ext_math_block ((cb, (attrs, _)), _) -> code_block c cb attrs; true
| Block.Ext_table ((t, (attrs, _)), _) -> table c t attrs; true
| Block.Ext_footnote_definition ((t, (attrs, _)), _) -> footnote c t attrs; true
| Block.Ext_standalone_attributes (attrs, _) -> standalone_attributes c attrs; true
| Block.Ext_attribute_definition ((attr_def, (attrs, _)), _) -> attribute_def c attr_def attrs; true
| _ -> newline c; indent c; C.string c "<!-- Unknown Cmarkit block -->"; true

(* Document rendering *)

let doc c d = C.block c (Doc.block d); true

(* Renderer *)

let renderer ?(include_attributes = false) () =
  let init_context = init_context ~include_attributes in
  Cmarkit_renderer.make ~init_context ~inline ~block ~doc ()
let of_doc ?(include_attributes = false) d =
  Cmarkit_renderer.doc_to_string (renderer ~include_attributes ()) d
