type t = Update of string | GoForward | GoBackward

let to_string (v : t) =
  match v with
  | Update s -> s
  | GoForward -> "goforward"
  | GoBackward -> "gobackward"

let of_string s : t =
  match s with
  | "goforward" -> GoForward
  | "gobackward" -> GoBackward
  | s -> Update s
