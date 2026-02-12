module StringMap = Map.Make (String)
module IntMap = Map.Make (Int)

type poll = int IntMap.t StringMap.t

let json_per_poll result : Yojson.Safe.t =
  let r =
    IntMap.fold
      (fun key result acc -> `List [ `Int key; `Int result ] :: acc)
      result []
  in
  `List r

let json_to_poll json =
  try
    let res =
      match json with
      | `List l ->
          List.fold_left
            (fun acc -> function
              | `List [ `Int key; `Int result ] -> IntMap.add key result acc
              | _ -> raise Not_found)
            IntMap.empty l
      | _ -> raise Not_found
    in
    Some res
  with Not_found -> None

let poll_to_json (p : poll) =
  let r =
    StringMap.fold
      (fun key result acc -> `List [ `String key; json_per_poll result ] :: acc)
      p []
  in
  `List r

let poll_of_json json : poll option =
  try
    let res =
      match json with
      | `List l ->
          List.fold_left
            (fun acc -> function
              | `List [ `String key; result ] ->
                  StringMap.add key (json_to_poll result |> Option.get) acc
              | _ -> raise Not_found)
            StringMap.empty l
      | _ -> raise Not_found
    in
    Some res
  with Not_found | Invalid_argument _ -> None

let total_votes_per_poll = IntMap.fold (fun _key -> ( + ))
let total_votes poll = StringMap.fold (fun _key -> total_votes_per_poll) poll 0

type t =
  | Send_step of int * [ `Fast | `Normal ]
  | Poll_truth of poll
  | Vote of { id : string; vote : int }

let to_string v =
  let json : Yojson.Safe.t =
    match v with
    | Send_step (i, `Fast) -> `Assoc [ ("send_step_fast", `Int i) ]
    | Send_step (i, `Normal) -> `Assoc [ ("send_step_normal", `Int i) ]
    | Poll_truth poll ->
        `Assoc
          [
            ( "poll_truth",
              (* `String (Marshal.to_string poll []) *) poll_to_json poll );
          ]
    | Vote { id; vote } ->
        `Assoc
          [ ("poll_vote", `Assoc [ ("id", `String id); ("vote", `Int vote) ]) ]
  in
  Yojson.Safe.to_string json

let from_string json =
  let ( let* ) = Option.bind in
  let* json : Yojson.Safe.t =
    try Some (Yojson.Safe.from_string json) with _ -> None
  in
  match json with
  | `Assoc [ ("send_step_fast", `Int i) ] -> Some (Send_step (i, `Fast))
  | `Assoc [ ("send_step_normal", `Int i) ] -> Some (Send_step (i, `Normal))
  | `Assoc [ ("poll_truth", s) ] -> (
      match poll_of_json s with None -> None | Some s -> Some (Poll_truth s))
  | `Assoc [ ("poll_vote", `Assoc [ ("id", `String id); ("vote", `Int vote) ]) ]
    ->
      Some (Vote { id; vote })
  | _ -> None
