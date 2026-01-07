val get_step : Global_state.t -> int
val incr_step : Global_state.t -> unit Undoable.t
val set_step : Global_state.t -> int -> unit
