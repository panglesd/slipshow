type 'a timed = 'a * float
type event = Stroke of Types.Stroke.t | Erase of string list timed

type t = event list
(** Ordered by time *)

type recording_in_progress

val of_string : string -> (t, string) result
val to_string : t -> string
val start_record : unit -> recording_in_progress
val stop_record : recording_in_progress -> t
val record : recording_in_progress -> event -> unit
val now : unit -> float
