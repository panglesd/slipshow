open Types
open Record

let svg =
  Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem") |> Option.get

let replay_stroke ?(speedup = 1.) (stroke : Stroke.t) =
  let start_time = now () in
  let el = Strokes.create_elem_of_stroke { stroke with path = [] } in
  Brr.El.append_children svg [ el ];
  let filter () =
    let speedup =
      match Fast.get_mode () with Normal -> speedup | _ -> 10000.
    in
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
      (Some (Jstr.v (Strokes.svg_path stroke.options stroke.scale path)))
      el;
    if finished then ()
    else
      let _animation_frame_id = Brr.G.request_animation_frame draw_loop in
      ()
  in
  let _animation_frame_id = Brr.G.request_animation_frame draw_loop in
  ()

let start_time = function
  | Stroke { path = (_, t) :: _; _ } | Erase (_, t) -> t
  | Stroke { path = []; _ } -> assert false
(* Paths cannot be empty *)
(* failwith "TODO" (\* TODO: implement *\) *)

let replay ?(speedup = 1.) (record : t (* record *)) =
  let fut, resolve_fut = Fut.create () in
  let start_replay = now () in
  let filter l speedup =
    let speedup =
      match Fast.get_mode () with Normal -> speedup | _ -> 10000.
    in
    let time_elapsed = now () -. start_replay in
    let rec loop acc = function
      | [] -> (acc, [])
      | ev :: tl when start_time ev <= speedup *. time_elapsed ->
          loop (ev :: acc) tl
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
        | Stroke s -> replay_stroke ~speedup s
        | Erase _ -> failwith "TODO" (* TODO: implement *))
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
    Brr.G.request_animation_frame (draw_loop (List.rev record))
  in
  fut

let stroke_until ~time_elapsed (stroke : Stroke.t) =
  let path = List.filter (fun (_, t) -> t <= time_elapsed) stroke.path in
  let el = Strokes.create_elem_of_stroke { stroke with path } in
  el

let draw_until ~elapsed_time (record : t) =
  List.concat_map
    (fun event ->
      let time = start_time event in
      if elapsed_time >= time then
        let time_elapsed = elapsed_time -. time in
        match event with
        | Stroke s -> [ stroke_until ~time_elapsed s ]
        | _ -> failwith "TODO" (* TODO: DO *)
      else [])
    record
