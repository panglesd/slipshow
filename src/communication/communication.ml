open Sexplib.Std

type payload = State of int | Ready [@@deriving sexp]
type t = { id : string; payload : payload } [@@deriving sexp]

let t_of_sexp_opt s =
  try Some (t_of_sexp s) with Sexplib0.Sexp.Of_sexp_error _ -> None

let of_string s =
  match Sexplib.Sexp.of_string_conv s t_of_sexp_opt with
  | `Result (Some _ as r) -> r
  | _ -> None

let to_string v = v |> sexp_of_t |> Sexplib.Sexp.to_string
