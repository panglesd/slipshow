val move :
  Global_state.t ->
  Window.t ->
  Coordinates.window ->
  duration:float ->
  unit Undoable.t

val move_relative_pure :
  Global_state.t ->
  ?x:float ->
  ?y:float ->
  ?scale:float ->
  Window.t ->
  duration:float ->
  unit Fut.t

val move_relative :
  Global_state.t ->
  ?x:float ->
  ?y:float ->
  ?scale:float ->
  Window.t ->
  duration:float ->
  unit Undoable.t

val focus_pure :
  Global_state.t -> ?margin:float -> Window.t -> Brr.El.t list -> unit Fut.t

val focus :
  Global_state.t ->
  ?duration:float ->
  ?margin:float ->
  Window.t ->
  Brr.El.t list ->
  unit Undoable.t

val enter :
  Global_state.t ->
  ?duration:float ->
  ?margin:float ->
  Window.t ->
  Brr.El.t ->
  unit Undoable.t

val up :
  Global_state.t ->
  ?duration:float ->
  ?margin:float ->
  Window.t ->
  Brr.El.t ->
  unit Undoable.t

val center :
  Global_state.t ->
  ?duration:float ->
  ?margin:float ->
  Window.t ->
  Brr.El.t ->
  unit Undoable.t

val down :
  Global_state.t ->
  ?duration:float ->
  ?margin:float ->
  Window.t ->
  Brr.El.t ->
  unit Undoable.t

val scroll :
  Global_state.t ->
  ?duration:float ->
  ?margin:float ->
  Window.t ->
  Brr.El.t ->
  unit Undoable.t
