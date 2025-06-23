(*---------------------------------------------------------------------------
   Copyright (c) 2021 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Cmarkit
module C = Cmarkit_renderer.Context
module String_set = Set.Make (String)

(* State *)

type heading_level =
| Part
| Chapter
| Section
| Subsection

type state =
  { backend_blocks : bool;
    first_heading_level : heading_level;
    mutable sot : bool; (* start of text *)
    mutable labels : String_set.t;
    mutable footnote_labels : string Label.Map.t; }

let state : state C.State.t = C.State.make ()
let get_state c = C.State.get c state
let backend_blocks c = (get_state c).backend_blocks
let first_heading_level c = (get_state c).first_heading_level
let init_context
    ?(backend_blocks = false) ?(first_heading_level = Section) c _
  =
  let labels = String_set.empty and footnote_labels = Label.Map.empty in
  let st =
    { backend_blocks; first_heading_level; sot = true; labels; footnote_labels }
  in
  C.State.set c state (Some st)

let unique_label c l =
  let st = C.State.get c state in
  let rec loop labels l c =
    let l' = if c = 0 then l else (String.concat "-" [l; Int.to_string c]) in
    match String_set.mem l' labels with
    | true -> loop labels l (c + 1)
    | false -> st.labels <- String_set.add l' labels; l'
  in
  loop st.labels l 0

let make_label l = (* latex seems to choke on these underscores in labels *)
  String.map (function '_' | ' ' | '\t' -> '-' | c -> c) l

let footnote_label c id =
  let st = get_state c in
  match Label.Map.find_opt id st.footnote_labels with
  | Some l -> l, false
  | None ->
      let l = make_label (String.sub id 1 (String.length id - 1)) in
      let l = "fn-" ^ l in
      st.footnote_labels <- Label.Map.add id l st.footnote_labels;
      l, true

(* Escaping *)

let buffer_add_latex_escaped_uchar b u = match Uchar.to_int u with
| 0x0000 -> Buffer.add_utf_8_uchar b Uchar.rep
| 0x0023 (* # *) -> Buffer.add_string b {|\#|}
| 0x0024 (* $ *) -> Buffer.add_string b {|\$|}
| 0x0025 (* % *) -> Buffer.add_string b {|\%|}
| 0x0026 (* & *) -> Buffer.add_string b {|\&|}
| 0x005C (* \ *) -> Buffer.add_string b {|\textbackslash{}|}
| 0x005E (* ^ *) -> Buffer.add_string b {|\textasciicircum{}|}
| 0x005F (* _ *) -> Buffer.add_string b {|\_|}
| 0x007B (* { *) -> Buffer.add_string b {|\{|}
| 0x007D (* } *) -> Buffer.add_string b {|\}|}
| 0x007E (* ~ *) -> Buffer.add_string b {|\textasciitilde{}|}
| _ -> Buffer.add_utf_8_uchar b u

let latex_escaped_uchar c u = buffer_add_latex_escaped_uchar (C.buffer c) u

let buffer_add_latex_escaped_string b s =
  let string = Buffer.add_string in
  let flush b max start i =
    if start <= max then Buffer.add_substring b s start (i - start);
  in
  let rec loop b s max start i =
    if i > max then flush b max start i else
    let next = i + 1 in
    match String.get s i with
    | '\x00' ->
        flush b max start i; Buffer.add_utf_8_uchar b Uchar.rep;
        loop b s max next next
    | '#' -> flush b max start i; string b {|\#|}; loop b s max next next
    | '$' -> flush b max start i; string b {|\$|}; loop b s max next next
    | '%' -> flush b max start i; string b {|\%|}; loop b s max next next
    | '&' -> flush b max start i; string b {|\&|}; loop b s max next next
    | '\\' ->
        flush b max start i; string b {|\textbackslash{}|};
        loop b s max next next
    | '^' ->
        flush b max start i; string b {|\textasciicircum{}|};
        loop b s max next next
    | '_' -> flush b max start i; string b {|\_|}; loop b s max next next
    | '{' -> flush b max start i; string b {|\{|}; loop b s max next next
    | '}' -> flush b max start i; string b {|\}|}; loop b s max next next
    | '~' ->
        flush b max start i; string b {|\textasciitilde{}|};
        loop b s max next next
    | c -> loop b s max start next
  in
  loop b s (String.length s - 1) 0 0

let latex_escaped_string c s = buffer_add_latex_escaped_string (C.buffer c) s

(* Rendering functions *)

let newline c =
  (* Block generally introduce newlines, except the first one. *)
  let st = get_state c in if st.sot then st.sot <- false else C.byte c '\n'

let comment c s = C.string c "% "; latex_escaped_string c s; newline c

let comment_undefined_label c l = match Inline.Link.referenced_label l with
| None -> () | Some def -> comment c ("Undefined label " ^ (Label.key def))

let comment_unknown_def_type c l = match Inline.Link.referenced_label l with
| None -> () | Some def ->
    comment c ("Unknown label definition type for " ^ (Label.key def))

let comment_foonote_image c l = match Inline.Link.referenced_label l with
| None -> () | Some def ->
    comment c ("Footnote " ^ (Label.key def) ^ " referenced as image")

let block_lines c = function (* newlines only between lines *)
| [] -> () | l :: ls ->
    let line c l = newline c; C.string c (Block_line.to_string l) in
    C.string c (Block_line.to_string l); List.iter (line c) ls

let tight_block_lines c = function (* newlines only between lines *)
| [] -> () | l :: ls ->
    let line c l = newline c; C.string c (Block_line.tight_to_string l) in
    C.string c (Block_line.tight_to_string l); List.iter (line c) ls

(* Inline rendering *)

let autolink c a =
  let pre = if Inline.Autolink.is_email a then "mailto:" else "" in
  let link = pre ^ (fst (Inline.Autolink.link a)) in
  C.string c "\\url{"; latex_escaped_string c link; C.byte c '}'

let code_span c cs =
  let code = Inline.Code_span.code cs in
  C.string c "\\texttt{"; latex_escaped_string c code; C.byte c '}'

let emphasis c e =
  C.string c "\\emph{"; C.inline c (Inline.Emphasis.inline e); C.byte c '}'

let link c l = match Inline.Link.reference_definition (C.get_defs c) l with
| Some (Link_definition.Def ((ld, _), _)) ->
    let d = match Link_definition.dest ld with (* None -> "" | Some *) (u, _) -> u in
    let dlen = String.length d in
    begin match dlen > 0 && d.[0] = '#' with
    | true ->
        let label = make_label (String.sub d 1 (dlen - 1)) in
        C.string c "\\hyperref[";
        latex_escaped_string c label;
        C.string c "]{";
        C.inline c (Inline.Link.text l); C.byte c '}'
    | false ->
        C.string c "\\href{";
        latex_escaped_string c d;
        C.string c "}{";
        C.inline c (Inline.Link.text l); C.byte c '}'
    end
| Some (Block.Footnote.Def ((fn, _), _)) ->
    let key = Label.key (Option.get (Inline.Link.referenced_label l)) in
    let l, new' = footnote_label c key in
    begin match new' with
    | false ->
        C.string c "\\textsuperscript{\\ref{"; C.string c l; C.string c "}}"
    | true ->
        C.string c "\\footnote{\\label{"; C.string c l; C.string c "}";
        C.block c (Block.Footnote.block fn);
        C.string c "}"
    end
| None -> C.inline c (Inline.Link.text l); comment_undefined_label c l
| Some _ -> C.inline c (Inline.Link.text l); comment_unknown_def_type c l

let image c i = match Inline.Link.reference_definition (C.get_defs c) i with
| Some (Link_definition.Def ((ld, _), _)) ->
    let d = match Link_definition.dest ld with
    (* | None -> "" | Some *) (u, _) -> u
    in
    let is_external d =
      String.starts_with ~prefix:"http:" d ||
      String.starts_with ~prefix:"https:" d
    in
    if is_external d then link c i else
    begin
      C.string c "\\protect\\includegraphics{";
      latex_escaped_string c d;
      C.byte c '}'
    end
| Some (Block.Footnote.Def _) -> comment_foonote_image c i
| None -> comment_undefined_label c i
| Some _ -> comment_unknown_def_type c i

let strong_emphasis c e =
  C.string c "\\textbf{"; C.inline c (Inline.Emphasis.inline e); C.byte c '}'

let break c b = match Inline.Break.type' b with
| `Hard -> C.string c "\\\\"; newline c
| `Soft -> newline c

let text c t = latex_escaped_string c t

let strikethrough c s =
  C.string c "\\sout{"; C.inline c (Inline.Strikethrough.inline s); C.byte c '}'

let math_span c ms =
  let tex = Inline.Math_span.tex_layout ms in
  C.string c (if Inline.Math_span.display ms then "\\[" else "\\(");
  tight_block_lines c tex;
  C.string c (if Inline.Math_span.display ms then "\\]" else "\\)")

let inline c = function
| Inline.Autolink ((a, _TODO), _) -> autolink c a; true
| Inline.Break (b, _) -> break c b; true
| Inline.Code_span ((cs, _TODO), _) -> code_span c cs; true
| Inline.Emphasis ((e, _TODO), _) -> emphasis c e; true
| Inline.Image ((i, _TODO), _) -> image c i; true
| Inline.Inlines (is, _) -> List.iter (C.inline c) is; true
| Inline.Link ((l, _TODO), _) -> link c l; true
| Inline.Raw_html (_, _) -> comment c "Raw CommonMark HTML omitted"; true
| Inline.Strong_emphasis ((e, _TODO), _) -> strong_emphasis c e; true
| Inline.Text ((t, _TODO), _) -> text c t; true
| Inline.Ext_strikethrough ((s, _TODO), _) -> strikethrough c s; true
| Inline.Ext_math_span ((ms, _TODO), _) -> math_span c ms; true
| Inline.Ext_attrs _ -> comment c "Attributes omitted"; true
| _ -> comment c "Unknown Cmarkit inline"; true

(* Block rendering *)

type heading =
  | Part
  | Chapter
  | Section
  | Subsection

let heading_of_string = function
  | "part" -> Some Part
  | "chapter" -> Some Chapter
  | "section" -> Some Section
  | "subsection" -> Some Subsection
  | _s -> None

let pp_heading fmt = function
  | Part -> Format.pp_print_string fmt "part"
  | Chapter -> Format.pp_print_string fmt "chapter"
  | Section -> Format.pp_print_string fmt "section"
  | Subsection -> Format.pp_print_string fmt "subsection"

let attributes c attrs =
  if Attributes.is_empty attrs then () else
  comment c "Attributes cannot be rendered in latex"

let block_quote c attrs bq =
  attributes c attrs;
  newline c;
  C.string c "\\begin{quote}";
  C.block c (Block.Block_quote.block bq);
  C.string c "\\end{quote}";
  newline c

let code_block c attrs cb =
  attributes c attrs;
  let info = Option.map fst (Block.Code_block.info_string cb) in
  let lang = Option.bind info Block.Code_block.language_of_info_string in
  let code = Block.Code_block.code cb in
  let raw_line (l, _) = C.string c l; newline c in
  let line = raw_line (* XXX: escape or not ? *) in
  match lang with
  | Some (lang, _env) when backend_blocks c && lang.[0] = '=' ->
      if lang = "=latex" then block_lines c code else ()
  | _ ->
      newline c;
      begin match lang with
      | None ->
          C.string c "\\begin{verbatim}"; newline c;
          List.iter line code;
          C.string c "\\end{verbatim}"
      | Some (lang, _env) ->
          C.string c "\\begin{lstlisting}[language=";
          C.string c lang; C.byte c ']'; newline c;
          List.iter line code;
          C.string c "\\end{lstlisting}"
      end;
      newline c

let heading c attrs h =
  attributes c attrs;
  let first = match first_heading_level c with
  | Part -> 0 | Chapter -> 1 | Section -> 2 | Subsection -> 3
  in
  let cmd = match first + Block.Heading.level h with
  | 1 -> "part{" | 2 -> "chapter{" | 3 -> "section{" | 4 -> "subsection{"
  | 5 -> "subsubsection{" | 6 -> "paragraph{" | 7 -> "subparagraph{"
  | 8 -> "subparagraph{" | _ -> "subparagraph{"
  in
  let i = Block.Heading.inline h in
  newline c;
  C.byte c '\\'; C.string c cmd; C.inline c i; C.byte c '}';
  begin match Block.Heading.id h with
  | None -> ()
  | Some (`Auto id | `Id id) ->
      let label = unique_label c (make_label id) in
      C.string c "\\label{"; latex_escaped_string c label; C.byte c '}'
  end;
  newline c

let list_item c (i, _meta) =
  C.string c "\\item{}";
  begin match Block.List_item.ext_task_marker i with
  | None -> ()
  | Some (u, _) -> (* Something better can likely be done *)
      C.string c " \\lbrack";
      begin match  Uchar.to_int u = 0x0020 with
      | true -> C.string c "\\phantom{x}"
      | false -> C.byte c ' '; C.utf_8_uchar c u
      end;
      C.string c "\\rbrack \\enspace"
  end;
  C.block c (Block.List_item.block i)

let list c attrs l =
 attributes c attrs;
 match Block.List'.type' l with
| `Unordered _ ->
    newline c;
    C.string c "\\begin{itemize}"; newline c;
    List.iter (list_item c) (Block.List'.items l);
    C.string c "\\end{itemize}";
    newline c
| `Ordered (start, _) ->
    newline c;
    C.string c "\\begin{enumerate}";
    if start <> 1
    then (C.string c "[start="; C.string c (Int.to_string start); C.byte c ']');
    newline c;
    List.iter (list_item c) (Block.List'.items l);
    C.string c "\\end{enumerate}";
    newline c

let html_block c attrs _ = attributes c attrs; newline c; comment c "CommonMark HTML block omitted"

let paragraph c attrs p =
  attributes c attrs; newline c; C.inline c (Block.Paragraph.inline p); newline c

let thematic_break c attrs =
  attributes c attrs;
  newline c;
  C.string c "\\begin{center}\\rule{0.5\\linewidth}{.25pt}\\end{center}";
  newline c

let math_block c attrs cb =
  attributes c attrs;
  let line l = C.string c (Block_line.to_string l); newline c in
  C.string c "\\["; newline c;
  List.iter line (Block.Code_block.code cb);
  C.string c "\\]"; newline c

let table c attrs t =
  attributes c attrs;
  let start c align op =
    begin match align with
    | None -> C.byte c '{';
    | Some `Left -> C.string c "\\multicolumn{1}{l}{"
    | Some `Center -> C.string c "\\multicolumn{1}{c}{"
    | Some `Right -> C.string c "\\multicolumn{1}{r}{"
    end;
    if op <> "" then C.string c op;
  in
  let close c = C.byte c '}'; newline c in
  let rec cols c op ~align count cs = match align, cs with
  | ((a, _) :: align), (col, _) :: cs ->
      start c (fst a) op; C.inline c col; close c;
      if count > 1 then (C.string c " &"; newline c);
      cols c op ~align (count - 1) cs
  | [], (col, _) :: cs ->
      start c None op; C.inline c col; close c;
      if count > 1 then (C.string c " &"; newline c);
      cols c op ~align:[] (count - 1) cs
  | (a :: align), [] ->
      if count > 1 then (C.string c "&"; newline c);
      cols c op ~align (count - 1) []
  | [], [] ->
      for i = count downto 2 do C.string c "&"; newline c done;
      C.string c "\\\\"; newline c
  in
  let header c count ~align cs = cols c "\\bfseries{}" ~align count cs in
  let data c count ~align cs = cols c "" ~align count cs in
  let rec rows c col_count ~align = function
  | ((`Header cols, _), _) :: rs ->
      let align, rs = match rs with
      | ((`Sep align, _), _) :: rs -> align, rs
      | _ -> align, rs
      in
      header c col_count ~align cols;
      C.string c "\\hline"; newline c;
      rows c col_count ~align rs
  | ((`Data cols, _), _) :: rs ->
      data c col_count ~align cols; rows c col_count ~align rs
  | ((`Sep align, _), _) :: rs -> rows c col_count ~align rs
  | [] -> ()
  in
  newline c; C.string c "\\bigskip"; newline c;
  C.string c "\\begin{tabular}{";
  for i = 1 to Block.Table.col_count t do C.byte c 'l' done;
  C.byte c '}'; newline c;
  begin match Block.Table.rows t with
  | (((`Data _ | `Sep _), _), _) :: _ -> C.string c "\\hline"; newline c
  | _ -> ()
  end;
  rows c (Block.Table.col_count t) ~align:[] (Block.Table.rows t);
  C.string c "\\hline"; newline c;
  C.string c "\\end{tabular}";
  newline c; C.string c "\\bigskip"; newline c

let block c = function
| Block.Block_quote ((bq, (attrs, _)), _) -> block_quote c attrs bq; true
| Block.Blocks (bs, _) -> List.iter (C.block c) bs; true
| Block.Code_block ((cb, (attrs, _)), _) -> code_block c attrs cb; true
| Block.Heading ((h, (attrs, _)), _) -> heading c attrs h; true
| Block.Html_block ((html, (attrs, _)), _) -> html_block c attrs html; true
| Block.List ((l, (attrs, _)), _) -> list c attrs l; true
| Block.Paragraph ((p, (attrs, _)), _) -> paragraph c attrs p; true
| Block.Thematic_break ((_, (attrs, _)), _) -> thematic_break c attrs; true
| Block.Ext_math_block ((cb, (attrs, _)), _)-> math_block c attrs cb; true
| Block.Ext_table ((t, (attrs, _)), _)-> table c attrs t; true
| Block.Blank_line _ -> true
| Block.Link_reference_definition _
| Block.Ext_footnote_definition _ -> true;
| Block.Ext_standalone_attributes _ -> comment c "Attributes cannot be rendered in latex"; true
| _ -> comment c "Unknown Cmarkit block"; true

(* Document rendering *)

let doc c d = C.block c (Doc.block d); true

(* Renderer *)

let renderer ?backend_blocks ?first_heading_level () =
  let init_context = init_context ?backend_blocks ?first_heading_level in
  Cmarkit_renderer.make ~init_context ~inline ~block ~doc ()

let of_doc ?backend_blocks ?first_heading_level d =
  Cmarkit_renderer.doc_to_string
    (renderer ?backend_blocks ?first_heading_level ()) d
