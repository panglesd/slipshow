(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

let js_to_string o =
  if Jv.is_null o then "null" else
  if Jv.is_undefined o then "undefined" else
  Jv.to_string (Jv.call o "toString" [||])

let pp_jv ppf v = Format.pp_print_string ppf (js_to_string v)
let pp_jstr ppf s = Format.fprintf ppf "@[Jstr.v %S@]" (Jstr.to_string s)
let pp_jv_error ppf (e : Jv.Error.t) =
  (* XXX add the stack trace *)
  Format.pp_print_string ppf (js_to_string (Jv.repr e))

let stdouts = ref Jstr.empty (* for capturing toplevel outputs. *)
let stdouts_reset () = stdouts := Jstr.empty
let stdouts_append ~js_string:d =
  stdouts := Jstr.append !stdouts (Obj.magic d : Jstr.t)

let resp = Buffer.create 100

let top_init () =
  (* FIXME investigate if this is a toplevel limitation or a
     js_of_ocaml one: we need to set the stdout/stderr flushers to
     capture errors and directive outputs. This means the poked program
     can't use them. *)
  Jsoo_runtime.Sys.set_channel_output' stdout stdouts_append;
  Jsoo_runtime.Sys.set_channel_output' stderr stdouts_append;
  Js_of_ocaml_toplevel.JsooTop.initialize ();
  (* FIXME we likely want to go differently about these things.
     https://github.com/ocaml/ocaml/pull/10559 would be nice. *)
  let ppf = Format.formatter_of_buffer resp in
  ignore (Js_of_ocaml_toplevel.JsooTop.use ppf
            "#install_printer Brr_poke.pp_jstr;;");
  ignore (Js_of_ocaml_toplevel.JsooTop.use ppf
            "#install_printer Brr_poke.pp_jv_error;;");
  ignore (Js_of_ocaml_toplevel.JsooTop.use ppf
            "#install_printer Brr_poke.pp_jv;;");
  ()

let top_eval phrase =
  let ppf = Format.formatter_of_buffer resp in
  stdouts_reset ();
  Js_of_ocaml_toplevel.JsooTop.execute true ppf (Jstr.to_string phrase);
  let r = Jstr.append !stdouts (Jstr.of_string (Buffer.contents resp)) in
  Buffer.reset resp; stdouts_reset ();
  r

let top_use phrases =
  let ppf = Format.formatter_of_buffer resp in
  stdouts_reset ();
  let _bool = Js_of_ocaml_toplevel.JsooTop.use ppf (Jstr.to_string phrases) in
  let r = Jstr.append !stdouts (Jstr.of_string (Buffer.contents resp)) in
  stdouts_reset (); Buffer.reset resp;
  r

let define () =
  let ocaml_version = Jstr.of_string Sys.ocaml_version in
  let jsoo_version = Jstr.of_string Jsoo_runtime.Sys.version in
  let o =
    Jv.obj [| "version", Jv.of_int 0;
              "ocaml_version", Jv.of_jstr ocaml_version;
              "jsoo_version", Jv.of_jstr jsoo_version;
              "init", Jv.repr top_init;
              "eval", Jv.repr top_eval;
              "use", Jv.repr top_use; |]
  in
  Jv.set Jv.global "ocaml_poke" o
