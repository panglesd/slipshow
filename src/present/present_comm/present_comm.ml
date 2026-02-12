type t = Send_step of int

let to_string v =
  let json : Yojson.Safe.t =
    match v with Send_step i -> `Assoc [ ("send_step", `Int i) ]
  in
  Yojson.Safe.to_string json

let from_string json =
  let ( let* ) = Option.bind in
  let* json : Yojson.Safe.t =
    try Some (Yojson.Safe.from_string json) with _ -> None
  in
  match json with
  | `Assoc [ ("send_step", `Int i) ] -> Some (Send_step i)
  | _ -> None
