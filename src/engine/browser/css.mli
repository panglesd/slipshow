type property =
  | Scale of float
  | Rotate of float
  | Translate of { x : float; y : float }
  | Left of float
  | Right of float
  | Top of float
  | Bottom of float
  | TransitionDuration of float
  | TransitionDelay of float
  | TransitionTiming of string
  | Width of float
  | Height of float

val set : property list -> Brr.El.t -> unit Fut.t
