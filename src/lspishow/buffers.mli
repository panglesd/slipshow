type buffer = { source : string; unit : Slipshow.Ast.unit' }
type t = (Fpath.t, buffer) Hashtbl.t

val buffers : t

val read_file : Fpath.t -> Slipshow.file_reader
(** Read files, taking the value in the opened buffers if needed. *)

val to_units : unit -> Slipshow.Ast.unit' Fpath.map
(** The opened buffer units *)

val update : Fpath.t -> string -> unit
(** Update a buffer to contain a source *)
