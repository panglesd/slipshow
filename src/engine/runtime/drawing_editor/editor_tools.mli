module Selection : sig
  val timeline_event :
    State_types.t -> stroke_height:int -> Brr_lwd.Elwd.handler

  val box : Brr.El.t Lwd_seq.t Lwd.t
end

module Move : sig
  val timeline_event :
    State_types.t -> stroke_height:int -> Brr_lwd.Elwd.handler

  val drawing_event : State_types.t -> Brr_lwd.Elwd.handler
end
