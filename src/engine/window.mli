type window

val pp : window -> unit
val setup : Brr.El.t -> window Fut.t
val move_pure : window -> Coordinates.window -> delay:float -> unit Fut.t
val move : window -> Coordinates.window -> delay:float -> unit UndoMonad.t
val translate_coords : float * float -> float * float

val move_relative_pure :
  ?x:float -> ?y:float -> ?scale:float -> window -> delay:float -> unit Fut.t

val move_relative :
  ?x:float ->
  ?y:float ->
  ?scale:float ->
  window ->
  delay:float ->
  unit UndoMonad.t

val focus_pure : window -> Brr.El.t -> unit Fut.t
val focus : window -> Brr.El.t -> unit UndoMonad.t
val enter : window -> Brr.El.t -> unit UndoMonad.t
val up : window -> Brr.El.t -> unit UndoMonad.t
val center : window -> Brr.El.t -> unit UndoMonad.t
val down : window -> Brr.El.t -> unit UndoMonad.t
