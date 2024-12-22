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
val move_pure : window -> Coordinates.window -> delay:float -> unit Fut.t
val move : window -> Coordinates.window -> delay:float -> unit UndoMonad.t

val move_relative_pure :
  ?x:float -> ?y:float -> ?scale:float -> window -> delay:float -> unit Fut.t

val move_relative :
  ?x:float ->
  ?y:float ->
  ?scale:float ->
  window ->
  delay:float ->
  unit UndoMonad.t

val move_to_pure : window -> Brr.El.t -> unit Fut.t
val move_to : window -> Brr.El.t -> unit UndoMonad.t
val enter : window -> Brr.El.t -> unit UndoMonad.t
val up : window -> Brr.El.t -> unit UndoMonad.t
