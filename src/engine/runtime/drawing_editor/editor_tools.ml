open State_types
open Lwd_infix

let very_quick_sample g =
  let root = Lwd.observe g in
  let res = Lwd.quick_sample root in
  Lwd.quick_release root;
  res

let ( !! ) = Jstr.v
let px_float x = Jstr.append (Jstr.of_float x) !!"px"

module Selection = struct
  let select ?(pre = false) t0 t1 track0 track1 recording mode =
    Lwd_table.iter
      (fun { end_at; starts_at; selected; preselected; track; _ } ->
        let end_at = very_quick_sample end_at in
        let starts_at = very_quick_sample starts_at in
        let track = Lwd.peek track in
        let is_selected =
          track0 <= track && track <= track1 && t0 <= end_at && starts_at <= t1
        in
        let var = if pre then preselected else selected in
        let is_selected =
          match mode with
          | `Replace -> is_selected
          | `Add -> is_selected || Lwd.peek var
          | `Toggle ->
              let xor a b = (a && not b) || ((not a) && b) in
              xor is_selected (Lwd.peek var)
        in
        Lwd.set var is_selected)
      recording.strokes

  let box_selection_var = Lwd.var None

  let timeline_event recording stroke_height =
    let select_of_coords ?pre container ~x ~dx ~y ~dy ev =
      let x, dx =
        let total_length = Lwd.peek recording.total_time in
        let width_in_pixel = Brr.El.bound_w container in
        let scale = total_length /. width_in_pixel in
        (x *. scale, dx *. scale)
      in
      let y, y' =
        (int_of_float y / stroke_height, int_of_float (y +. dy) / stroke_height)
      in
      let mode =
        let mouse_ev = Brr.Ev.as_type ev in
        if Brr.Ev.Mouse.shift_key mouse_ev then `Add
        else if Brr.Ev.Mouse.ctrl_key mouse_ev then `Toggle
        else `Replace
      in
      select ?pre x (x +. dx) y y' recording mode
    in
    let start x y ev =
      (* It would be nice to just pass the event itself, but outside of the
           event handler the current target may be [null] unfortunately stupid
           programming language... See
           https://developer.mozilla.org/en-US/docs/Web/API/Event/currentTarget *)
      let container =
        ev |> Brr.Ev.current_target |> Brr.Ev.target_to_jv |> Brr.El.of_jv
      in
      let x = x -. Brr.El.bound_x container in
      let y = y -. Brr.El.bound_y container in
      let position_var = (Lwd.var x, Lwd.var y, Lwd.var 0., Lwd.var 0.) in
      Lwd.set box_selection_var (Some position_var);
      (x, y, container, position_var)
    in
    let drag ~dx ~dy (x, y, container, (vx, vy, vdx, vdy)) ev =
      let x, dx = if dx < 0. then (x +. dx, -.dx) else (x, dx) in
      let y, dy = if dy < 0. then (y +. dy, -.dy) else (y, dy) in
      select_of_coords container ~pre:true ~x ~y ~dx ~dy ev;
      Lwd.set vx x;
      Lwd.set vy y;
      Lwd.set vdx dx;
      Lwd.set vdy dy
    in
    let end_ (_, _, container, (x, y, dx, dy)) ev =
      let x, y, dx, dy = (Lwd.peek x, Lwd.peek y, Lwd.peek dx, Lwd.peek dy) in
      Lwd_table.iter
        (fun { preselected; _ } -> Lwd.set preselected false)
        recording.strokes;
      select_of_coords container ~x ~y ~dx ~dy ev;
      Lwd.set box_selection_var None
    in
    Ui_widgets.mouse_drag start drag end_

  let box =
    let$ box_selection = Lwd.get box_selection_var in
    match box_selection with
    | None -> Lwd_seq.empty
    | Some (x, y, dx, dy) ->
        let st =
          let x =
            let$ x = Lwd.get x in
            (Brr.El.Style.left, px_float x)
          in
          let y =
            let$ y = Lwd.get y in
            (Brr.El.Style.top, px_float y)
          in
          let dx =
            let$ dx = Lwd.get dx in
            (Brr.El.Style.width, px_float dx)
          in
          let dy =
            let$ dy = Lwd.get dy in
            (Brr.El.Style.height, px_float dy)
          in
          [
            `R x;
            `R y;
            `R dx;
            `R dy;
            `P (Brr.El.Style.background_color, !!"lightgray");
            `P (!!"opacity", !!"0.5");
            `P (!!"border", !!"1px solid black");
            `P (Brr.El.Style.position, !!"absolute");
          ]
        in
        let div = Brr_lwd.Elwd.div ~st [] in
        Lwd_seq.element div

  let box = Lwd_seq.lift box
end

module Move = struct
  let move time_shift track_shift strokes =
    List.iter
      (fun (old_path, old_track, stroke) ->
        let new_track = Int.max 0 (old_track + track_shift) in
        Lwd.set stroke.track new_track;
        let new_path = Path_editing.translate old_path time_shift in
        Lwd.set stroke.path new_path)
      strokes

  let timeline_event recording stroke_height =
    let ev =
      let translate_of_coords strokes container ~dx ~dy =
        let time_shift =
          let total_length = Lwd.peek recording.total_time in
          let width_in_pixel = Brr.El.bound_w container in
          let scale = total_length /. width_in_pixel in
          dx *. scale
        in
        let track_shift = int_of_float dy / stroke_height in
        move time_shift track_shift strokes
      in
      let start _x _y ev =
        let strokes =
          Lwd_table.fold
            (fun acc stroke ->
              if not (Lwd.peek stroke.selected) then acc
              else (Lwd.peek stroke.path, Lwd.peek stroke.track, stroke) :: acc)
            [] recording.strokes
        in
        let el =
          ev |> Brr.Ev.current_target |> Brr.Ev.target_to_jv |> Brr.El.of_jv
        in
        (strokes, el)
      in
      let drag ~dx ~dy (strokes, container) _ev =
        translate_of_coords strokes container ~dx ~dy
      in
      let end_ _ _ = () in
      Ui_widgets.mouse_drag start drag end_
    in
    ev
end
