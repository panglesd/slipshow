module Types = Types
open Types
module Width = Width
module Tool = Tool
module Color = Color
module State = State
module Stroke = Stroke
module Event = Event
module Tools = Tools
module Record = Record
module Replay = Replay
module Strokes = Strokes
module Utils = Utils

let to_string (stroke, origin) =
  Yojson.Safe.to_string
    (`List
       [ `String (origin_to_string origin); `String (Stroke.to_string stroke) ])

let of_string s =
  match Yojson.Safe.from_string s with
  | `List [ `String origin; `String stroke ] ->
      let ( let* ) = Option.bind in
      let* origin = origin_of_string origin in
      let* stroke = Stroke.of_string stroke in
      Some (stroke, origin)
  | _ -> None
  | exception Yojson.Json_error _ -> None

let send_all_strokes () =
  let all_strokes =
    Hashtbl.fold
      (fun _ { State.Strokes.stroke; origin; _ } acc ->
        to_string (stroke, origin) :: acc)
      State.Strokes.all []
  in
  Messaging.send_all_strokes all_strokes

let receive_all_strokes all_strokes =
  List.iter
    (fun s ->
      match of_string s with
      | None -> ()
      | Some (stroke, origin) ->
          let element = Strokes.create_elem_of_stroke stroke in
          Hashtbl.add State.Strokes.all stroke.id { element; stroke; origin };
          let svg =
            Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
            |> Option.get
          in
          Brr.El.append_children svg [ element ])
    all_strokes

let setup = Setup.setup
