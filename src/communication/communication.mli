type drawing_event =
  | End of { state : string }
  | Start of { id : string; state : string; coord : float * float }
  | Continue of { state : string; coord : float * float }
  | Clear

type stroke = { id : string; state : string; path : (float * float) list }

type payload =
  | State of int * [ `Fast | `Normal ]
  | Ready
  | Open_speaker_notes
  | Drawing of drawing_event
  | Send_all_drawing
  | Receive_all_drawing of stroke list

type t = { payload : payload }

val of_string : string -> t option
val to_string : t -> string
