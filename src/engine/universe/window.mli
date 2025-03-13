type window

val pp : window -> unit
val setup : Brr.El.t -> window Fut.t
val move_pure : window -> Coordinates.window -> delay:float -> unit Fut.t
val move : window -> Coordinates.window -> delay:float -> unit Undoable.t
val translate_coords : float * float -> float * float

val move_relative_pure :
  ?x:float -> ?y:float -> ?scale:float -> window -> delay:float -> unit Fut.t

val move_relative :
  ?x:float ->
  ?y:float ->
  ?scale:float ->
  window ->
  delay:float ->
  unit Undoable.t

val focus_pure : window -> Brr.El.t list -> unit Fut.t
val focus : window -> Brr.El.t list -> unit Undoable.t
val enter : window -> Brr.El.t -> unit Undoable.t
val up : window -> Brr.El.t -> unit Undoable.t
val center : window -> Brr.El.t -> unit Undoable.t
val down : window -> Brr.El.t -> unit Undoable.t

val with_fast_moving : (unit -> unit Fut.t) -> unit Fut.t
(** Inside this scope, window movement are immediate no matter the initial delay
*)
