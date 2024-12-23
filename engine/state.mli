val set_coord : Coordinates.window -> unit
val get_coord : unit -> Coordinates.window

module Focus : sig
  val push : Coordinates.window -> unit UndoMonad.t
  val pop : unit -> Coordinates.window UndoMonad.t
end
