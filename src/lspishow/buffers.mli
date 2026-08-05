type buffer = { source : string; unit : Slipshow.Ast.unit' }
type t = (Fpath.t, buffer) Hashtbl.t

val buffers : t

val read_file : Fpath.t -> Slipshow.file_reader
(** Read files, taking the value in the opened buffers if needed. *)

val to_units : unit -> Slipshow.Ast.unit' Fpath.map
(** The opened buffer units *)

val update : force:bool -> Fpath.t -> string -> 'b option -> unit
(** Update a buffer to contain a source. If [force] is true, force the
    recomputation of the buffer, but don't update root. *)
