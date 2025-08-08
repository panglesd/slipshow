type file =
  | Slipshow_js
  | Scheduler_js
  | Pdf_support
  | Slip_internal_css
  | Slip_system_css
  | Favicon
  | Mathjax_js
  | Highlight_js
  | Highlight_css
  | Highlight_js_ocaml

val read : file -> string
