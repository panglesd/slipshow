type drawing_payload =
  | End of { state : string }
  | Start of { id : string; state : string; coord : float * float }
  | Continue of { state : string; coord : float * float }
  | Clear

type payload =
  | State of int * [ `Fast | `Normal ]
  | Ready
  | Open_speaker_notes
  | Drawing of drawing_payload

type t = { id : string; payload : payload }

val of_string : string -> t option
val to_string : t -> string
