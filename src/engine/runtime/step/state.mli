type transition = {
  from : int;
  to_ : int;
  mode : Fast.mode;
  mutable next : transition option;
  send_message : bool;
}

type t = At of int | Transition of transition

val get_step : unit -> t

(* val incr_step : unit -> unit Undoable.t *)
val set_step : t -> unit
val to_string : t -> string
