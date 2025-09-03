open Types

let svg_path options path =
  let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
  let path =
    List.rev_map
      (fun (x, y) -> Perfect_freehand.Point.v (x *. scale) (y *. scale))
      path
  in
  let stroke = Perfect_freehand.get_stroke ~options path in
  let svg_path = Perfect_freehand.get_svg_path_from_stroke stroke in
  Jstr.to_string svg_path

let coord_of_event ev =
  let mouse = Brr.Ev.as_type ev |> Brr.Ev.Pointer.as_mouse in
  let x = Brr.Ev.Mouse.client_x mouse and y = Brr.Ev.Mouse.client_y mouse in
  (x, y) |> Normalization.translate_coords |> Universe.Window.translate_coords

let get_id =
  let id_number = ref 0 in
  let window_name = Brr.Window.name Brr.G.window |> Jstr.to_string in
  let name = "__slipshow__" ^ window_name in
  fun () ->
    let i = !id_number in
    incr id_number;
    name ^ string_of_int i

let is_pressed = ( != ) 0

let check_is_pressed ev f =
  if
    is_pressed
      (ev |> Brr.Ev.as_type |> Brr.Ev.Pointer.as_mouse |> Brr.Ev.Mouse.buttons)
  then f ()
  else ()

let do_if_drawing f =
  match State.get_state () with { tool = Pointer; _ } -> () | state -> f state

let continue_shape_func coord =
  match !State.current_drawing_state with
  | Drawing (el, stroke) ->
      let stroke = { stroke with path = coord :: stroke.path } in
      State.current_drawing_state := Drawing (el, stroke);
      Brr.El.set_at (Jstr.v "d")
        (Some (Jstr.v (svg_path stroke.options stroke.path)))
        el
  | Erasing last_point ->
      Hashtbl.iter
        (fun _id (elem, { Stroke.path; _ }) ->
          let intersect = Utils.intersect_poly path (coord, last_point) in
          let close_enough = Utils.close_enough_poly path coord in
          if intersect || close_enough then State.Strokes.remove_el elem)
        State.Strokes.all;
      State.current_drawing_state := Erasing coord;
      ()
  | Pointing -> ()

let continue_shape ev =
  check_is_pressed ev @@ fun () ->
  let coord = coord_of_event ev in
  continue_shape_func coord;
  Messaging.draw (Continue { coord })

let create_elem_of_stroke { Stroke.options; color; opacity; id; path } =
  let p = Brr.El.v ~ns:`SVG (Jstr.v "path") [] in
  let set_at at v = Brr.El.set_at (Jstr.v at) (Some (Jstr.v v)) p in
  set_at "fill" (Color.to_string color);
  set_at "id" id;
  let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
  let scale = 1. /. scale in
  Brr.El.set_inline_style (Jstr.v "transform")
    (Jstr.v @@ Format.sprintf "scale3d(%.10f,%.10f,%.10f)" scale scale scale)
    p;
  set_at "opacity" (string_of_float opacity);
  Brr.El.set_at (Jstr.v "d") (Some (Jstr.v (svg_path options path))) p;
  p

let options_of stroke width =
  let size =
    match (stroke, width) with
    | Tool.Pen, Width.Small -> 6.
    | Pen, Medium -> 10.
    | Pen, Large -> 14.
    | Highlighter, Small -> 28.
    | Highlighter, Medium -> 38.
    | Highlighter, Large -> 48.
  in
  Perfect_freehand.Options.v ~thinning:0.3 ~smoothing:0.5 ~size ~streamline:0.05
    ~last:false ()

let start_shape_func id ({ State.tool; _ } as state) coord =
  let svg =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
    |> Option.get
  in
  match tool with
  | Tool.Stroker stroker ->
      let opacity = match stroker with Tool.Highlighter -> 0.33 | Pen -> 1. in
      let path = [ coord ] in
      let options = options_of stroker state.width in
      let stroke = { Stroke.path; options; opacity; id; color = state.color } in
      let p = create_elem_of_stroke stroke in
      State.current_drawing_state := Drawing (p, stroke);
      Brr.El.append_children svg [ p ]
  | Eraser -> State.current_drawing_state := Erasing coord
  | Pointer -> ()

let start_shape _svg ev =
  do_if_drawing @@ fun state ->
  let id = get_id () in
  let coord = coord_of_event ev in
  start_shape_func id state coord;
  let state = state |> State.to_string in
  Messaging.draw (Start { state; id; coord })

let end_shape_func _attrs =
  (match !State.current_drawing_state with
  | Drawing (el, stroke) -> Hashtbl.add State.Strokes.all stroke.id (el, stroke)
  | _ -> ());
  State.current_drawing_state := Pointing

let end_shape () =
  do_if_drawing @@ fun attrs ->
  let state = attrs |> State.to_string in
  Messaging.draw (End { state });
  end_shape_func attrs

let clear_func () =
  Hashtbl.iter
    (fun _ (elem, _) -> State.Strokes.remove_el elem)
    State.Strokes.all

let clear () =
  Messaging.draw Clear;
  clear_func ()
