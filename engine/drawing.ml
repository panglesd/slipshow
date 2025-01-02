let current_path = ref []
let current_el = ref None
let is_pressed = ( != ) 0

let svg_path path =
  let res =
    match path with
    | [] -> []
    | (x, y) :: rest ->
        Format.sprintf "M %f,%f" x y
        :: List.map (fun (x, y) -> Format.sprintf "L %f,%f" x y) rest
  in
  String.concat " " res

let coord_of_event ev =
  let mouse = Brr.Ev.as_type ev in
  let x = Brr.Ev.Mouse.client_x mouse and y = Brr.Ev.Mouse.client_y mouse in
  (x, y) |> Normalization.translate_coords |> Window.translate_coords

let extend_shape x = current_path := x :: !current_path

let check_is_pressed ev f =
  if is_pressed (ev |> Brr.Ev.as_type |> Brr.Ev.Mouse.buttons) then f () else ()

let handle_mouse_move ev =
  Brr.Console.(log [ coord_of_event ev ]);
  check_is_pressed ev @@ fun () ->
  extend_shape (coord_of_event ev);
  match !current_el with
  | None -> ()
  | Some el ->
      Brr.El.set_at (Jstr.v "d") (Some (Jstr.v (svg_path !current_path))) el

type t = {
  mousemove : Brr.Ev.listener;
  mousedown : Brr.Ev.listener;
  mouseup : Brr.Ev.listener;
}

let start_shape svg =
  let p = Brr.El.v ~ns:`SVG (Jstr.v "path") [] in
  Brr.El.set_at (Jstr.v "stroke") (Some (Jstr.v "red")) p;
  Brr.El.set_at (Jstr.v "fill") (Some (Jstr.v "none")) p;
  current_el := Some p;
  current_path := [];
  Brr.El.append_children svg [ p ]

let end_shape () =
  current_el := None;
  current_path := []

let connect svg =
  (* let target = *)
  (*   Brr.El.find_first_by_selector (Jstr.v "#universe") *)
  (*   |> Option.get |> Brr.El.as_target *)
  (* in *)
  let mousemove =
    Brr.Ev.listen Brr.Ev.mousemove handle_mouse_move
      (Brr.Document.as_target Brr.G.document)
    (* target *)
  in
  let mousedown =
    Brr.Ev.listen Brr.Ev.mousedown
      (fun _x ->
        Brr.Console.(log [ "mouse down" ]);
        start_shape svg)
      (Brr.Document.as_target Brr.G.document)
    (* target *)
  in
  let mouseup =
    Brr.Ev.listen Brr.Ev.mouseup
      (fun _x ->
        Brr.Console.(log [ "mouse up" ]);
        end_shape ())
      (Brr.Document.as_target Brr.G.document)
    (* target *)
  in
  { mousemove; mousedown; mouseup }

let disconnect { mousemove; mousedown; mouseup } =
  Brr.Ev.unlisten mousemove;
  Brr.Ev.unlisten mousedown;
  Brr.Ev.unlisten mouseup
