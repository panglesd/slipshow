val send_ready : Brr.Window.t -> unit -> unit
val send_step : Brr.Window.t -> int -> [ `Fast | `Normal ] -> unit

(* module Draw_event : sig *)
(*   type t = Draw of string | Erase of string | Clear of string *)

(*   val to_string : t -> string *)
(*   val of_string : string -> t option *)
(* end *)

val draw : (* Draw_event.t *) Brr.Window.t -> string -> unit
val send_all_strokes : Brr.Window.t -> string list -> unit
val open_speaker_notes : Brr.Window.t -> unit -> unit
val send_speaker_notes : Brr.Window.t -> string -> unit
