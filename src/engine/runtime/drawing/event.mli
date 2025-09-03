(** This contains event handlers. They send messages to other frames. *)

val continue_shape : Brr.Ev.Pointer.t Brr.Ev.t -> unit
val start_shape : Brr.Ev.Pointer.t Brr.Ev.t -> unit
val end_shape : unit -> unit
val clear : unit -> unit
