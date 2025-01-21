type previewer

(** A previewer is meant for "live previewing without flickering".

    To create a previewer, you {e need} to provide an HTML element that contains
    exactly:
    - An iframe with the [right-panel1] ID
    - An iframe with the [right-panel2] ID.

    When you have a previewer, you can preview a source. For the moment, it has
    to be a {e source}: you cannot pass it a compiled file. *)

val create_previewer :
  ?initial_stage:int -> ?callback:(int -> unit) -> Brr.El.t -> previewer

val preview : previewer -> string -> unit
val preview_compiled : previewer -> Slipshow.delayed -> unit
