val send_ready : unit -> unit
val send_step : int -> [ `Fast | `Normal ] -> unit

(* module Draw_event : sig *)
(*   type t = Draw of string | Erase of string | Clear of string *)

(*   val to_string : t -> string *)
(*   val of_string : string -> t option *)
(* end *)

val draw : (* Draw_event.t *) string -> unit
val send_all_strokes : string list -> unit
val open_speaker_notes : unit -> unit
val send_speaker_notes : string -> unit
