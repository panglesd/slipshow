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

let () = Random.self_init ()

let get_id =
  let id_number = ref 0 in
  let window_name = Brr.Window.name Brr.G.window |> Jstr.to_string in
  let name = "__slipshow__" ^ window_name in
  fun () ->
    let i = !id_number in
    let hash = Random.bits () |> string_of_int in
    incr id_number;
    String.concat "" [ name; string_of_int i; "_"; hash ]

type current_situation = K : (module Tools.Stroker) -> current_situation

let current_situation : (Types.origin, current_situation) Hashtbl.t =
  Hashtbl.create 10

let start origin state coord id =
  match state.State.tool with
  | Stroker stroker ->
      let () = Tools.Draw.start origin stroker ~id ~coord in
      Hashtbl.replace current_situation origin (K (module Tools.Draw))
  | Eraser -> ()
  | Pointer | Select | Move -> ()

let start_shape origin ev =
  let coord = coord_of_event ev in
  let state = State.get_state () in
  let id = get_id () in
  let () =
    let state = state |> State.to_string in
    Messaging.draw (Start { state; id; coord })
  in
  start origin state coord id

let continue origin coord =
  match Hashtbl.find_opt current_situation origin with
  | None -> ()
  | Some (K (module Tool)) ->
      let () = Tool.continue origin ~coord in
      Hashtbl.replace current_situation origin (K (module Tool))

let continue_shape origin ev =
  check_is_pressed ev @@ fun () ->
  let coord = coord_of_event ev in
  Messaging.draw (Continue { coord });
  continue origin coord

let end_ origin () =
  match Hashtbl.find_opt current_situation origin with
  | None -> ()
  | Some (K (module Tool)) ->
      Tool.end_ origin;
      Hashtbl.remove current_situation origin

let end_shape origin () =
  Messaging.draw End;
  end_ origin ()

let clear () =
  Messaging.draw Clear;
  Tools.Clear.click Self All
