(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** OCaml poke object definition for the OCaml console.

    See the {{!page-ocaml_console}OCaml console documentation}
    for more information. *)

val define : unit -> unit
(** [define ()] defines a global
    {{!page-ocaml_console.ocaml_poke}[ocaml_poke]} object in
    the global context of the caller.

    {b Limitation.} Due to {!Js_of_ocaml_toplevel.JsooTop}, this poke
    object sets channel flusher via
    {!Jsoo_runtime.Sys.set_channel_output'} for [stdout] and [stderr].
    This will not work if your application makes use of these
    channels. It's unclear whether this limitation can be easily
    lifted. *)

val pp_jstr : Format.formatter -> Jstr.t -> unit
val pp_jv_error : Format.formatter -> Jv.Error.t -> unit
val pp_jv : Format.formatter -> Jv.t -> unit
