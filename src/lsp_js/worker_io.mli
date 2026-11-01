(* Taken and adapted from:
   https://github.com/voodoos/merlin-js/blob/a7367198d332f153ed27de2136d3c6a4af8e206f/src/lsp/worker_io.mli *)

include Linol.IO with type 'a t = 'a Lwt.t and type out_channel = unit and type env = unit

val create_in_channel : unit -> in_channel
val push_message : in_channel -> string -> unit
