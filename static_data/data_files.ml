type file =
  | Slipshow_js
  | Scheduler_js
  | Pdf_support
  | Slip_internal_css
  | Slip_system_css
  | Favicon
  | Mathjax_js

let read f = match f with
  | Slipshow_js -> [%blob "../src/engine/runtime/slipshow.js"]
  | Scheduler_js -> [%blob "../src/engine/scheduler/scheduler.bc.js"]
  | Slip_internal_css -> [%blob "../src/engine/runtime/slipshow-internal.css"]
  | Slip_system_css -> [%blob "../src/engine/runtime/slipshow-system.css"]
  | Pdf_support -> [%blob "../src/engine/pdf-support/pdf_support.bc.js"]
  | Mathjax_js -> [%blob "tex-svg-full.js"]
  | Favicon -> [%blob "../logo/favicon.ico"]
