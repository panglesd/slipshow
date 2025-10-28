open Types
open Record

let start_time = function _, t -> t

let replay ?(speedup = 1.) (record : t (* record *)) =
  let fut, resolve_fut = Fut.create () in
  let start_replay = now () in
  let filter l speedup =
    let speedup =
      match Fast.get_mode () with Normal -> speedup | _ -> 10000.
    in
    let time_elapsed = now () -. start_replay in
    let rec loop acc = function
      | [] -> (List.rev acc, [])
      | ev :: tl when start_time ev <= speedup *. time_elapsed ->
          loop (ev :: acc) tl
      | rest -> (List.rev acc, rest)
    in
    loop [] l
  in
  let rec draw_loop l _ =
    let speedup =
      match Fast.get_mode () with Normal -> speedup | _ -> 10000.
    in
    let to_draw, rest = filter l speedup in
    List.iter
      (function
        | `Draw ev, _ -> Tools.Draw.execute (Record record.record_id) ev
        | `Erase ev, _ -> Tools.Erase.execute (Record record.record_id) ev
        | `Clear ev, _ -> Tools.Clear.execute (Record record.record_id) ev)
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
    Brr.G.request_animation_frame (draw_loop (List.rev record.events))
  in
  fut
