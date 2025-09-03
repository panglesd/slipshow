open Types
module Width = Width
module Tool = Tool
module Color = Color
module State = State
module Stroke = Stroke
module Event = Event

let send_all_strokes () =
  let all_strokes =
    Hashtbl.fold
      (fun _ (_, stroke) acc -> Stroke.to_string stroke :: acc)
      State.Strokes.all []
  in
  Messaging.send_all_strokes all_strokes

let receive_all_strokes all_strokes =
  List.iter
    (fun s ->
      match Stroke.of_string s with
      | None -> ()
      | Some stroke ->
          let el = Event.create_elem_of_stroke stroke in
          Hashtbl.add State.Strokes.all stroke.id (el, stroke);
          let svg =
            Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
            |> Option.get
          in
          Brr.El.append_children svg [ el ])
    all_strokes

let setup = Setup.setup
