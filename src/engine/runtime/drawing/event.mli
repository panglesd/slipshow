(** This contains event handlers. They send messages to other frames. *)

val start_recording : unit -> unit
val end_recording : unit -> Record.t option
val continue_shape : Types.origin -> Brr.Ev.Pointer.t Brr.Ev.t -> unit
val start_shape : Types.origin -> Brr.Ev.Pointer.t Brr.Ev.t -> unit
val end_shape : Types.origin -> unit -> unit
val clear : Types.origin -> unit -> unit
