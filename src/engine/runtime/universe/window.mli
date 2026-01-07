type t

val pp : t -> unit
val setup : Global_state.t -> Brr.El.t -> t Fut.t
val translate_coords : Global_state.t -> float * float -> float * float

val move_pure :
  Global_state.t -> t -> Coordinates.window -> duration:float -> unit Fut.t

(** The following values are useful for computing coordinates from
    [getBoundingRect]: *)

val bound_x : t -> float
val bound_y : t -> float
val live_scale : t -> float
