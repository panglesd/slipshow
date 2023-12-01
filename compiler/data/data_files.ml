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
  | Slipshow_js -> "slipshow.cdn.min.js.crunch"
  | Slip_css -> "slip.css.crunch"
  | Theorem_css -> "theorem.css.crunch"
  | Mathjax_js -> "tex-chtml.js.crunch"
  | Tailwind_css -> "tailwindcss.js.crunch"
  | Highlight_css -> "highlight-js.css.crunch"
  | Highlight_js -> "highlight-js.js.crunch"
  | Highlight_js_ocaml -> "highlight-js.ocaml.js.crunch"

let read f =
  Data_contents.read (string_of_file f) |> function
  | Some c -> c
  | None -> assert false
