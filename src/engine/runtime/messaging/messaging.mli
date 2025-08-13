val send_ready : unit -> unit
val send_step : int -> [ `Fast | `Normal ] -> unit
val draw : Communication.drawing_event -> unit
val send_all_strokes : Communication.stroke list -> unit
val send_speaker_notes : unit -> unit
