val set_coord : Coordinates.window -> unit
val get_coord : unit -> Coordinates.window
val get_step : unit -> int
val incr_step : unit -> unit UndoMonad.t

module Focus : sig
  val push : Coordinates.window -> unit UndoMonad.t
  val pop : unit -> Coordinates.window option UndoMonad.t
end
