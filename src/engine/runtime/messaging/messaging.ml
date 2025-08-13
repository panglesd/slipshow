let if_parent f =
  match Brr.Window.parent Brr.G.window with
  | None -> ()
  | Some parent -> f parent

let send_ready () =
  if_parent @@ fun parent ->
  let msg = { payload = Ready } |> Communication.to_string |> Jv.of_string in
  Brr.Window.post_message parent ~msg

let send_step step mode =
  if_parent @@ fun parent ->
  let msg =
    { payload = State (step, mode) } |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg

let draw draw_payload =
  if_parent @@ fun parent ->
  let payload = Communication.Drawing draw_payload in
  let msg = { payload } |> Communication.to_string |> Jv.of_string in
  Brr.Window.post_message parent ~msg

let send_all_strokes strokes =
  if_parent @@ fun parent ->
  let payload = Communication.Receive_all_drawing strokes in
  let msg = { payload } |> Communication.to_string |> Jv.of_string in
  Brr.Window.post_message parent ~msg

let send_speaker_notes () =
  if_parent @@ fun parent ->
  let msg =
    { payload = Open_speaker_notes } |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg
