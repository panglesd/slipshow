open Drawing_state.Live_coding

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
type clear_event = unit [@@deriving yojson]

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
