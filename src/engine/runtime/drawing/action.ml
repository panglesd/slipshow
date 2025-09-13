open Types

module Record = struct
  type event = Stroke of Stroke.t | Erase of unit [@@deriving yojson]

  let _ = Erase ()

  type timed_event = { event : event; time : float } [@@deriving yojson]

  type t = timed_event list [@@deriving yojson]
  (** Ordered by time *)

  type record = { start_time : float; evs : t } [@@deriving yojson]

  let of_string s = s |> Yojson.Safe.from_string |> record_of_yojson
  let to_string r = r |> record_to_yojson |> Yojson.Safe.to_string
  let current_record = ref None
  let now () = Brr.Performance.now_ms Brr.G.performance

  let add_event { start_time; evs } event starting_time =
    let time = starting_time -. start_time in
    let evs = { time; event } :: evs in
    { start_time; evs }

  let empty_record () = { start_time = now (); evs = [] }
  let start_record () = current_record := Some (empty_record ())

  let stop_record () =
    let res = !current_record in
    current_record := None;
    res

  let record event starting_time =
    match !current_record with
    | None -> ()
    | Some current_record_val ->
        current_record :=
          Some (add_event current_record_val event starting_time)
end

let svg_path options scale path =
  let path =
    List.rev_map
      (fun ((x, y), _) -> Perfect_freehand.Point.v (x *. scale) (y *. scale))
      path
  in
  let stroke = Perfect_freehand.get_stroke ~options path in
  let svg_path = Perfect_freehand.get_svg_path_from_stroke stroke in
  Jstr.to_string svg_path

let continue_shape coord =
  match !State.current_drawing_state with
  | Drawing (el, stroke, initial_time) ->
      let t = Record.now () -. initial_time in
      let stroke =
        { stroke with path = (coord, t) :: stroke.path; total_duration = t }
      in
      State.current_drawing_state := Drawing (el, stroke, initial_time);
      Brr.El.set_at (Jstr.v "d")
        (Some (Jstr.v (svg_path stroke.options stroke.scale stroke.path)))
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

let create_elem_of_stroke
    { Stroke.options; scale; color; opacity; id; path; total_duration = _ } =
  let p = Brr.El.v ~ns:`SVG (Jstr.v "path") [] in
  let set_at at v = Brr.El.set_at (Jstr.v at) (Some (Jstr.v v)) p in
  set_at "fill" (Color.to_string color);
  set_at "id" id;
  let () =
    let scale = 1. /. scale in
    let scale = string_of_float scale in
    Brr.El.set_inline_style (Jstr.v "transform")
      (Jstr.v @@ "scale3d(" ^ scale ^ "," ^ scale ^ "," ^ scale ^ ")")
      p
  in
  set_at "opacity" (string_of_float opacity);
  Brr.El.set_at (Jstr.v "d") (Some (Jstr.v (svg_path options scale path))) p;
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

let start_shape id ({ State.tool; _ } as state) coord =
  let initial_time = Record.now () in
  let svg =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
    |> Option.get
  in
  match tool with
  | Tool.Stroker stroker ->
      let opacity = match stroker with Tool.Highlighter -> 0.33 | Pen -> 1. in
      let path = [ (coord, 0.) ] in
      let options = options_of stroker state.width in
      let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
      let total_duration = 0. in
      let stroke =
        {
          Stroke.path;
          options;
          opacity;
          id;
          color = state.color;
          scale;
          total_duration;
        }
      in
      let p = create_elem_of_stroke stroke in
      State.current_drawing_state := Drawing (p, stroke, initial_time);
      Brr.El.append_children svg [ p ]
  | Eraser -> State.current_drawing_state := Erasing coord
  | Pointer -> ()

let end_shape () =
  (match !State.current_drawing_state with
  | Drawing (el, stroke, stroke_starting_time) ->
      let s = Stroke.to_string stroke in
      Brr.Console.(log [ "a stroke is: "; s ]);
      Record.record (Stroke stroke) stroke_starting_time;
      Hashtbl.add State.Strokes.all stroke.id (el, stroke)
  | _ -> ());
  State.current_drawing_state := Pointing

let clear () =
  Hashtbl.iter
    (fun _ (elem, _) -> State.Strokes.remove_el elem)
    State.Strokes.all

let () =
  let draw stroke =
    let start_time = Record.now () in
    let el = create_elem_of_stroke { stroke with path = [] } in
    let svg =
      Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
      |> Option.get
    in
    Brr.El.append_children svg [ el ];
    let filter () =
      let time_elapsed = Record.now () -. start_time in
      let rec loop acc = function
        | [] -> (acc, true)
        | ((_, t) as hd) :: tl when t <= time_elapsed -> loop (hd :: acc) tl
        | _ :: _ -> (acc, false)
      in
      loop [] (List.rev stroke.path)
    in
    let rec draw_loop _ =
      let path, finished = filter () in
      Brr.El.set_at (Jstr.v "d")
        (Some (Jstr.v (svg_path stroke.options stroke.scale path)))
        el;
      if finished then ()
      else
        let _animation_frame_id = Brr.G.request_animation_frame draw_loop in
        ()
    in
    let _animation_frame_id = Brr.G.request_animation_frame draw_loop in
    ()
  in
  let draw s =
    match s |> Jv.to_string |> Stroke.of_string with
    | Some stroke -> draw stroke
    | None -> Brr.Console.(log [ "Not a stroke" ])
  in
  let v = Jv.callback ~arity:1 draw in
  Jv.set Jv.global "draw_stroke" v

module Replay = struct
  open Record

  let replay_stroke ?(speedup = 1.) (stroke : Stroke.t) =
    Brr.Console.(log [ "Replaying stroke" ]);
    let start_time = now () in
    let el = create_elem_of_stroke { stroke with path = [] } in
    let svg =
      Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
      |> Option.get
    in
    Brr.El.append_children svg [ el ];
    let filter () =
      let time_elapsed = now () -. start_time in
      let rec loop acc = function
        | [] -> (acc, true)
        | ((_, t) as hd) :: tl when t <= speedup *. time_elapsed ->
            loop (hd :: acc) tl
        | _ :: _ -> (acc, false)
      in
      loop [] (List.rev stroke.path)
    in
    let rec draw_loop _ =
      let path, finished = filter () in
      Brr.El.set_at (Jstr.v "d")
        (Some (Jstr.v (svg_path stroke.options stroke.scale path)))
        el;
      if finished then ()
      else
        let _animation_frame_id = Brr.G.request_animation_frame draw_loop in
        ()
    in
    let _animation_frame_id = Brr.G.request_animation_frame draw_loop in
    ()

  let replay ?(speedup = 1.) (record : record) =
    let fut, resolve_fut = Fut.create () in
    let start_replay = now () in
    let filter l speedup =
      let time_elapsed = now () -. start_replay in
      let rec loop acc = function
        | [] -> (acc, [])
        | { time; event } :: tl when time <= speedup *. time_elapsed ->
            loop (event :: acc) tl
        | rest -> (acc, rest)
      in
      loop [] l
    in
    let rec draw_loop l _ =
      let speedup =
        match Fast.get_mode () with Normal -> speedup | _ -> 10000.
      in
      Brr.Console.(log [ "l has length"; List.length l ]);
      let to_draw, rest = filter l speedup in
      List.iter
        (function
          | Stroke s -> replay_stroke ~speedup s | Erase () -> failwith "TODO")
        to_draw;
      match rest with
      | [] -> resolve_fut ()
      | _ :: _ ->
          let _animation_frame_id =
            Brr.G.request_animation_frame (draw_loop rest)
          in
          ()
    in
    let _animation_frame_id =
      Brr.G.request_animation_frame (draw_loop (List.rev record.evs))
    in
    fut

  let stroke_until ~time_elapsed (stroke : Stroke.t) =
    let path = List.filter (fun (_, t) -> t <= time_elapsed) stroke.path in
    let el = create_elem_of_stroke { stroke with path } in
    el

  let draw_until ~elapsed_time (record : record) =
    List.concat_map
      (fun { event; time } ->
        if elapsed_time >= time then
          let time_elapsed = elapsed_time -. time in
          match event with
          | Stroke s -> [ stroke_until ~time_elapsed s ]
          | _ -> failwith "TODO" (* TODO: DO *)
        else [])
      record.evs
end
