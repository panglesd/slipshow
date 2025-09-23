module Record : sig
  type event = Stroke of Types.Stroke.t | Erase of float

  type t = event list
  (** Ordered by time *)

  val of_string : string -> (t, string) result
  val to_string : t -> string
  val start_record : unit -> unit
  val stop_record : unit -> t option
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
  val replay : ?speedup:float -> Record.t -> unit Fut.t
  val draw_until : elapsed_time:float -> Record.t -> Brr.El.t list
end
