type t

val as_map : t -> Fpath.set Fpath.Map.t

val current : t
(** Rev deps for opened buffers. *)

val update_state : new_unit:Slipshow.Ast.unit' -> Fpath.t -> unit
(** Updates the rev deps of a changed units. *)

val remove : Fpath.t -> unit

val get_roots : Fpath.t -> Fpath.set
(** Get the root(s) of a path. *)
