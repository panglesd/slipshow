let now global () =
  let performance =
    Jv.get (Brr.Window.to_jv global) "performance" |> Brr.Performance.of_jv
  in
  Brr.Performance.now_ms performance

open Drawing_state
open Messages

let very_quick_sample g =
  let root = Lwd.observe g in
  let res = Lwd.quick_sample root in
  Lwd.quick_release root;
  res

let ( !! ) = Jstr.v
let px_float x = Jstr.append (Jstr.of_float x) !!"px"

let window_coord_in_universe x y =
  let main =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
  in
  let offset_x = Brr.El.bound_x main in
  (x -. offset_x, y)
  |> Normalization.translate_coords |> Universe.Window.translate_coords
  (* See system.css: we add padding to be able to write on the side of the
     content. *)
  |> fun (x, y) -> (x -. 2000., y -. 2000.)

let mouse_drag_in_universe global start drag end_ =
  let start x y =
    let x, y = window_coord_in_universe x y in
    start x y
  in
  let drag ~x ~y ~dx ~dy =
    let x', y' = (x +. dx, y +. dy) in
    let x, y = window_coord_in_universe x y in
    let x', y' = window_coord_in_universe x' y' in
    let dx, dy = (x' -. x, y' -. y) in
    drag ~x ~y ~dx ~dy
  in
  Ui_widgets.mouse_drag global start drag end_

module Draw_stroke = struct
  let starts_at l = List.hd (List.rev l) |> snd
  let end_at l = List.hd l |> snd

  let start global ~replaying_state:_ strokes
      { started_time; stroker; color; width; id } x y =
    let now = now global in
    let path = [ ((x, y), now () -. started_time) ] in
    let el =
      let path = Lwd.var path in
      let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
      let end_at = Lwd.map (Lwd.get path) ~f:end_at in
      let starts_at = Lwd.map (Lwd.get path) ~f:starts_at in
      {
        id;
        scale;
        path;
        end_at;
        starts_at;
        color = Lwd.var color;
        stroker;
        width = Lwd.var width;
        selected = Lwd.var false;
        preselected = Lwd.var false;
        track = Lwd.var 0;
        erased = Lwd.var None;
      }
    in
    Lwd_table.append' strokes el;
    (started_time, el)

  let drag global ~x ~y ~dx ~dy ((started_time, el) as acc) =
    let now = now global in
    let path = Lwd.peek el.path in
    let path = ((x +. dx, y +. dy), now () -. started_time) :: path in
    Lwd.set el.path path;
    acc

  let end_ _ = ()

  let event global ~started_time strokes stroker color width =
    let start x y _ev =
      let id =
        "id" ^ (Random.int 429496729 |> string_of_int)
        (* TODO: id *)
      in
      let arg = { started_time; stroker; color; width; id } in
      Messages.send global @@ Draw (Start (arg, x, y));
      start global ~replaying_state:None strokes arg x y
    in
    let drag ~x ~y ~dx ~dy acc _ev =
      Messages.send global @@ Draw (Drag { x; y; dx; dy });
      drag global ~x ~y ~dx ~dy acc
    in
    let end_ acc _ev =
      Messages.send global @@ Draw End;
      end_ acc
    in
    mouse_drag_in_universe global start drag end_
end

module Erase = struct
  let start ~replayed_strokes strokes { started_time } x y =
    (started_time, strokes, replayed_strokes, (x, y))

  let drag global ~x ~y ~dx ~dy (started_time, strokes, replayed_strokes, c0) =
    let now = now global in
    let c1 = (x +. dx, y +. dy) in
    let try_erase stro time =
      let time = Option.value ~default:Float.infinity time in
      match Lwd.peek stro.erased with
      | Some { at; _ } when Lwd.peek at <= time -> ()
      | _ ->
          let path = Lwd.peek stro.path in
          let intersect =
            Drawing_state.Path_editing.intersect_poly2 path time (c0, c1)
          in
          let close_enough =
            let { Universe.Coordinates.scale; _ } =
              Universe.State.get_coord ()
            in
            Drawing_state.Path_editing.close_enough_poly2 scale path c1
          in
          if intersect || close_enough then
            Lwd.set stro.erased
              (Some
                 {
                   at =
                     Lwd.var
                       (Float.max
                          (List.hd path |> snd)
                          (now () -. started_time));
                   track = Lwd.var (Lwd.peek stro.track);
                   selected = Lwd.var false;
                   preselected = Lwd.var false;
                 })
          else ()
    in
    let _strokes_to_erase =
      Lwd_table.iter (fun stro -> try_erase stro None) strokes
    in
    let _strokes_to_erase =
      replayed_strokes
      |> Option.iter
         @@ Lwd_table.iter (fun (stro : stro) -> try_erase stro None)
    in
    (started_time, strokes, replayed_strokes, c1)

  let end_ _ = ()

  let event global ~started_time ~replayed_strokes strokes =
    let start x y _ev =
      Messages.send global @@ Erase (Start ({ started_time }, x, y));
      start ~replayed_strokes strokes { started_time } x y
    in
    let drag ~x ~y ~dx ~dy acc _ev =
      Messages.send global @@ Erase (Drag { x; y; dx; dy });
      drag global ~x ~y ~dx ~dy acc
    in
    let end_ acc _ev =
      Messages.send global @@ Erase End;
      end_ acc
    in
    mouse_drag_in_universe global start drag end_
end

module Clear = struct
  let clear global ~replayed_strokes started_time strokes =
    let now = now global in
    let clear strokes =
      Lwd_table.iter
        (fun stro ->
          if Lwd.peek stro.erased |> Option.is_some then ()
          else
            let path = Lwd.peek stro.path in
            Lwd.set stro.erased
              (Some
                 {
                   at =
                     Lwd.var
                       (Float.max
                          (List.hd path |> snd)
                          (now () -. started_time));
                   track = Lwd.var (Lwd.peek stro.track);
                   selected = Lwd.var false;
                   preselected = Lwd.var false;
                 }))
        strokes
    in
    clear strokes;
    Option.iter clear replayed_strokes

  let event global ~replayed_strokes started_time strokes =
    Messages.send global (Clear started_time);
    clear global ~replayed_strokes started_time strokes
end
