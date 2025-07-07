type file =
  | Slipshow_js
  | Slip_internal_css
  | Slip_system_css
  | Favicon
  | Mathjax_js
  | Highlight_js
  | Highlight_css
  | Highlight_js_ocaml

let string_of_file = function
  | Slipshow_js -> "slipshow.cdn.min.js.crunch"
  | Mathjax_js -> "tex-svg.js.crunch"
  | Highlight_css -> "highlight-js.css.crunch"
  | Highlight_js -> "highlight-js.js.crunch"
  | Highlight_js_ocaml -> "highlight-js.ocaml.js.crunch"
  | _ -> assert false

let read f =match f with
  | Slipshow_js -> [%blob "../engine/slipshow.js"]
  | Slip_internal_css -> [%blob "../engine/slipshow-internal.css"]
  | Slip_system_css -> [%blob "../engine/slipshow-system.css"]
  | Favicon -> [%blob "../../logo/favicon.ico"]
  | _ ->
     Data_contents.read (string_of_file f)
     |> function
       | Some c -> c
       | None -> assert false
