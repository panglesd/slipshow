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

type 'a t :=
  ?duration:float -> ?margin:float -> Window.t -> 'a -> unit Undoable.t

val focus : Brr.El.t list t
val enter : Brr.El.t t
val h_enter : Brr.El.t t
val up : Brr.El.t t
val center : Brr.El.t t
val down : Brr.El.t t
val scroll : Brr.El.t t
val right : Brr.El.t t
