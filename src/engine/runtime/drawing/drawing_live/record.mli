type 'a timed = 'a * float

type event =
  [ `Draw of Tools.Draw.event
  | `Erase of Tools.Erase.event
  | `Clear of Tools.Clear.event ]

type t = { events : event timed list; record_id : int }
(** Ordered by time *)

type recording_in_progress

val of_string : string -> (t, string) result
val to_string : t -> string
val start_record : unit -> recording_in_progress
val stop_record : recording_in_progress -> t
val record : event -> recording_in_progress -> unit
val now : unit -> float
