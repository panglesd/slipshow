(* val draw : *)
(*   elapsed_time:float Lwd.t option -> *)
(*   Drawing_state.Live_coding.stro Lwd_table.t -> *)
(*   Brr.El.t Lwd_seq.t Lwd.t *)

val drawing_area : Brr.El.t Lwd.t
val init_drawing_area : unit -> unit
val for_events : Brr.Window.t -> unit -> unit
