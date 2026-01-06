let id =
  Random.self_init ();
  Random.int 10000 |> string_of_int |> fun s -> "id" ^ s

let if_parent global f =
  match Brr.Window.parent global with None -> () | Some parent -> f parent

let send_ready global () =
  if_parent global @@ fun parent ->
  let msg =
    { payload = Ready; id } |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg

let send_step global step mode =
  if_parent global @@ fun parent ->
  let msg =
    { id; payload = State (step, mode) }
    |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg

let draw global string =
  if_parent global @@ fun parent ->
  let payload = Communication.Drawing string in
  let msg = { id; payload } |> Communication.to_string |> Jv.of_string in
  Brr.Window.post_message parent ~msg

let send_all_strokes global strokes =
  if_parent global @@ fun parent ->
  let payload = Communication.Receive_all_drawing strokes in
  let msg = { id; payload } |> Communication.to_string |> Jv.of_string in
  Brr.Window.post_message parent ~msg

let open_speaker_notes global () =
  if_parent global @@ fun parent ->
  let msg =
    { id; payload = Open_speaker_notes }
    |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg

let send_speaker_notes global s =
  if_parent global @@ fun parent ->
  let msg =
    { id; payload = Speaker_notes s } |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg
