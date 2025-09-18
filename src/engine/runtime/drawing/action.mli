module Record : sig
  type event = Stroke of Types.Stroke.t | Erase of unit
  type timed_event = { event : event; time : float }

  type t = timed_event list
  (** Ordered by time *)

  type record = { start_time : float; evs : t }

  val of_string : string -> (record, string) result
  val to_string : record -> string
  val start_record : unit -> unit
  val stop_record : unit -> record option
end

val continue_shape : float * float -> unit
val create_elem_of_stroke : Types.Stroke.t -> Brr.El.t
val start_shape : string -> State.t -> float * float -> unit
val end_shape : unit -> unit
val clear : unit -> unit

val svg_path :
  Perfect_freehand.Options.t ->
  float ->
  ((float * float) * float) list ->
  string

module Replay : sig
  val replay : ?speedup:float -> Record.record -> unit Fut.t
  val draw_until : elapsed_time:float -> Record.record -> Brr.El.t list
end
