open Sexplib.Std

type drawing_event =
  | End of { state : string }
  | Start of { id : string; state : string; coord : float * float }
  | Continue of { state : string; coord : float * float }
  | Clear
[@@deriving sexp]

type stroke = { id : string; state : string; path : (float * float) list }
[@@deriving sexp]

type payload =
  | State of int * [ `Fast | `Normal ]
  | Ready
  | Open_speaker_notes
  | Drawing of drawing_event
  | Send_all_drawing
  | Receive_all_drawing of stroke list
[@@deriving sexp]

type t = { payload : payload } [@@deriving sexp]

let t_of_sexp_opt s =
  try Some (t_of_sexp s) with Sexplib0.Sexp.Of_sexp_error _ -> None

let of_string s =
  match Sexplib.Sexp.of_string_conv s t_of_sexp_opt with
  | `Result (Some _ as r) -> r
  | _ -> None

let to_string v = v |> sexp_of_t |> Sexplib.Sexp.to_string
