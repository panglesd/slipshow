type payload =
  | State of int * [ `Fast | `Normal ]
  | Ready
  | Open_speaker_notes
  | Close_speaker_notes
  | Speaker_notes of string
  | Drawing of string
  | Send_all_drawing
  | Receive_all_drawing of string list
  | Next
  | Previous

type t = { payload : payload; id : string }

val of_string : string -> t option
val to_string : t -> string
