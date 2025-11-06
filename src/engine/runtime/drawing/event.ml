let coord_of_event ev =
  let mouse = Brr.Ev.as_type ev |> Brr.Ev.Pointer.as_mouse in
  let x = Brr.Ev.Mouse.client_x mouse and y = Brr.Ev.Mouse.client_y mouse in
  let main =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
  in
  let offset_x = Brr.El.bound_x main in
  (x -. offset_x, y)
  |> Normalization.translate_coords |> Universe.Window.translate_coords
  (* See system.css: we add padding to be able to write on the side of the
     content. *)
  |> fun (x, y) -> (x -. 2001., y -. 2001.)

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

type pack =
  | P : 'a option * (module Tools.Stroker with type event = 'a) -> pack

let current_recording = ref None
let start_recording () = current_recording := Some (Record.start_record ())
let record event = Option.iter (Record.record event) !current_recording
let end_recording () = Option.map Record.stop_record !current_recording

let start_shape ev =
  let origin = State.get_origin () in
  let coord = coord_of_event ev in
  let state = State.get_state () in
  let id = get_id () in
  let ( let> ) x y = Option.iter y x in
  let> (P (event, (module T))) =
    match state.State.tool with
    | Stroker stroker ->
        let start_args =
          { Tools.stroker; width = state.width; color = state.color }
        in
        let event = Tools.Draw.start start_args ~id ~coord in
        Some (P (event, (module Tools.Draw)))
    | Eraser ->
        let event = Tools.Erase.start () ~id ~coord in
        Some (P (event, (module Tools.Erase)))
    | Pointer | Select | Move -> None
  in
  Hashtbl.replace current_situation origin (K (module T));
  event
  |> Option.iter @@ fun event ->
     T.send event;
     record (T.coerce_event event);
     T.execute origin event (* |> Option.iter record *)

let continue_shape ev =
  let origin = State.get_origin () in
  check_is_pressed ev @@ fun () ->
  let coord = coord_of_event ev in
  match Hashtbl.find_opt current_situation origin with
  | None -> ()
  | Some (K (module Tool)) ->
      let ev = Tool.continue ~coord in
      ev
      |> Option.iter @@ fun event ->
         Tool.send event;
         record (Tool.coerce_event event);
         Tool.execute origin event

let end_shape () =
  let origin = State.get_origin () in
  match Hashtbl.find_opt current_situation origin with
  | None -> ()
  | Some (K (module Tool)) ->
      let ev = Tool.end_ () in
      Hashtbl.remove current_situation origin;
      ev
      |> Option.iter @@ fun event ->
         Tool.send event;
         record (Tool.coerce_event event);
         Tool.execute origin event

let clear () =
  let origin = State.get_origin () in
  let ev = Tools.Clear.trigger () in
  ev
  |> Option.iter @@ fun event ->
     Tools.Clear.send event;
     (* TODO: record clear *)
     Tools.Clear.execute origin event
