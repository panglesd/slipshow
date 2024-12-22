type property =
  | Scale of float
  | Rotate of float
  | Left of float
  | Right of float
  | Top of float
  | Bottom of float
  | TransitionDuration of float
  | Width of float
  | Height of float

val set : property list -> Brr.El.t -> unit UndoMonad.t
val set_pure : property list -> Brr.El.t -> unit Fut.t
