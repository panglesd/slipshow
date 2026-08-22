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

let send payload =
  if_parent @@ fun parent ->
  let msg = { id; payload } |> Communication.to_string |> Jv.of_string in
  Brr.Window.post_message parent ~msg

let draw string = send (Drawing string)
let send_all_strokes strokes = send (Receive_all_drawing strokes)
let save_drawing ~path ~content = send (Save_drawing (path, content))
let open_speaker_notes () = send Open_speaker_notes
let send_speaker_notes s = send (Speaker_notes s)
let opened_recording_panel () = send Open_recording_panel
let closed_recording_panel () = send Close_recording_panel

let send_gui_coordinate id (coord : Actions_arguments.Gui.t) =
  send
    (SaveCoordinates
       {
         x = coord.x;
         y = coord.y;
         scale = coord.scale;
         w = coord.width;
         h = coord.height;
         id;
       })

let send_loc loc = send (GotoLoc loc)
