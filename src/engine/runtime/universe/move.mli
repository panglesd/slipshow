val move :
  Fast.mode ->
  Window.t ->
  Coordinates.window ->
  duration:float ->
  unit Undoable.t

val move_relative_pure :
  ?x:float ->
  ?y:float ->
  ?scale:float ->
  Fast.mode ->
  Window.t ->
  duration:float ->
  unit Fut.t

val move_relative :
  ?x:float ->
  ?y:float ->
  ?scale:float ->
  Fast.mode ->
  Window.t ->
  duration:float ->
  unit Undoable.t

val focus_pure :
  ?margin:float -> Fast.mode -> Window.t -> Brr.El.t list -> unit Fut.t

val focus :
  ?duration:float ->
  ?margin:float ->
  Fast.mode ->
  Window.t ->
  Brr.El.t list ->
  unit Undoable.t

val enter :
  ?duration:float ->
  ?margin:float ->
  Fast.mode ->
  Window.t ->
  Brr.El.t ->
  unit Undoable.t

val up :
  ?duration:float ->
  ?margin:float ->
  Fast.mode ->
  Window.t ->
  Brr.El.t ->
  unit Undoable.t

val center :
  ?duration:float ->
  ?margin:float ->
  Fast.mode ->
  Window.t ->
  Brr.El.t ->
  unit Undoable.t

val down :
  ?duration:float ->
  ?margin:float ->
  Fast.mode ->
  Window.t ->
  Brr.El.t ->
  unit Undoable.t

val scroll :
  ?duration:float ->
  ?margin:float ->
  Fast.mode ->
  Window.t ->
  Brr.El.t ->
  unit Undoable.t
