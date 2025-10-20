let id =
  Random.self_init ();
  Random.int 10000 |> string_of_int |> fun s -> "id" ^ s

let if_parent f =
  match Brr.Window.parent Brr.G.window with
  | None -> ()
  | Some parent -> f parent

let send_ready () =
  if_parent @@ fun parent ->
  let msg =
    { payload = Ready; id } |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg

let send_step step mode =
  if_parent @@ fun parent ->
  let msg =
    { id; payload = State (step, mode) }
    |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg

module Draw_event = struct
  type t = Draw of string | Erase of string [@@deriving yojson]

  let to_string d = d |> to_yojson |> Yojson.Safe.to_string

  let of_string s =
    match Yojson.Safe.from_string s with
    | r -> of_yojson r
    | exception Yojson.Json_error e -> Error e

  let of_string s =
    match of_string s with
    | Ok s -> Some s
    | Error e ->
        Brr.Console.(log [ "Error when converting back a draw event:"; e; s ]);
        None
end

let draw draw_payload =
  if_parent @@ fun parent ->
  let draw_payload = Draw_event.to_string draw_payload in
  let payload = Communication.Drawing draw_payload in
  let msg = { id; payload } |> Communication.to_string |> Jv.of_string in
  Brr.Window.post_message parent ~msg

let send_all_strokes strokes =
  if_parent @@ fun parent ->
  let payload = Communication.Receive_all_drawing strokes in
  let msg = { id; payload } |> Communication.to_string |> Jv.of_string in
  Brr.Window.post_message parent ~msg

let open_speaker_notes () =
  if_parent @@ fun parent ->
  let msg =
    { id; payload = Open_speaker_notes }
    |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg

let send_speaker_notes s =
  if_parent @@ fun parent ->
  let msg =
    { id; payload = Speaker_notes s } |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg
