type window = {
  scale_container : Brr.El.t;
  rotate_container : Brr.El.t;
  universe : Brr.El.t;
  width : int;
  height : int;
  mutable coordinate : Coordinates.window;
}

val pp : window -> unit
val setup : width:int -> height:int -> window Fut.t
val move : window -> Coordinates.window -> delay:float -> unit Fut.t
val move_u : window -> Coordinates.window -> delay:float -> unit UndoMonad.t

val move_relative :
  ?x:float -> ?y:float -> ?scale:float -> window -> delay:float -> unit Fut.t

val move_relative_u :
  ?x:float ->
  ?y:float ->
  ?scale:float ->
  window ->
  delay:float ->
  unit UndoMonad.t

val move_to : window -> Brr.El.t -> unit Fut.t
val move_to_u : window -> Brr.El.t -> unit UndoMonad.t
val enter_u : window -> Brr.El.t -> unit UndoMonad.t
