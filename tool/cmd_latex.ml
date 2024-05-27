(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

open Std
open Cmarkit

let built_in_preamble = ref "" (* See at the end of the module *)

let buffer_add_inline_preamble b p =
  Buffer.add_char b '\n'; Buffer.add_string b p; Buffer.add_char b '\n'

let buffer_add_inline_preamble_option b = function
| None -> () | Some p -> buffer_add_inline_preamble b p

let buffer_add_inline_preambles b files =
  let add_file b file =
    let preamble = Os.read_file file |> Result.to_failure in
    buffer_add_inline_preamble b (String.trim preamble)
  in
  List.iter (add_file b) files

let text_inline t = Inline.Text (t, Meta.none)
let untilted_inline = text_inline "Untilted"

let lift_headings_map ~extract_title doc =
  let open Cmarkit in
  let title = ref None in
  let block m = function
  | Block.Heading ((h, _), meta) as b ->
      let inline = Block.Heading.inline h in
      if extract_title && Option.is_none !title
      then (title := Some inline; Mapper.delete) else
      let level = Block.Heading.level h in
      if level = 1 then Mapper.ret b else
      let id = Block.Heading.id h in
      let level = level - 1 in
      let h = Block.Heading.make ?id ~level inline in
      Mapper.ret (Block.Heading ((h, (Attributes.empty, Meta.none)), meta))
  | _ -> Mapper.default
  in
  let doc = Mapper.map_doc (Mapper.make ~block ()) doc in
  let title = Option.value ~default:untilted_inline !title in
  title, doc

let empty_defs = Cmarkit.Label.Map.empty
let buffer_add_docs ?(defs = empty_defs) ~accumulate_defs parse r b files =
  let rec loop defs = function
  | [] -> ()
  | file :: files ->
      let md = Os.read_file file |> Result.to_failure in
      let _, doc = parse ~extract_title:false ~file ~defs md in
      let defs = if accumulate_defs then Cmarkit.Doc.defs doc else empty_defs in
      Cmarkit_renderer.buffer_add_doc r b doc;
      if files <> [] then Buffer.add_char b '\n';
      loop defs files
  in
  loop defs files

let buffer_add_title r doc b title =
  let ctx = Cmarkit_renderer.Context.make r b in
  let () = Cmarkit_renderer.Context.init ctx doc in
  Cmarkit_renderer.Context.inline ctx title

let buffer_add_author b = function
| None -> () | Some a ->
    Buffer.add_string b "\n\\author{";
    Buffer.add_string b a; Buffer.add_char b '}'

let title_of_file f =
  if f = "-" then "Untitled" else
  String.capitalize_ascii (Filename.remove_extension (Filename.basename f))

let doc
    ~accumulate_defs ~extract_title parse r ~author ~title ~inline_preambles
    ~keep_built_in_preambles files
  =
  let built_in_preamble =
    if inline_preambles = [] || keep_built_in_preambles
    then Some (!built_in_preamble) else None
  in
  let file, files = List.hd files, List.tl files in
  let md = Os.read_file file |> Result.to_failure in
  let title, doc =
    let defs = empty_defs in
    match title with
    | Some t -> text_inline t, snd (parse ~extract_title:false ~file ~defs md)
    | None ->
        if extract_title then parse ~extract_title:true ~file ~defs md else
        let title = text_inline (title_of_file file) in
        (title, snd (parse ~extract_title:false ~file ~defs md))
  in
  let defs = if accumulate_defs then Cmarkit.Doc.defs doc else empty_defs in
  Printf.kbprintf Buffer.contents (Buffer.create 1024)
{|\documentclass{article}
%a%a
%a\title{%a}
\begin{document}
\maketitle
%a%a%a
\end{document}
|}
buffer_add_inline_preamble_option built_in_preamble
buffer_add_inline_preambles inline_preambles
buffer_add_author author
(buffer_add_title r doc) title
(Cmarkit_renderer.buffer_add_doc r) doc
Buffer.add_string (if files <> [] then "\n" else "")
(buffer_add_docs ~defs ~accumulate_defs parse r) files

let latex
    files quiet accumulate_defs strict heading_auto_ids backend_blocks
    lift_headings docu title author inline_preambles keep_built_in_preambles
  =
  let resolver = Label_resolver.v ~quiet in
  let r = Cmarkit_latex.renderer ~backend_blocks () in
  let parse ~extract_title ~file ~defs md =
    let doc =
      Cmarkit.Doc.of_string ~resolver ~defs ~heading_auto_ids ~file ~strict md
    in
    if lift_headings then lift_headings_map ~extract_title doc else
    untilted_inline, doc
  in
  try
    let s = match docu with
    | true ->
        doc ~accumulate_defs ~extract_title:lift_headings parse
          ~author ~title ~inline_preambles ~keep_built_in_preambles r files
    | false ->
        Printf.kbprintf Buffer.contents (Buffer.create 2048) "%a"
          (buffer_add_docs ~accumulate_defs parse r) files;
    in
    print_string s; 0
  with
  | Failure err -> Log.err "%s" err; Exit.err_file

(* Command line interface *)

open Cmdliner

let author =
  let doc = "Document author when $(b,--doc) is used. $(docv) is interpreted \
             as raw LaTeX."
  in
  Arg.(value & opt (some string) None & info ["a"; "author"] ~doc ~docv:"NAME")

let backend_blocks =
  let doc = "Code blocks with language $(b,=latex) are included verbatim \
             in the output. Other code blocks with language starting \
             with $(b,=) are dropped. This does not activate math support, \
             use $(b,--exts) for that."
  in
  Cli.backend_blocks ~doc

let inline_preambles =
  let doc = "Add the content of LaTeX file $(docv) to the document preamble \
             when $(b,--doc) is used. If unspecified a built-in preamble is \
             written directly in the document (use $(b,-k) to keep it even \
             when this option is specified). Repeatable."
  in
  Arg.(value & opt_all string [] &
       info ~doc ["inline-preamble"] ~docv:"FILE.latex")

let keep_built_in_preamble =
  let doc = "Keep built-in preamble even if one is specified via \
             $(b,--inline-preamble)."
  in
  Arg.(value & flag & info ["k"; "keep-built-in-preamble"] ~doc)

let lift_headings =
  let doc = "Lift headings one level up and, when $(b,--doc) is used, \
             extract the first heading (of any level) to take it as the \
             title; unless a title is specified via the $(b,--title) option. \
             This is useful for certain CommonMark documents like READMEs \
             for which taking the headings literally results in unnatural \
             sectioning."
  in
  Arg.(value & flag & info ["l"; "lift-headings"] ~doc)

let v =
  let doc = "Render CommonMark to LaTeX" in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) outputs a LaTeX fragment or document on standard output.";
    `Pre "$(mname) $(tname) $(b,-e -c -l -h README.md > README.latex)";`Noblank;
    `Pre "$(b,tlmgr install enumitem listings hyperref ulem bera fontspec)";
    `Noblank;
    `Pre "$(b,xelatex README.latex)";
    `Blocks Cli.common_man ]
  in
  Cmd.v (Cmd.info "latex" ~doc ~man) @@
  Term.(const latex $ Cli.files $ Cli.quiet $ Cli.accumulate_defs $ Cli.strict $
        Cli.heading_auto_ids $ backend_blocks $ lift_headings $
        Cli.docu $ Cli.title $ author $ inline_preambles $
        keep_built_in_preamble)

(* Built-in LaTeX preamable, defined that way to avoid source clutter *)

let () = built_in_preamble :=
{|\usepackage{graphicx}
\usepackage{enumitem}
\usepackage{listings}
\usepackage{hyperref}
\usepackage[normalem]{ulem}
\usepackage[scaled=0.8]{beramono}
\usepackage{fontspec}

\lstset{
  columns=[c]fixed,
  basicstyle=\small\ttfamily,
  keywordstyle=\bfseries,
  upquote=true,
  commentstyle=\slshape,
  breaklines=true,
  showstringspaces=false}

\lstdefinelanguage{ocaml}{language=[objective]caml,
  literate={'"'}{\textquotesingle "\textquotesingle}3
            {'\\"'}{\textquotesingle \textbackslash"\textquotesingle}4,
}

\renewcommand{\arraystretch}{1.3}
|}


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
