type property =
  | Scale of float
  | Rotate of float
  | Left of float
  | Right of float
  | Top of float
  | Bottom of float
  | TransitionDuration of float
  | TransitionTiming of string
  | Width of float
  | Height of float

val set : property list -> Brr.El.t -> unit Fut.t
