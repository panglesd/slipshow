module Asset = Asset
module Frontmatter = Frontmatter

type file_reader = Fpath.t -> (string option, [ `Msg of string ]) result

let math_option_elem math_mode ~has_math =
  let elem =
    if not has_math then ""
    else
      match math_mode with
      | `Katex ->
          {| window.Katex = {
          // customised options
          // • auto-render specific keys, e.g.:
          delimiters: [
              {left: '\\(', right: '\\)', display: false},
              {left: '\\[', right: '\\]', display: true}
          ],
          // • rendering keys, e.g.:
            throwOnError : false,
            strict: false,
            trust:true
        };
|}
      | `Mathjax ->
          {|window.MathJax = {
  loader: {load: ['[tex]/html']},
  tex: {packages: {'[+]': ['html']}}
};|}
  in
  "<script>" ^ elem ^ "</script>"

let mermaid_option_elem ~has_mermaid =
  let elem =
    if not has_mermaid then ""
    else
      {|window.Mermaid = { startOnLoad: false, deterministicIds : true, securityLevel: "loose" };|}
  in
  "<script>" ^ elem ^ "</script>"

let mathjax_element math_mode has_math math_link =
  if not has_math then ""
  else
    match math_link with
    | Some (Asset.Local { content = t; _ }) ->
        Format.sprintf "<script id=\"MathJax-script\">%s</script>" t
    | Some (Remote r) ->
        Format.sprintf "<script id=\"MathJax-script\" src=\"%s\"></script>" r
    | None -> (
        match math_mode with
        | `Katex ->
            String.concat ""
            @@ [
                 Format.sprintf "<script>%s</script>"
                   (Katex.read "katex.min.js" |> Option.get);
                 Format.sprintf "<style>%s</style>"
                   (Katex.read "standalone-style.min.css" |> Option.get);
                 Format.sprintf "<script>%s</script>"
                   (Katex.read "auto-render.min.js" |> Option.get);
                 {|  <script>
        renderMathInElement(document.body, window.Katex);
</script>
|};
               ]
        | `Mathjax ->
            Format.sprintf "<script id=\"MathJax-script\">%s</script>"
              Data_files.(read Mathjax_js))

let mermaid_element has_mermaid =
  if not has_mermaid then ""
  else
    String.concat ""
      [
        "<script id=\"mermaid-script\">";
        Mermaid.read "mermaid.min.js" |> Option.get;
        "</script>";
        "<script>mermaid.initialize(window.Mermaid)</script>";
      ]

let css_element = function
  | Asset.Local { content = t; _ } -> Format.sprintf "<style>%s</style>" t
  | Remote r -> Format.sprintf {|<link href="%s" rel="stylesheet" />|} r

let theme_css = function
  | `Builtin theme ->
      Format.sprintf "<style>%s</style>" (Themes.content ~lite:true theme)
  | `External asset -> css_element asset

let internal_css =
  Format.sprintf "<style>%s</style>" Data_files.(read Slip_internal_css)

let system_css =
  Format.sprintf "<style>%s</style>" Data_files.(read Slip_system_css)

let variable_css ~width ~height =
  Format.sprintf
    "<style>:root {  --page-width: %dpx;  --page-height: %dpx;}</style>" width
    height

let slipshow_js_element slipshow_link =
  match slipshow_link with
  | Some (Asset.Local { content = t; _ }) ->
      Format.sprintf "<script>%s</script>" t
  | Some (Remote r) -> Format.sprintf "<script src=\"%s\"></script>" r
  | None -> Format.sprintf "<script>%s</script>" Data_files.(read Slipshow_js)

let head ~width ~height ~theme ~highlightjs_theme ~(has : Has.t) ~math_mode
    ~css_links =
  let theme = theme_css theme in
  let highlight_css_element =
    let filename = "styles/" ^ highlightjs_theme ^ ".min.css" in
    "<style>" ^ (Option.get @@ Highlightjs.read filename) ^ "</style>"
  in
  let highlight_js_element =
    "<script>"
    ^ (Option.get @@ Highlightjs.read "highlight.min.js")
    ^ "</script>"
  in
  let highlight_js_lang_element lang =
    let filename = "languages/" ^ lang ^ ".min.js" in
    Highlightjs.read filename
    |> Option.map @@ fun s -> "<script>" ^ s ^ "</script>"
  in
  let highlight_js_lang_elements =
    has.code_blocks |> fun x ->
    Has.StringSet.fold
      (fun h acc ->
        match highlight_js_lang_element h with
        | None -> acc
        | Some l -> l :: acc)
      x []
    |> String.concat ""
  in
  let pdf_support =
    if has.pdf then
      "<script id=\"__pdf_support\">"
      ^ Data_files.(read Pdf_support)
      ^ "</script>"
    else ""
  in
  let favicon_element =
    let href =
      let mime_type = "image/x-icon" in
      let base64 = Base64.encode_string Data_files.(read Favicon) in
      Format.sprintf "data:%s;base64,%s" mime_type base64
    in
    Format.sprintf {|<link rel="icon" type="image/x-icon" href="%s">|} href
  in
  let css_elements = List.map css_element css_links |> String.concat "" in
  let math_option = math_option_elem math_mode ~has_math:has.math in
  let mermaid_option = mermaid_option_elem ~has_mermaid:has.mermaid in
  String.concat "\n"
    [
      pdf_support;
      variable_css ~width ~height;
      favicon_element;
      internal_css;
      system_css;
      theme;
      css_elements;
      highlight_css_element;
      highlight_js_element;
      highlight_js_lang_elements;
      math_option;
      mermaid_option;
    ]

let embed_in_page ~has_speaker_view ~slipshow_js content ~has ~math_link
    ~css_links ~js_links ~theme ~dimension ~highlightjs_theme ~math_mode =
  let width, height = dimension in
  let head =
    head ~has ~css_links ~theme ~width ~height ~highlightjs_theme ~math_mode
  in
  let slipshow_js_element = slipshow_js_element slipshow_js in
  let js =
    js_links
    |> List.map (function
         | Asset.Local { content = t; _ } ->
             Format.sprintf "<script>%s</script>" t
         | Remote r -> Format.sprintf {|<script src="%s"></script>|} r)
    |> String.concat ""
  in
  let mathjax_element = mathjax_element math_mode has.math math_link in
  let mermaid_element = mermaid_element has.mermaid in
  let start =
    String.concat ""
      [
        {|
<!doctype html>
<html>
  <head>|};
        (if has_speaker_view then {|    <base target="_parent">|} else "");
        {|
    <meta charset="utf-8" />
    |};
        head;
        {|
  </head>
  <body>
    <div id="slipshow-vertical-flex">
      <div id="slipshow-horizontal-flex">
        <div id="slipshow-main">
          <div id="slipshow-content">
            <svg id="slipshow-drawing-elem" style="overflow:visible; position: absolute; z-index:1000; pointer-events: none"></svg>
            |};
        content;
        {|
          </div>
          <div id="slip-touch-controls">
            <div class="slip-previous">←</div>
            <div class="slip-fullscreen">⇱</div>
            <div class="slip-next">→</div>
          </div>
          <div id="slipshow-counter">0</div>
        </div>
      </div>
    </div>
    <!-- Include the library -->
      |};
        slipshow_js_element;
        {|
    <!-- Start the presentation () -->
    <script>hljs.highlightAll();</script>|};
        mathjax_element;
        mermaid_element;
        {|    <script>
        async function startfunction () {
        if (typeof mermaid !== "undefined" )
          await mermaid.run();
        startSlipshow(|};
        string_of_int width;
        {|, |};
        string_of_int height;
        {|,|};
      ]
  in
  let end_ =
    Format.sprintf
      {|);
};
      startfunction()
    </script>%s
  </body>
</html>|}
      js
  in
  (start, end_, has_speaker_view)

type starting_state = int
type delayed = string * string * bool

let delayed_to_string s = Marshal.to_string s [] |> Base64.encode_string

let string_to_delayed s =
  let s =
    s |> Base64.decode |> function Ok x -> x | Error _ -> failwith "Hello11"
  in
  Marshal.from_string s 0

let convert_to_md ~read_file content =
  let md = Cmarkit.Doc.of_string ~heading_auto_ids:true ~strict:false content in
  let sd = Compile.of_cmarkit ~read_file md in
  let sd = Compile.to_cmarkit sd in
  Cmarkit_commonmark.of_doc ~include_attributes:false sd

let delayed ?slipshow_js ?(frontmatter = Frontmatter.empty)
    ?(read_file = fun _ -> Ok None) ~has_speaker_view s =
  let Frontmatter.Resolved frontmatter, s =
    let ( let* ) x f =
      match x with
      | Ok x -> f x
      | Error (`Msg err) ->
          Logs.err (fun m -> m "Failed to parse the frontmatter: %s" err);
          (frontmatter, s)
    in
    match Frontmatter.extract s with
    | None -> (frontmatter, s)
    | Some (yaml, s) ->
        let* txt_frontmatter = Frontmatter.of_string yaml in
        let to_asset = Asset.of_string ~read_file in
        let txt_frontmatter = Frontmatter.resolve txt_frontmatter ~to_asset in
        let frontmatter = Frontmatter.combine txt_frontmatter frontmatter in
        (frontmatter, s)
  in
  let toplevel_attributes =
    frontmatter.toplevel_attributes
    |> Option.value ~default:Frontmatter.Default.toplevel_attributes
  in
  let dimension =
    frontmatter.dimension |> Option.value ~default:Frontmatter.Default.dimension
  in
  let css_links = frontmatter.css_links in
  let js_links = frontmatter.js_links in
  let math_mode =
    Option.value ~default:Frontmatter.Default.math_mode frontmatter.math_mode
  in
  let theme =
    match frontmatter.theme with
    | None -> Frontmatter.Default.theme
    | Some (`Builtin _ as x) -> x
    | Some (`External x) ->
        let asset = Asset.of_string ~read_file x in
        `External asset
  in
  let highlightjs_theme =
    Option.value ~default:Frontmatter.Default.highlightjs_theme
      frontmatter.highlightjs_theme
  in
  let math_link = frontmatter.math_link in
  let md = Compile.compile ~attrs:toplevel_attributes ~read_file s in
  let content = Renderers.to_html_string md in
  let has = Has.find_out md in
  embed_in_page ~has_speaker_view ~slipshow_js ~dimension ~has ~math_link ~theme
    ~css_links ~js_links content ~highlightjs_theme ~math_mode

let add_starting_state ?(autofocus = true) (start, end_, has_speaker_view)
    (starting_state : starting_state option) =
  let autofocus = if autofocus then "autofocus" else "" in
  let starting_state =
    match starting_state with None -> "0" | Some st -> string_of_int st
  in
  let html = start ^ starting_state ^ end_ in
  let orig_html = html in
  let html =
    let buf = Buffer.create 10 in
    Cmarkit_html.buffer_add_html_escaped_string buf html;
    Buffer.contents buf
  in
  let favicon_element =
    let href =
      let mime_type = "image/x-icon" in
      let base64 = Base64.encode_string Data_files.(read Favicon) in
      Format.sprintf "data:%s;base64,%s" mime_type base64
    in
    Format.sprintf {|<link rel="icon" type="image/x-icon" href="%s">|} href
  in
  let html =
    String.concat ""
      [
        {|
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
|};
        favicon_element;
        {|
  </head>
    <body>
      <iframe |};
        autofocus;
        {| name="slipshow_main_pres" id="slipshow__internal_iframe" srcdoc="|};
        html;
        {|" style="
    width: 100%;
    height: 100%;
    position: fixed;
    left: 0;
    border: 1px;
    right: 0;
    top: 0;
    bottom: 0;
"></iframe>

      <script>
|};
        Data_files.(read Scheduler_js);
        {|
      </script>
  </body>
</html>|};
      ]
  in
  if has_speaker_view then html else orig_html

let convert ~has_speaker_view ?autofocus ?slipshow_js ?frontmatter
    ?starting_state ?read_file s =
  let delayed =
    delayed ~has_speaker_view ?slipshow_js ?frontmatter ?read_file s
  in
  add_starting_state ?autofocus delayed starting_state
