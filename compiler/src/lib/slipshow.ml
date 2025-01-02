type asset = Ast.asset =
  | Local of { mime_type : string option; content : string }
  | Remote of string

let mathjax_element has_math math_link =
  if not has_math then ""
  else
    match math_link with
    | Some (Local { content = t; _ }) ->
        Format.sprintf "<script id=\"MathJax-script\">%s</script>" t
    | Some (Remote r) ->
        Format.sprintf "<script id=\"MathJax-script\" src=\"%s\"></script>" r
    | None ->
        Format.sprintf "<script id=\"MathJax-script\">%s</script>"
          Data_files.(read Mathjax_js)

let slip_css_element = function
  | Some (Local { content = t; _ }) -> Format.sprintf "<style>%s</style>" t
  | Some (Remote r) -> Format.sprintf {|<link href="%s" rel="stylesheet" />|} r
  | None -> Format.sprintf "<style>%s</style>" Data_files.(read Slip_css)

let theorem_css_element = function
  | Some (Local { content = t; _ }) -> Format.sprintf "<style>%s</style>" t
  | Some (Remote r) -> Format.sprintf {|<link href="%s" rel="stylesheet" />|} r
  | None -> Format.sprintf "<style>%s</style>" Data_files.(read Theorem_css)

let slipshow_js_element slipshow_link =
  match slipshow_link with
  | Some (Local { content = t; _ }) -> Format.sprintf "<script>%s</script>" t
  | Some (Remote r) -> Format.sprintf "<script src=\"%s\"></script>" r
  | None -> Format.sprintf "<script>%s</script>" Data_files.(read Slipshow_js)

let embed_in_page content ~has_math ~math_link ~slip_css_link ~theorem_css_link
    ~slipshow_js_link =
  let mathjax_element = mathjax_element has_math math_link in
  let slip_css_element = slip_css_element slip_css_link in
  let theorem_css_element = theorem_css_element theorem_css_link in
  let slipshow_js_element = slipshow_js_element slipshow_js_link in
  let highlight_css_element =
    "<style>" ^ Data_files.(read Highlight_css) ^ "</style>"
  in
  let highlight_js_element =
    "<script>" ^ Data_files.(read Highlight_js) ^ "</script>"
  in
  let highlight_js_ocaml_element =
    "<script>" ^ Data_files.(read Highlight_js_ocaml) ^ "</script>"
  in
  let start =
    Format.sprintf
      {|
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    %s
    %s
    %s
    %s
    %s
    %s
  </head>
  <body>
    <div id="open-window">
      <div class="format-container">
        <div class="rotate-container">
          <div class="scale-container">
            <div class="universe movable" id="universe">
              <div width="10000" height="10000" class="fog"></div>
              <svg id="slipshow-drawing" style="overflow:visible; position: absolute; z-index:1000"></svg>
              <div class="slip-rescaler">
                <div class="slip">
                  <div class="slip-body">
                     %s
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>



  <!-- Include the library -->
    %s
    <!-- Start the presentation () -->
     <script>hljs.highlightAll();</script>
    <script>
//      Slipshow.startSlipshow(|}
      mathjax_element slip_css_element theorem_css_element highlight_css_element
      highlight_js_element highlight_js_ocaml_element content
      slipshow_js_element
  in
  let end_ = {|);
    </script>
  </body>
                   </html>|} in
  (start, end_)

type starting_state = int list * string
type delayed = string * string

let delayed_to_string s = Marshal.to_string s [] |> Base64.encode_string

let string_to_delayed s =
  let s = s |> Base64.decode |> Result.get_ok in
  Marshal.from_string s 0

let delayed ?math_link ?slip_css_link ?theorem_css_link ?slipshow_js_link
    ?(resolve_images = fun x -> Remote x) s =
  let md = Cmarkit.Doc.of_string ~heading_auto_ids:true ~strict:false s in
  let md = Cmarkit.Mapper.map_doc (Mappings.of_cmarkit resolve_images) md in
  let content =
    Cmarkit_renderer.doc_to_string Renderers.custom_html_renderer md
  in
  let has_math = Folders.has_math md in
  embed_in_page ~has_math ~math_link ~slip_css_link ~theorem_css_link
    ~slipshow_js_link content

let add_starting_state (start, end_) starting_state =
  let starting_state =
    match starting_state with
    | None -> ""
    | Some (st, id) ->
        "["
        ^ String.concat "," (List.map string_of_int st)
        ^ "], \"" ^ id ^ "\""
  in
  start ^ starting_state ^ end_

let convert ?starting_state ?math_link ?slip_css_link ?theorem_css_link
    ?slipshow_js_link ?(resolve_images = fun x -> Remote x) s =
  let delayed =
    delayed ?math_link ?slip_css_link ?theorem_css_link ?slipshow_js_link
      ~resolve_images s
  in
  add_starting_state delayed starting_state
