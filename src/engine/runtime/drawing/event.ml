let coord_of_event ev =
  let mouse = Brr.Ev.as_type ev |> Brr.Ev.Pointer.as_mouse in
  let x = Brr.Ev.Mouse.client_x mouse and y = Brr.Ev.Mouse.client_y mouse in
  let main =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
  in
  let offset_x = Brr.El.bound_x main in
  (x -. offset_x, y)
  |> Normalization.translate_coords |> Universe.Window.translate_coords

let is_pressed = ( != ) 0

let check_is_pressed ev f =
  if
    is_pressed
      (ev |> Brr.Ev.as_type |> Brr.Ev.Pointer.as_mouse |> Brr.Ev.Mouse.buttons)
  then f ()
  else ()

let do_if_drawing f =
  match State.get_state () with { tool = Pointer; _ } -> () | state -> f state

let get_id =
  let id_number = ref 0 in
  let window_name = Brr.Window.name Brr.G.window |> Jstr.to_string in
  let name = "__slipshow__" ^ window_name in
  fun () ->
    let i = !id_number in
    let hash = Random.bits () |> string_of_int in
    incr id_number;
    String.concat "" [ name; string_of_int i; "_"; hash ]

let start_shape ev =
  do_if_drawing @@ fun state ->
  let id = get_id () in
  let coord = coord_of_event ev in
  Action.start_shape id state coord;
  let state = state |> State.to_string in
  Messaging.draw (Start { state; id; coord })

let continue_shape ev =
  check_is_pressed ev @@ fun () ->
  let coord = coord_of_event ev in
  Action.continue_shape coord;
  Messaging.draw (Continue { coord })

let end_shape () =
  Messaging.draw End;
  Action.end_shape ()

let clear () =
  Messaging.draw Clear;
  Action.clear ()
