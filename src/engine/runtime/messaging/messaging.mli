val send_ready : Global_state.t -> unit -> unit
val send_step : Global_state.t -> int -> [ `Fast | `Normal ] -> unit

(* module Draw_event : sig *)
(*   type t = Draw of string | Erase of string | Clear of string *)

(*   val to_string : t -> string *)
(*   val of_string : string -> t option *)
(* end *)

val draw : (* Draw_event.t *) Global_state.t -> string -> unit
val send_all_strokes : Global_state.t -> string list -> unit
val open_speaker_notes : Global_state.t -> unit -> unit
val send_speaker_notes : Global_state.t -> string -> unit
