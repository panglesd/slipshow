type file =
  | Slipshow_js
  | Scheduler_js
  | Pdf_support
  | Slip_internal_css
  | Slip_system_css
  | Favicon
  | Mathjax_js

let string_of_file = function
  | Mathjax_js -> "tex-svg-full.js.crunch"
  | _ -> assert false

let read f = match f with
  | Slipshow_js -> [%blob "../src/engine/runtime/slipshow.js"]
  | Scheduler_js -> [%blob "../src/engine/scheduler/scheduler.bc.js"]
  | Slip_internal_css -> [%blob "../src/engine/runtime/slipshow-internal.css"]
  | Slip_system_css -> [%blob "../src/engine/runtime/slipshow-system.css"]
  | Pdf_support -> [%blob "../src/engine/pdf-support/pdf_support.bc.js"]
  | Favicon -> [%blob "../logo/favicon.ico"]
  | _ ->
     Data_contents.read (string_of_file f)
     |> function
       | Some c -> c
       | None -> assert false
