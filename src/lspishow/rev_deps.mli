type t

val as_map : t -> Fpath.set Fpath.Map.t

val current : t
(** Rev deps for opened buffers. **)

val update_state :
  old_unit:Slipshow.Ast.unit' option ->
  new_unit:Slipshow.Ast.unit' ->
  Fpath.t ->
  unit
(** Updates the rev deps of a changed units. Needs the old value to remove
    recorded deps. **)

val get_roots : Fpath.t -> Fpath.set
(** Get the root(s) of a path. **)
