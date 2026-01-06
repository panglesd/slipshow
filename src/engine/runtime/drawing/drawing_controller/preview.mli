(* val draw : *)
(*   elapsed_time:float Lwd.t option -> *)
(*   Drawing_state.Live_coding.stro Lwd_table.t -> *)
(*   Brr.El.t Lwd_seq.t Lwd.t *)

val request_animation_frame : Jv.t -> (float -> unit) -> int
val drawing_area : Brr.El.t Lwd.t
val init_drawing_area : Global_state.t -> unit -> unit
val for_events : Global_state.t -> unit -> unit
