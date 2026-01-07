(** This is the code that makes it so that:

    - The displayed content has a ratio [width/height], centered, with black
      around it,

    - The displayed content (on scale 1) has size [width x height]

    It is important that 2 is not made by moving the window, as otherwise on
    rescaling the window, the scale would change... *)

val setup : Global_state.t -> Brr.El.t -> unit Fut.t

val translate_coords : Global_state.t -> float * float -> float * float
(** Turn coordinates given as "screen coordinates" to coordinates given as
    inside the black square *)

val scale : Global_state.t -> float -> float
(** Scale coordinates (? TODO: improve docstring) *)
