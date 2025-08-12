val set_id : string option -> unit
val send_ready : unit -> unit
val send_step : int -> [ `Fast | `Normal ] -> unit
val draw : Communication.drawing_payload -> unit
val send_speaker_notes : unit -> unit
