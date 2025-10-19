(** This contains event handlers. They send messages to other frames. *)

val continue_shape : Tools.origin -> Brr.Ev.Pointer.t Brr.Ev.t -> unit
val start_shape : Tools.origin -> Brr.Ev.Pointer.t Brr.Ev.t -> unit
val end_shape : Tools.origin -> unit -> unit
val clear : unit -> unit
val continue : Tools.origin -> float * float -> unit
val start : Tools.origin -> State.t -> float * float -> string -> unit
val end_ : Tools.origin -> unit -> unit
