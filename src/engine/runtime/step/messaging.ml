let id = ref None
let set_id i = id := i
let if_id f = match !id with None -> () | Some id -> f id

let if_parent f =
  match Brr.Window.parent Brr.G.window with
  | None -> ()
  | Some parent -> f parent

let send_ready () =
  if_id @@ fun id ->
  if_parent @@ fun parent ->
  let msg =
    { Communication.id; payload = Ready }
    |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg

let send_step () =
  if_id @@ fun id ->
  if_parent @@ fun parent ->
  let step = State.get_step () in
  let msg =
    { Communication.id; payload = State step }
    |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg

let send_speaker_notes () =
  if_id @@ fun id ->
  if_parent @@ fun parent ->
  let msg =
    { Communication.id; payload = Open_speaker_notes }
    |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message parent ~msg
