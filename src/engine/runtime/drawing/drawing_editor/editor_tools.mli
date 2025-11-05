module Selection : sig
  module Timeline : sig
    val event : State_types.t -> stroke_height:int -> Brr_lwd.Elwd.handler
    val box : Brr.El.t Lwd_seq.t Lwd.t
  end

  module Preview : sig
    val event : State_types.t -> Brr_lwd.Elwd.handler
    val box : Brr.El.t Lwd_seq.t Lwd.t
  end
end

module Move : sig
  module Timeline : sig
    val event : State_types.t -> stroke_height:int -> Brr_lwd.Elwd.handler
  end

  module Preview : sig
    val event : State_types.t -> Brr_lwd.Elwd.handler
  end
end

module Scale : sig
  module Timeline : sig
    val event : State_types.t -> Brr_lwd.Elwd.handler
  end

  module Preview : sig
    val event : State_types.t -> Brr_lwd.Elwd.handler
  end
end
