val get_step : unit -> int
val incr_step : unit -> unit Undoable.t

module Focus : sig
  val push : Universe.Coordinates.window -> unit Undoable.t
  val pop : unit -> Universe.Coordinates.window option Undoable.t
end
