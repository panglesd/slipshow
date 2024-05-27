(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

open Std
open Cmarkit

let strf = Printf.sprintf
let pf = Format.fprintf
let cut = Format.pp_print_cut
let indent ppf n = for i = 1 to n do Format.pp_print_space ppf () done
let loc kind ~indent:n ppf m =
  pf ppf "@[<v>@[%a%s:@]@,@[%a%a@]@]"
    indent n kind
    indent n Textloc.pp_ocaml (Meta.textloc m)

let block_line kind ~indent ppf (_, m) = loc kind ~indent ppf m
let tight_block_line kind ~indent ppf (_, (_, m)) = loc kind ~indent ppf m
let tight_block_lines kind ~indent ppf ls =
  Format.pp_print_list (tight_block_line kind ~indent) ppf ls

let label ~indent ppf l =
  tight_block_lines "Label" ~indent ppf (Label.text l)

let defined_label ~indent ppf l =
  tight_block_lines "Defined label" ~indent ppf (Label.text l)

let label_def ~indent ppf l =
  tight_block_lines "Label definition" ~indent ppf (Label.text l)

let link_definition ~indent ppf ld =
  let label ppf = function
  | None -> () | Some l -> cut ppf (); label ~indent ppf l
  in
  let defined_label ppf = function
  | None -> () | Some l -> cut ppf (); defined_label ~indent ppf l
  in
  let dest ppf = function
  | (* None -> () | Some *) (_, m) -> cut ppf (); loc "Destination" ~indent ppf m
  in
  let title ppf = function
  | None -> () | Some ls -> cut ppf (); tight_block_lines "Title" ~indent ppf ls
  in
  pf ppf "%a%a%a%a"
    label (Link_definition.label ld)
    defined_label (Link_definition.defined_label ld)
    dest (Link_definition.dest ld)
    title (Link_definition.title ld)

let link_reference ~indent:n ppf = function
| `Ref (_, l, ref) ->
    label ~indent:n ppf l; cut ppf (); label_def ~indent:n ppf ref
| `Inline ((ld, _), m) ->
    pf ppf "%a%a" (loc "Inline" ~indent:n) m (link_definition ~indent:n) ld

let rec inlines ~indent ppf = function
| [] -> () | is -> cut ppf (); Format.pp_print_list (inline ~indent) ppf is

and link kind ~indent:n ppf ((l, _), m) =
  pf ppf "@[<v>%a@,%a@,%a@]"
    (loc kind ~indent:n) m
    (inline ~indent:(n + 2)) (Inline.Link.text l)
    (link_reference ~indent:(n + 2)) (Inline.Link.reference l)

and inline ~indent:n ppf = function
| Inline.Autolink (a, m) ->
    let is_email = Inline.Autolink.is_email a in
    let link = Inline.Autolink.link a in
    let autolink = strf "Autolink (email:%b)" is_email in
    pf ppf "@[<v>%a@,%a@]"
      (loc autolink ~indent:n) m (loc "Link" ~indent:(n + 2)) (snd link)
| Inline.Break (b, m) ->
    let label = match Inline.Break.type' b with
    | `Hard -> "Hard break" | `Soft -> "Soft break"
    in
    let layout_before = Inline.Break.layout_before b in
    let layout_after = Inline.Break.layout_after b in
    pf ppf "@[<v>%a@,%a@,%a@]"
      (loc label ~indent:n) m
      (loc "Layout before" ~indent:(n + 2)) (snd layout_before)
      (loc "Layout after" ~indent:(n + 2)) (snd layout_after)
| Inline.Code_span (c, m) ->
    let line = tight_block_line "Code span line" ~indent:(n + 2) in
    pf ppf "@[<v>%a@,%a@]"
      (loc "Code span" ~indent:n) m
      (Format.pp_print_list line) (Inline.Code_span.code_layout c)
| Inline.Emphasis (e, m) ->
    let i = Inline.Emphasis.inline e in
      pf ppf "@[<v>%a@,%a@]"
        (loc "Emphasis" ~indent:n) m (inline ~indent:(n + 2)) i
| Inline.Image (i, m) ->
    link "Image" ~indent:n ppf ((i, Attributes.empty), m)
| Inline.Inlines (is, m) ->
    pf ppf "@[<v>%a%a@]"
      (loc "Inlines" ~indent:n) m (inlines ~indent:(n + 2)) is
| Inline.Link (l, m) ->
      link "Link" ~indent:n ppf ((l, Attributes.empty), m)
| Inline.Raw_html (r, m) ->
    let line = tight_block_line "Raw HTML line" ~indent:(n + 2) in
    pf ppf "@[<v>%a@,%a@]"
      (loc "Raw HTML" ~indent:n) m (Format.pp_print_list line) r
| Inline.Strong_emphasis (e, m) ->
    let i = Inline.Emphasis.inline e in
    pf ppf "@[<v>%a@,%a@]"
      (loc "Strong emphasis" ~indent:n) m (inline ~indent:(n + 2)) i
| Inline.Text (t, m) ->
    loc "Text" ~indent:n ppf m
| Inline.Ext_strikethrough (s, m) ->
    let i = Inline.Strikethrough.inline s in
    pf ppf "@[<v>%a@,%a@]"
      (loc "Strikethrough" ~indent:n) m (inline ~indent:(n + 2)) i
| Inline.Ext_attrs (s, m) ->
    let i = Inline.Attributes_span.content s in
    pf ppf "@[<v>%a@,%a@]"
      (loc "Attributes" ~indent:n) m (inline ~indent:(n + 2)) i
| Inline.Ext_math_span (ms, m) ->
    let display = Inline.Math_span.display ms in
    let line = tight_block_line "Math span line" ~indent:(n + 2) in
    pf ppf "@[<v>%a@,%a@]"
      (loc (if display then "Math display span" else "Math span") ~indent:n) m
      (Format.pp_print_list line) (Inline.Math_span.tex_layout ms)
| _ ->
    indent ppf n; Format.pp_print_string ppf "Unknown Cmarkit inline"

let code_block ~indent:n label cb m ppf =
  let line ppf (_, m) = loc "Code line" ~indent:(n + 2) ppf m in
  let lines ppf = function
  | [] -> () | ls -> cut ppf (); Format.pp_print_list line ppf ls
  in
  let info_string ppf = function
  | None -> () | Some (_, m) ->
      cut ppf (); loc "Info string" ~indent:(n + 2) ppf m
  in
  let opening_fence ppf cb = match Block.Code_block.layout cb with
  | `Indented -> () | `Fenced f ->
      cut ppf ();
      loc "Opening fence" ~indent:(n + 2) ppf (snd f.opening_fence)
  in
  let closing_fence ppf cb = match Block.Code_block.layout cb with
  | `Indented -> () | `Fenced f ->
      match f.closing_fence with
      | None -> () | Some (_, m) ->
          cut ppf (); loc "Closing fence" ~indent:(n + 2) ppf m
  in
  pf ppf "@[<v>%a%a%a%a%a@]"
    (loc label ~indent:n) m
    opening_fence cb
    info_string (Block.Code_block.info_string cb)
    lines (Block.Code_block.code cb)
    closing_fence cb

let rec blocks ~indent ppf = function
| [] -> () | bs -> cut ppf (); Format.pp_print_list (block ~indent) ppf bs

and block ~indent:n ppf = function
| Block.Blank_line (_, m) ->
      loc "Blank line" ~indent:n ppf m
| Block.Block_quote ((bq, _), m) ->
    let b = Block.Block_quote.block bq in
    pf ppf "@[<v>%a@,%a@]"
        (loc "Block quote" ~indent:n) m (block ~indent:(n + 2)) b
| Block.Blocks (bs, m) ->
    pf ppf "@[<v>%a%a@]"
      (loc "Blocks" ~indent:n) m (blocks ~indent:(n + 2)) bs
| Block.Code_block ((cb, _), m) ->
    code_block ~indent:n "Code block" cb m ppf
| Block.Heading ((h, _), m) ->
    let level = Block.Heading.level h in
    let heading = "Heading, level " ^ Int.to_string level in
    let setext_underline ppf h = match Block.Heading.layout h with
    | `Atx _ -> () | `Setext st ->
        cut ppf ();
        loc "Setext underline" ~indent:(n + 2) ppf (snd st.underline_count)
    in
    let i = Block.Heading.inline h in
    pf ppf "@[<v>%a@,%a%a@]"
      (loc heading ~indent:n) m (inline ~indent:(n + 2)) i
      setext_underline h
| Block.Html_block ((lines, _), m) ->
    pf ppf "@[<v>%a@,%a@]"
      (loc "HTML block" ~indent:n) m
      (Format.pp_print_list (block_line "HTML line" ~indent:(n + 2))) lines
| Block.Link_reference_definition (((ld : Link_definition.t), _), m) ->
    pf ppf "@[<v>%a%a@]"
      (loc "Link reference definition" ~indent:n) m
      (link_definition ~indent:(n + 2)) ld
| Block.List ((l, _), m) ->
    let task_marker ppf i = match Block.List_item.ext_task_marker i with
    | None -> ()
    | Some (_, m) ->
        cut ppf (); (loc ~indent:(n + 4) "Task marker") ppf m
    in
    let list_item ppf (i, m) =
      pf ppf "@[<v>%a@,%a%a@,%a@]"
        (loc ~indent:(n + 2) "List item") m
        (loc ~indent:(n + 4) "List marker") (snd (Block.List_item.marker i))
        task_marker i
        (block ~indent:(n + 4)) (Block.List_item.block i)
    in
    let list = strf "List (tight:%b)" (Block.List'.tight l) in
    let items = Block.List'.items l in
    pf ppf "@[<v>%a@,%a@]"
      (loc list ~indent:n) m (Format.pp_print_list list_item) items
| Block.Paragraph ((p, _), m) ->
    pf ppf "@[<v>%a@,%a@]"
      (loc "Paragraph" ~indent:n) m
      (inline ~indent:(n + 2)) (Block.Paragraph.inline p)
| Block.Thematic_break (_, m) ->
    loc "Thematic break" ~indent:n ppf m
| Block.Ext_math_block ((cb, _), m) ->
    code_block ~indent:n "Math block" cb m ppf
| Block.Ext_table ((t, _), m) ->
    let col ~indent:n ppf (i, _) = inline ~indent:n ppf i in
    let row ~indent:n ppf = function
    | (`Header is, m), _  ->
        pf ppf "@[<v>%a@,%a@]"
          (loc "Header row" ~indent:n) m
          (Format.pp_print_list (col ~indent:(n + 2))) is
    | (`Data is, m), _ ->
        pf ppf "@[<v>%a@,%a@]"
          (loc "Data row" ~indent:n) m
          (Format.pp_print_list (col ~indent:(n + 2))) is
    | (`Sep seps, m), _ ->
        pf ppf "@[<v>%a@,%a@]"
          (loc "Separator line" ~indent:n) m
          (Format.pp_print_list (loc "Separator" ~indent:(n + 2)))
          (List.map snd seps)
    in
    pf ppf "@[<v>%a@,%a@]"
      (loc ~indent:n "Table") m
      (Format.pp_print_list (row ~indent:(n + 2))) (Block.Table.rows t)
| Block.Ext_footnote_definition ((fn, _), m) ->
    let b = Block.Footnote.block fn in
    let l = Block.Footnote.label fn in
    pf ppf "@[<v>%a@,%a@,%a@]"
      (loc "Footnote definition" ~indent:n) m
      (label ~indent:(n + 2)) l (block ~indent:(n + 2)) b
| Block.Ext_standalone_attributes (attrs, m) ->
    pf ppf "@[<v>%a@]"
      (loc "Standalone attributes" ~indent:n) m
| _ ->
    indent ppf n; Format.pp_print_string ppf "Unknown Cmarkit block"

let doc_locs ppf doc = block ~indent:0 ppf (Doc.block doc)

let locs files strict no_layout =
  let locs ~file contents =
    let locs = true and layout = not no_layout in
    let doc = Cmarkit.Doc.of_string ~file ~locs ~layout ~strict contents in
    doc_locs Format.std_formatter doc
  in
  Std.process_files locs files

(* Command line interface *)

open Cmdliner

let v =
  let doc = "Show CommonMark parse locations" in
  let exits = Exit.exits in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) outputs CommonMark parse locations.";
    `Blocks Cli.common_man; ]
  in
  Cmd.v (Cmd.info "locs" ~doc ~exits ~man) @@
  Term.(const locs $ Cli.files $ Cli.strict $ Cli.no_layout)

(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
