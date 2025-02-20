type file =
  | Slipshow_js
  | Slip_css
  | Mathjax_js
  | Highlight_js
  | Highlight_css
  | Highlight_js_ocaml

let string_of_file = function
  | Slipshow_js -> "slipshow.cdn.min.js.crunch"
  | Slip_css -> "slip.css.crunch"
  | Mathjax_js -> "tex-svg.js.crunch"
  | Highlight_css -> "highlight-js.css.crunch"
  | Highlight_js -> "highlight-js.js.crunch"
  | Highlight_js_ocaml -> "highlight-js.ocaml.js.crunch"

let read f =match f with
  | Slipshow_js -> [%blob "src/engine/slipshow.js"]
  | Slip_css -> [%blob "src/engine/slipshow.css"]
  | _ ->
     Data_contents.read (string_of_file f)
     |> function
       | Some c -> c
       | None -> assert false
