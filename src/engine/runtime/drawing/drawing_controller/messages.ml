open Drawing_state

let width_to_yojson x = `Float x
let width_of_yojson = function `Float x -> Ok x | _ -> Error ""
let color_to_yojson x = `String x
let color_of_yojson = function `String x -> Ok x | _ -> Error ""

let stroker_to_yojson (s : stroker) =
  match s with Pen -> `String "Pen" | Highlighter -> `String "Highlighter"

let stroker_of_yojson = function
  | `String "Pen" -> Ok Pen
  | `String "Highlighter" -> Ok Highlighter
  | _ -> Error ""

type 'a drag_event =
  | Start of ('a * float * float)
  | Drag of { x : float; y : float; dx : float; dy : float }
  | End
[@@deriving yojson]

type draw_stroke_arg = {
  started_time : width;
  stroker : stroker;
  color : color;
  width : width;
  id : string;
}
[@@deriving yojson]

type draw_event = draw_stroke_arg drag_event [@@deriving yojson]
type erase_arg = { started_time : float } [@@deriving yojson]
type erase_event = erase_arg drag_event [@@deriving yojson]
type clear_event = float (* = started_time *) [@@deriving yojson]

type event = Draw of draw_event | Erase of erase_event | Clear of clear_event
[@@deriving yojson]

let event_to_string ev = ev |> event_to_yojson |> Yojson.Safe.to_string

let event_of_string s =
  match Yojson.Safe.from_string s with
  | r -> event_of_yojson r
  | exception Yojson.Json_error e -> Error e

let event_of_string s =
  match event_of_string s with
  | Ok s -> Some s
  | Error e ->
      Brr.Console.(log [ "Error when converting back an erase event:"; e ]);
      None

let send event = Messaging.draw (event_to_string event)

let send_all_strokes () =
  let strokes =
    Lwd_table.fold
      (fun acc e ->
        Yojson.Safe.to_string (Drawing_state.Json.V1.of_stro e) :: acc)
      [] Drawing_state.workspaces.live_drawing
  in
  Messaging.send_all_strokes strokes

let receive_all_strokes strokes =
  let ( let* ) x f =
    match x with
    | Error s -> Brr.Console.(error [ ("Error when converting strokes", s) ])
    | Ok x -> f x
  in
  List.iter
    (fun stro ->
      let* json =
        try Ok (Yojson.Safe.from_string stro)
        with Yojson.Json_error s -> Error s
      in
      let* stro = Drawing_state.Json.V1.to_stro json in
      Lwd.set stro.track (-1);
      (* This is a hack so that strokes keep their order, even though the time
         received are relative to the main window, not relative to the receiving
         window. TODO: find a better fix *)
      Lwd_table.append' Drawing_state.workspaces.live_drawing stro)
    strokes
