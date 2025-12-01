val move : Window.t -> Coordinates.window -> duration:float -> unit Undoable.t

val move_relative_pure :
  ?x:float ->
  ?y:float ->
  ?scale:float ->
  Window.t ->
  duration:float ->
  unit Fut.t

val move_relative :
  ?x:float ->
  ?y:float ->
  ?scale:float ->
  Window.t ->
  duration:float ->
  unit Undoable.t

val focus_pure : ?margin:float -> Window.t -> Brr.El.t list -> unit Fut.t

type 'a move := ?duration:float -> Window.t -> 'a -> unit Undoable.t

val focus : ?margin:float -> Brr.El.t list move
val enter : Brr.El.t move
val h_enter : Brr.El.t move
val up : ?margin:float -> Brr.El.t move
val center : Brr.El.t move
val down : ?margin:float -> Brr.El.t move
val scroll : ?margin:float -> Brr.El.t move
val right : ?margin:float -> Brr.El.t move
val left : ?margin:float -> Brr.El.t move
