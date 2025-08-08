type payload = State of int | Ready | Open_speaker_notes
type t = { id : string; payload : payload }

val of_string : string -> t option
val to_string : t -> string
