(** This contains event handlers. They send messages to other frames. *)

val start_recording : unit -> unit
val end_recording : unit -> Record.t option
val continue_shape : Types.origin -> Brr.Ev.Pointer.t Brr.Ev.t -> unit
val start_shape : Types.origin -> Brr.Ev.Pointer.t Brr.Ev.t -> unit
val end_shape : Types.origin -> unit -> unit
val clear : unit -> unit
(* val continue : Types.origin -> float * float -> unit *)
(* val start : Types.origin -> State.t -> float * float -> string -> unit *)
(* val end_ : Types.origin -> unit -> unit *)
