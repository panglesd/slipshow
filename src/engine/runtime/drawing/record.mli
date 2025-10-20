type event = Stroke of Types.Stroke.t | Erase of float

type t = event list
(** Ordered by time *)

val of_string : string -> (t, string) result
val to_string : t -> string
val start_record : unit -> unit
val stop_record : unit -> t option
val now : unit -> float
