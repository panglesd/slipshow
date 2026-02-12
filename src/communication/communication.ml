open Sexplib.Std

type payload =
  | State of int * [ `Fast | `Normal ]
  | Ready
  | Set_state of int
  | Open_speaker_notes
  | Close_speaker_notes
  | Speaker_notes of string
  | Drawing of string
  | Send_all_drawing
  | Receive_all_drawing of string list
[@@deriving sexp]

type t = { payload : payload; id : string } [@@deriving sexp]

let t_of_sexp_opt s =
  try Some (t_of_sexp s) with Sexplib0.Sexp.Of_sexp_error _ -> None

let of_string s =
  match Sexplib.Sexp.of_string_conv s t_of_sexp_opt with
  | `Result (Some _ as r) -> r
  | _ -> None

let to_string v = v |> sexp_of_t |> Sexplib.Sexp.to_string
