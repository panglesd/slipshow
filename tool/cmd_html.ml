(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Std

let built_in_css = ref "" (* See at the end of the module *)

let buffer_add_docs ~accumulate_defs parse r b files =
  let empty_defs = Cmarkit.Label.Map.empty in
  let rec loop defs = function
  | [] -> ()
  | file :: files ->
      let md = Os.read_file file |> Result.to_failure in
      let doc = parse ~defs ~file md in
      let defs = if accumulate_defs then Cmarkit.Doc.defs doc else empty_defs in
      Cmarkit_renderer.buffer_add_doc r b doc;
      if files <> [] then Buffer.add_char b '\n';
      loop defs files
  in
  loop empty_defs files

let buffer_add_inline_css b css =
  Buffer.add_string b "\n  <style type=\"text/css\">\n";
  Buffer.add_string b css;
  Buffer.add_string b "\n  </style>"

let buffer_add_inline_css_option b = function
| None -> () | Some css -> buffer_add_inline_css b css

let buffer_add_css_href b href =
  Buffer.add_string b "\n  <link rel=\"stylesheet\" type=\"text/css\" href=\"";
  Cmarkit_html.buffer_add_pct_encoded_string b href;
  Buffer.add_string b "\">"

let buffer_add_inline_js b js =
  Buffer.add_string b "\n  <script>\n";
  Buffer.add_string b js;
  Buffer.add_string b "\n  </script>"

let buffer_add_js_href b href =
  Buffer.add_string b
    "\n  <script rel=\"text/javascript\" defer=\"defer\" src=\"";
  Cmarkit_html.buffer_add_pct_encoded_string b href;
  Buffer.add_string b "\"></script>"

let buffer_add_csss b csss = List.iter (buffer_add_css_href b) csss
let buffer_add_inline_csss b files =
  let add_file b file =
    let css = Os.read_file file |> Result.to_failure in
    buffer_add_inline_css b (String.trim css)
  in
  List.iter (add_file b) files

let buffer_add_jss b jss = List.iter (buffer_add_js_href b) jss
let buffer_add_inline_jss b files =
  let add_file b file =
    let js = Os.read_file file |> Result.to_failure in
    buffer_add_inline_js b (String.trim js)
  in
  List.iter (add_file b) files

let buffer_add_title = Cmarkit_html.buffer_add_html_escaped_string
let buffer_add_author b = function
| None -> () | Some a ->
    Buffer.add_string b "\n  <meta name=\"author\" content=\"";
    Cmarkit_html.buffer_add_html_escaped_string b a;
    Buffer.add_string b "\">"

let title_of_file f =
  if f = "-" then "Untitled" else
  String.capitalize_ascii (Filename.remove_extension (Filename.basename f))

let doc
    ~lang ~title ~author ~csss ~inline_csss ~keep_built_in_css ~jss ~inline_jss
    buffer_add_docs files
  =
  let title = match title with
  | Some t -> t | None -> title_of_file (List.hd files)
  in
  let built_in = match keep_built_in_css || (csss = [] && inline_csss = []) with
  | true -> Some !built_in_css
  | false -> None
  in
  Printf.kbprintf Buffer.contents (Buffer.create 2048)
{|<!DOCTYPE html>
<html lang="%s">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">%a
  <title>%a</title>%a%a%a%a%a
</head>
<body>
%a</body>
</html>|}
lang
buffer_add_author author
buffer_add_title title
buffer_add_inline_css_option built_in
buffer_add_csss csss
buffer_add_inline_csss inline_csss
buffer_add_jss jss
buffer_add_inline_jss inline_jss
buffer_add_docs files

let html
    files quiet accumulate_defs strict heading_auto_ids backend_blocks locs
    layout safe docu lang title author csss inline_csss keep_built_in_css jss
    inline_jss full_featured
  =
  let resolver = Label_resolver.v ~quiet in
  let safe = safe && not full_featured in
  let strict = strict && not full_featured in
  let heading_auto_ids = heading_auto_ids || full_featured in
  let docu = docu || full_featured in
  let jss =
    if not full_featured then jss else
    "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js" :: jss
  in
  let r = Cmarkit_html.renderer ~backend_blocks ~safe () in
  let parse ~defs ~file md =
    Cmarkit.Doc.of_string ~resolver ~defs ~heading_auto_ids ~layout ~locs
      ~file ~strict md
  in
  let buffer_add_docs = buffer_add_docs ~accumulate_defs parse r in
  try
    let s = match docu with
    | true ->
        doc ~lang ~title ~author ~csss ~inline_csss ~keep_built_in_css ~jss
          ~inline_jss buffer_add_docs files
    | false ->
        Printf.kbprintf Buffer.contents (Buffer.create 2048) "%a"
          buffer_add_docs files
    in
    print_string s; 0
  with
  | Failure err -> Log.err "%s" err; Exit.err_file

(* Command line interface *)

open Cmdliner

let author =
  let doc = "Document author when $(b,--doc) is used. Gets into a \
             $(b,meta) element." in
  Arg.(value & opt (some string) None & info ["a"; "author"] ~doc ~docv:"NAME")

let backend_blocks =
  let doc = "Code blocks with language $(b,=html) are included verbatim \
             in the output, if $(b,--unsafe) is also specified. Other code \
             blocks with language starting with $(b,=) are dropped."
  in
  Cli.backend_blocks ~doc

let csss =
  let doc = "Link CSS $(docv) in the document when $(b,--doc) is \
             used. If unspecified and no other $(b,--inline-css) is \
             specified, a basic stylesheet is written directly \
             in the document (use $(b,-k) to keep it even when \
             this option is specified). Repeatable."
  in
  Arg.(value & opt_all string [] & info ["css"] ~doc ~docv:"URL")

let full_featured =
  let doc = "Full-featured document. This is a synonym for options \
             $(b,--unsafe -e -c -h) and adds a JavaScript script from \
             a CDN to render math."
  in
  Arg.(value & flag & info ["f"; "full-featured"] ~doc)

let inline_csss =
  let doc = "Add the content of CSS file $(docv) to the document when \
             $(b,--doc) is used. If unspecified and no other \
             $(b,--css) is specified, a built-in stylesheet is written \
             directly in the document (use $(b,-k) to keep it even when \
             this option is specified). Repeatable (gets in separate \
             $(b,style) elements)."
  in
  Arg.(value & opt_all string [] & info ~doc ["inline-css"] ~docv:"FILE.css")

let keep_built_in_css =
  let doc = "Keep built-in CSS even if other CSS is specified via \
             $(b,--css) or $(b,--inline-css)."
  in
  Arg.(value & flag & info ["k"; "keep-built-in-css"] ~doc)

let jss =
  let doc = "Link JavaScript $(docv) in the document when $(b,--doc) \
             is used. Repeatable."
  in
  Arg.(value & opt_all string [] & info ~doc ["js"] ~docv:"URL")

let inline_jss =
  let doc = "Add the content of JavaScript file $(docv) to the document when \
             $(b,--doc) is used. Repeatable (gets in separate \
             $(b,script) elements)."
  in
  Arg.(value & opt_all string [] & info ~doc ["inline-js"] ~docv:"FILE.js")

let layout =
  let doc = "Keep layout information (has no effect on rendering)." in
  Arg.(value & flag & info ["layout"] ~doc)

let locs =
  let doc = "Keep source text locations (has no effect on rendering)." in
  Arg.(value & flag & info ["locs"] ~doc)

let v =
  let doc = "Render CommonMark to HTML" in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) outputs an HTML fragment or document on standard output.";
    `Pre "$(mname) $(tname) $(b,--unsafe -e -c -h README.md > README.html)";
    `P "With math rendering support:";
    `Pre "$(mname) $(tname) $(b,\\\\)"; `Noblank;
    `Pre "  $(b,--js) $(b,'https://cdn.jsdelivr.net/npm/\
          mathjax@3/es5/tex-svg.js') $(b,\\\\)";
    `Noblank;
    `Pre "  $(b,--unsafe -e -c -h README.md > README.html)";
    `P "The $(b,-f) option can be used instead of the previous invocation:";
    `Pre "$(mname) $(tname) $(b,-f README.md > README.html";
    `Blocks Cli.common_man; ]
  in
  Cmd.v (Cmd.info "html" ~doc ~man) @@
  Term.(const html $ Cli.files $ Cli.quiet $ Cli.accumulate_defs $ Cli.strict $
        Cli.heading_auto_ids $ backend_blocks $ locs $ layout $ Cli.safe $
        Cli.docu $ Cli.lang $ Cli.title $ author $ csss $ inline_csss $
        keep_built_in_css $ jss $ inline_jss $ full_featured)

(* Built-in CSS, defined that way to avoid source clutter *)

let () = built_in_css :=
{|    *, *::before, *::after { box-sizing: border-box }
    body { min-height: 100vh; min-height: 100svh; }
    body, h1, h2, h3, h4, p, figure, blockquote, dl, dd { margin: 0; }
    pre, input, button, textarea, select { font: inherit }

    :root
    {  font-size: 100%;
       /* font-synthesis: none; */
       -webkit-text-size-adjust: none;

      --font_headings: system-ui, sans-serif;
      --font_body: system-ui, sans-serif;
      --font_mono: monospace;

      --font_m: 1rem; --leading_m: 1.5rem;
      --font_s: 0.82rem;
      --font_l: 1.125rem; --leadig_l: 1.34rem;
      --font_xl: 1.5rem; --leading_xl: 1.8rem;
      --font_xxl: 2.5rem; --leading_xxl: 3rem;

      --font_mono_ratio:
        /* mono / body size, difficult to find a good cross-browser value */
           0.92;
      --leading_mono_m: calc(var(--leading_m) * var(--font_mono_ratio));

      --sp_xxs: calc(0.25 * var(--leading_m));
      --sp_xs: calc(0.5 * var(--leading_m));
      --sp_s: calc(0.75 * var(--leading_m));
      --sp_m: var(--leading_m);
      --sp_l: calc(1.125 * var(--leading_m));
      --sp_xl: calc(1.5 * var(--leading_m));
      --sp_xxl: calc(2.0 * var(--leading_m));

      --measure_m: 73ch;
      --page_inline_pad: var(--sp_m);
      --page_block_pad: var(--sp_xl);

      --blockquote_border: 2px solid #ACACAC;
      --rule_border: 1px solid #CACBCE;
      --heading_border: 1px solid #EAECEF;
      --table_cell_pad: 0.4em;
      --table_hover: #f5f5f5;
      --table_sep: #efefef;
      --table_cell_inline_pad: 0.625em;
      --table_cell_block_pad: 0.25em;

      --code_span_bg: #EFF1F3;
      --code_span_inline_pad: 0.35ch;
      --code_block_bg: #F6F8FA;
      --code_block_bleed: 0.8ch;
      --code_block_block_pad: 1ch;

      --a_fg: #0969DA;
      --a_fg_hover: #1882ff;
      --a_visited: #8E34A5;
      --target_color: #FFFF96;
    }

    body
    { font-family: var(--font_body); font-weight: 400;
      font-size: var(--font_m); line-height: var(--leading_m);
      max-inline-size: var(--measure_m);
      padding-block: var(--page_block_pad);
      padding-inline: var(--page_inline_pad);
      margin-inline: auto;
      background-color: white; color: black; }

    body > *:first-child { margin-block-start: 0 }
    body * + * { margin-block-start: var(--sp_xs) }

    /* Blocks */

    h1, h2, h3, h4, h5, h6
    { font-family: var(--font_headings); font-weight: 600}

    h1 { font-size: var(--font_xxl); line-height: var(--leading_xxl);
         margin-block-start: var(--sp_xl); }

    h3 + *, h4 + *, h5 + *, h6 + *
    { margin-block-start: var(--sp_xs); }

    h2 { font-size: var(--font_xl); line-height: var(--leading_xl);
         margin-block-start: var(--sp_m);
         padding-block-end: var(--sp_xxs);
         border-bottom: var(--heading_border); }

    h3 { font-size: var(--font_l); line-height: var(--leading_l);
         margin-block-start: var(--sp_m); }

    h4 { font-weight: 400; font-style: oblique; }

    ul, ol { padding-inline-start: 3ch; }
    li + li { margin-block-start: var(--sp_xxs); }

    li > .task { display: flex; margin:0; padding:0; align-items: baseline;
                 column-gap: var(--sp_xxs); }
    li > .task > input { padding:0; margin:0 }
    li > .task > div { margin:0; padding:0 }

    blockquote > blockquote { margin-inline: 0.25ch; }
    blockquote
    {  margin-inline: 2ch;
       padding-inline: 1ch;
       border-left: var(--blockquote_border) }

    hr + * { margin-block-start: calc(var(--sp_s) - 1px); }
    hr { border: 0; border-block-end: var(--rule_border);
         width: 10ch;
         margin-block-start: var(--sp_s); margin-inline: auto; }

    pre
    { line-height: var(--leading_mono_m);
      white-space: pre-wrap;
      overflow-wrap: break-word;
      background-color: var(--code_block_bg);
      padding-block: var(--code_block_block_pad);
      padding-inline: var(--code_block_bleed);
      margin-inline: calc(-1.0 * var(--code_block_bleed)) }

    pre code { padding-inline: 0; background-color: inherit }

    [role="region"] { overflow: auto }
    table { border-collapse: separate; border-spacing: 0; white-space: nowrap }
    tr:hover > td { background: var(--table_hover) }
    th, td, th.left, td.left { text-align: left }
    th.right, td.right { text-align: right }
    th.center, td.center { text-align: center }
    td, th { border: 0px solid var(--table_sep); border-block-end-width: 1px }
    tr:first-child td { border-block-start-width: 1px; } /* headerless */
    th { font-weight: 600 }
    th, td { padding-inline: var(--table_cell_inline_pad);
             padding-block: var(--table_cell_block_pad); }

    /* Inlines */

    code
    { font-family: var(--font_mono);
      font-size: calc(1em * var(--font_mono_ratio));
      background-color: var(--code_span_bg);
      padding-inline: var(--code_span_inline_pad);
      border-radius: 3px;
      white-space: break-spaces; }

    a:hover { color: var(--a_fg_hover) }
    a:hover:visited { color: var(--a_visited); }
    a { color: var(--a_fg);
        text-decoration: underline;
        text-decoration-thickness: 0.04em;
        text-decoration-skip-ink: all;
        text-underline-offset: 3px; }

    *:hover > a.anchor { visibility: visible; }
    body > *:hover:first-child > a.anchor { visibility: hidden }
    a.anchor:visited { color: var(--a_fg); }
    a.anchor:before { content: "#";  }
    a.anchor:hover { color: var(--a_fg_hover); }
    a.anchor
    { visibility: hidden; position: absolute;
      font-weight: 400; font-style: normal;
      font-size: 0.9em;
      margin-left: -2.5ch;
      padding-right: 1ch; padding-left: 1ch; /* To remain selectable */
      color: var(--a_fg_hover);
      text-decoration: none; }

    *:target
    { background-color: var(--target_color);
      box-shadow: 0 0 0 3px var(--target_color); }

    em { font-style: oblique }
    b, strong { font-weight: 600 }
    small { font-size: var(--font_s) }
    sub, sup { vertical-align: baseline;
               font-size: 0.75em;
               line-height: 0; position:relative }
    sub { bottom: -0.25em }
    sup { top: -0.5em }

    /* Footnotes */

    a.fn-label { text-decoration: none; }
    a:target.fn-label { box-shadow: none }

    [role="doc-endnotes"]
    { font-size: 87.5%;
      line-height: calc(0.875 * var(--leading_m));
      margin-block-start: var(--sp_m);
      border-block-start: var(--rule_border); }
    [role="doc-endnotes"] > ol > li * + * { margin-block-start: var(--sp_xxs) }
    [role="doc-endnotes"] > ol { padding-inline-start: 2ex; }
    [role="doc-endnotes"] a.fn-label { padding-right:0.5ex; }

    [role="doc-endnotes"] > ol > li:target
    { background-color: inherit; box-shadow: none }
    [role="doc-endnotes"] > ol > li:target::marker
    { font-weight:900; /* Can't set background */ }
|}
