type drawing_event =
  | End
  | Start of { id : string; state : string; coord : float * float }
  | Continue of { coord : float * float }
  | Clear

type payload =
  | State of int * [ `Fast | `Normal ]
  | Ready
  | Open_speaker_notes
  | Close_speaker_notes
  | Speaker_notes of string
  | Drawing of drawing_event
  | Send_all_drawing
  | Receive_all_drawing of string list

type t = { payload : payload; id : string }

val of_string : string -> t option
val to_string : t -> string
