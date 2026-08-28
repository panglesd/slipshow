type file =
  | Slipshow_js
  | Scheduler_js
  | Pdf_support
  | Slip_internal_css
  | Slip_system_css
  | Favicon
  | Mathjax_js
  | Tachyon_css

val read : file -> string
