module Asset = Asset
module Frontmatter = Frontmatter

type file_reader = Fpath.t -> (string option, [ `Msg of string ]) result

let mathjax_element has_math math_link =
  if not has_math then ""
  else
    match math_link with
    | Some (Asset.Local { content = t; _ }) ->
        Format.sprintf "<script id=\"MathJax-script\">%s</script>" t
    | Some (Remote r) ->
        Format.sprintf "<script id=\"MathJax-script\" src=\"%s\"></script>" r
    | None ->
        Format.sprintf "<script id=\"MathJax-script\">%s</script>"
          Data_files.(read Mathjax_js)

let css_element = function
  | Asset.Local { content = t; _ } -> Format.sprintf "<style>%s</style>" t
  | Remote r -> Format.sprintf {|<link href="%s" rel="stylesheet" />|} r

let theme_css = function
  | `Builtin theme -> Format.sprintf "<style>%s</style>" (Themes.content theme)
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

let head ~width ~height ~theme ~has_math ~math_link ~css_links =
  let theme = theme_css theme in
  let highlight_css_element =
    "<style>" ^ Data_files.(read Highlight_css) ^ "</style>"
  in
  let highlight_js_element =
    "<script>" ^ Data_files.(read Highlight_js) ^ "</script>"
  in
  let highlight_js_ocaml_element =
    "<script>" ^ Data_files.(read Highlight_js_ocaml) ^ "</script>"
  in
  let favicon_element =
    let href =
      let mime_type = "image/x-icon" in
      let base64 = Base64.encode_string Data_files.(read Favicon) in
      Format.sprintf "data:%s;base64,%s" mime_type base64
    in
    Format.sprintf {|<link rel="icon" type="image/x-icon" href="%s">|} href
  in
  let mathjax_element = mathjax_element has_math math_link in
  let css_elements = List.map css_element css_links |> String.concat "" in
  String.concat "\n"
    [
      variable_css ~width ~height;
      favicon_element;
      mathjax_element;
      internal_css;
      system_css;
      theme;
      css_elements;
      highlight_css_element;
      highlight_js_element;
      highlight_js_ocaml_element;
    ]

let embed_in_page content ~has_math ~math_link ~css_links ~theme ~dimension =
  let width, height = dimension in
  let head = head ~has_math ~math_link ~css_links ~theme ~width ~height in
  let slipshow_js_element = slipshow_js_element None in
  let start =
    Format.sprintf
      {|
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    %s
  </head>
  <body>
    <div id="slipshow-main">
      <div id="slipshow-content">
        <svg id="slipshow-drawing-elem" style="overflow:visible; position: absolute; z-index:1000"></svg>
        %s
      </div>
      <div id="slip-touch-controls">
        <div class="slip-previous">←</div>
        <div class="slip-fullscreen">⇱</div>
        <div class="slip-next">→</div>
      </div>
      <div id="slipshow-counter">0</div>
    </div>

    <!-- Include the library -->
    %s
    <!-- Start the presentation () -->
    <script>hljs.highlightAll();</script>
    <script>
      startSlipshow(%d, %d,|}
      head content slipshow_js_element width height
  in
  let end_ = {|);
    </script>
  </body>
                   </html>|} in
  (start, end_)

type starting_state = int * string
type delayed = string * string

let delayed_to_string s = Marshal.to_string s [] |> Base64.encode_string

let string_to_delayed s =
  let s = s |> Base64.decode |> Result.get_ok in
  Marshal.from_string s 0

let convert_to_md ~read_file content =
  let md = Cmarkit.Doc.of_string ~heading_auto_ids:true ~strict:false content in
  let sd = Compile.of_cmarkit ~read_file md in
  let sd = Compile.to_cmarkit sd in
  Cmarkit_commonmark.of_doc ~include_attributes:false sd

let delayed ?(frontmatter = Frontmatter.empty) ?(read_file = fun _ -> Ok None) s
    =
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
        let* yaml = yaml in
        let* txt_frontmatter = Frontmatter.of_yaml yaml in
        let to_asset = Asset.of_string ~read_file in
        let txt_frontmatter = Frontmatter.resolve txt_frontmatter ~to_asset in
        let frontmatter = Frontmatter.combine frontmatter txt_frontmatter in
        (frontmatter, s)
  in
  let toplevel_attributes =
    frontmatter.toplevel_attributes
    |> Option.value ~default:Frontmatter.Default.toplevel_attributes
  in
  let dimension =
    frontmatter.dimension |> Option.value ~default:Frontmatter.Default.dimension
  in
  let css_links =
    frontmatter.css_links (* |> List.map (Asset.of_string ~read_file) *)
  in
  let theme =
    match frontmatter.theme with
    | None -> Frontmatter.Default.theme
    | Some (`Builtin _ as x) -> x
    | Some (`External x) ->
        let asset = Asset.of_string ~read_file x in
        `External asset
  in
  let math_link =
    frontmatter.math_link (* |> Option.map (Asset.of_string ~read_file) *)
  in
  let md = Compile.compile ~attrs:toplevel_attributes ~read_file s in
  let content =
    Cmarkit_renderer.doc_to_string Renderers.custom_html_renderer md
  in
  let has_math = Folders.has_math md in
  embed_in_page ~dimension ~has_math ~math_link ~theme ~css_links content

let add_starting_state (start, end_) starting_state =
  let starting_state =
    match starting_state with
    | None -> ""
    | Some (st, id) -> string_of_int st ^ ", \"" ^ id ^ "\""
  in
  start ^ starting_state ^ end_

let convert ?frontmatter ?starting_state ?read_file s =
  let delayed = delayed ?frontmatter ?read_file s in
  add_starting_state delayed starting_state
