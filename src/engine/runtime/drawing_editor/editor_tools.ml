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

  let timeline recording stroke_height =
    let box_selection_var = Lwd.var None in
    let ev =
      let select_of_coords ?pre container ~x ~dx ~y ~dy ev =
        let x, dx =
          let total_length = Lwd.peek recording.total_time in
          let width_in_pixel = Brr.El.bound_w container in
          let scale = total_length /. width_in_pixel in
          (x *. scale, dx *. scale)
        in
        let y, y' =
          ( int_of_float y / stroke_height,
            int_of_float (y +. dy) / stroke_height )
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
        let position_var = Lwd.var (x, y, 0., 0.) in
        Lwd.set box_selection_var (Some position_var);
        (x, y, container, position_var)
      in
      let drag ~dx ~dy (x, y, container, position_var) ev =
        let x, dx = if dx < 0. then (x +. dx, -.dx) else (x, dx) in
        let y, dy = if dy < 0. then (y +. dy, -.dy) else (y, dy) in
        select_of_coords container ~pre:true ~x ~y ~dx ~dy ev;
        Lwd.set position_var (x, y, dx, dy)
      in
      let end_ (_, _, container, position_var) ev =
        let x, y, dx, dy = Lwd.peek position_var in
        Lwd_table.iter
          (fun { preselected; _ } -> Lwd.set preselected false)
          recording.strokes;
        select_of_coords container ~x ~y ~dx ~dy ev;
        Lwd.set box_selection_var None
      in
      Ui_widgets.mouse_drag start drag end_
    in
    let box =
      let$ box_selection = Lwd.get box_selection_var in
      match box_selection with
      | None -> Lwd_seq.empty
      | Some var ->
          let st =
            let x =
              let$ x, _, _, _ = Lwd.get var in
              (Brr.El.Style.left, px_float x)
            in
            let y =
              let$ _, y, _, _ = Lwd.get var in
              (Brr.El.Style.top, px_float y)
            in
            let dx =
              let$ _, _, dx, _ = Lwd.get var in
              (Brr.El.Style.width, px_float dx)
            in
            let dy =
              let$ _, _, _, dy = Lwd.get var in
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
    in
    (Lwd_seq.lift box, ev)
end
