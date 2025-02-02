type file =
  | Slipshow_js
  | Slip_css
  | Theorem_css
  | Mathjax_js
  | Tailwind_css
  | Highlight_js
  | Highlight_css
  | Highlight_js_ocaml

val read : file -> string
