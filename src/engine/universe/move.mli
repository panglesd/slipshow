val move : Window.t -> Coordinates.window -> delay:float -> unit Undoable.t

val move_relative_pure :
  ?x:float -> ?y:float -> ?scale:float -> Window.t -> delay:float -> unit Fut.t

val move_relative :
  ?x:float ->
  ?y:float ->
  ?scale:float ->
  Window.t ->
  delay:float ->
  unit Undoable.t

val focus_pure : ?margin:float -> Window.t -> Brr.El.t list -> unit Fut.t

val focus :
  ?delay:float -> ?margin:float -> Window.t -> Brr.El.t list -> unit Undoable.t

val enter : Window.t -> Brr.El.t -> unit Undoable.t
val up : Window.t -> Brr.El.t -> unit Undoable.t
val center : Window.t -> Brr.El.t -> unit Undoable.t
val down : Window.t -> Brr.El.t -> unit Undoable.t
val scroll : Window.t -> Brr.El.t -> unit Undoable.t
