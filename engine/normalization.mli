(** This is the code that makes it so that:

    - The displayed content has a ratio [width/height], centered, with black
      around it,

    - The displayed content (on scale 1) has size [width x height]

    It is important that 2 is not made by moving the window, as otherwise on
    rescaling the window, the scale would change... *)

val setup : unit -> unit Fut.t
