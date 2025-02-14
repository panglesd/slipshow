type file =
  | Slipshow_js
  | Slip_css
  | Mathjax_js
  | Highlight_js
  | Highlight_css
  | Highlight_js_ocaml

val read : file -> string
