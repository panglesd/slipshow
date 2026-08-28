type buffer = {
  source : string;
  unit : Slipshow.Ast.unit';
  diagnostic : Diagnosis.t list;
}

type t = (Fpath.t, buffer) Hashtbl.t

val buffers : t

val read_file : Fpath.t -> Slipshow.file_reader
(** Read files, taking the value in the opened buffers if needed. *)

val to_units : unit -> (Slipshow.Ast.unit' * Diagnosis.t list) Fpath.map
(** The opened buffer units *)

val update : force:bool -> should_broadcast:bool -> Fpath.t -> string -> unit
(** Update a buffer to contain a source. If [force] is true, force the
    recomputation of the buffer, but don't update root. *)
