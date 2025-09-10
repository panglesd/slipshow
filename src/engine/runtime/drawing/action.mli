module Record : sig
  type record

  val start_record : unit -> unit
  val stop_record : unit -> record option
end

val continue_shape : float * float -> unit
val create_elem_of_stroke : Types.Stroke.t -> Brr.El.t
val start_shape : string -> State.t -> float * float -> unit
val end_shape : unit -> unit
val clear : unit -> unit

module Replay : sig
  val replay : ?speedup:float -> Record.record -> unit
end
