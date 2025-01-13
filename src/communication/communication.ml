open Sexplib.Std

type payload = State of int | Ready [@@deriving sexp]
type t = { id : string; payload : payload } [@@deriving sexp]

let of_string s = s |> Sexplib.Sexp.of_string |> t_of_sexp
let to_string v = v |> sexp_of_t |> Sexplib.Sexp.to_string
