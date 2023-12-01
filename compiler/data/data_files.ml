type file =
  | Slipshow_js
  | Slip_css
  | Theorem_css
  | Mathjax_js
  | Tailwind_css
  | Highlight_js
  | Highlight_css
  | Highlight_js_ocaml

let string_of_file = function
  | Slipshow_js -> "slipshow.cdn.min.js"
  | Slip_css -> "slip.css"
  | Theorem_css -> "theorem.css"
  | Mathjax_js -> "tex-chtml.js"
  | Tailwind_css -> "tailwindcss.js"
  | Highlight_css -> "highlight-js.css"
  | Highlight_js -> "highlight-js.js"
  | Highlight_js_ocaml -> "highlight-js.ocaml.js"

let read f =
  Data_contents.read (string_of_file f) |> function
  | Some c -> c
  | None -> assert false
