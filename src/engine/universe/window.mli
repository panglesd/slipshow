type t

val pp : t -> unit
val setup : Brr.El.t -> t Fut.t
val translate_coords : float * float -> float * float
val move_pure : t -> Coordinates.window -> duration:float -> unit Fut.t

val with_fast_moving : (unit -> unit Fut.t) -> unit Fut.t
(** Inside this scope, window movement are immediate no matter the initial delay
*)

(** The following values are useful for computing coordinates from
    [getBoundingRect]: *)

val bound_x : t -> float
val bound_y : t -> float
val live_scale : t -> float
