(** A rescaler is an element which:
    - Transform its child so that its child width becomes the same as its own
      width (usually, children of rescalers have a fixed width)
    - Adapt its height to the (new) child height.

    For instance, a subslip needs a rescaler to have a fixed rendering (as if
    rendered on 1920px of width) but have another width computed by something
    else (eg three subslips in a flexbox row) *)

val setup_rescalers : unit -> unit
(** Setup resize_observers for all elements with the right class *)
