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
  let select ~epsilon ?(pre = false) t0 t1 track0 track1 recording mode =
    Lwd_table.iter
      (fun { end_at; starts_at; selected; preselected; track; erased; _ } ->
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
        Lwd.set var is_selected;
        let () =
          match Lwd.peek erased with
          | None -> ()
          | Some { at; selected; preselected; track } ->
              let at = Lwd.peek at in
              let erase_selected_var = if pre then preselected else selected in
              let track = Lwd.peek track in
              let is_selected =
                track0 <= track && track <= track1
                && t0 -. epsilon <= at
                && at <= t1 +. epsilon
                (* For erase we are more lenient as they are discrete *)
              in
              let is_selected =
                match mode with
                | `Replace -> is_selected
                | `Add -> is_selected || Lwd.peek erase_selected_var
                | `Toggle ->
                    let xor a b = (a && not b) || ((not a) && b) in
                    xor is_selected (Lwd.peek erase_selected_var)
              in
              Lwd.set erase_selected_var is_selected
        in
        ())
      recording.strokes

  let box_selection_var = Lwd.var None

  let timeline_event recording ~stroke_height =
    let select_of_coords ?pre container ~x ~dx ~y ~dy ev =
      let total_length = Lwd.peek recording.total_time in
      let width_in_pixel = Brr.El.bound_w container in
      let scale = total_length /. width_in_pixel in
      let x, dx = (x *. scale, dx *. scale) in
      let y, y' =
        (int_of_float y / stroke_height, int_of_float (y +. dy) / stroke_height)
      in
      let epsilon = 10. *. scale in
      let mode =
        let mouse_ev = Brr.Ev.as_type ev in
        if Brr.Ev.Mouse.shift_key mouse_ev then `Add
        else if Brr.Ev.Mouse.ctrl_key mouse_ev then `Toggle
        else `Replace
      in
      select ~epsilon ?pre x (x +. dx) y y' recording mode
    in
    let start x y ev =
      (* It would be nice to just pass the event itself, but outside of the
         event handler the current target may be [null] unfortunately, stupid
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
        (fun { preselected; erased; _ } ->
          Lwd.set preselected false;
          Option.iter
            (fun (v : erased) -> Lwd.set v.preselected false)
            (Lwd.peek erased))
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
  let move recording time_shift track_shift strokes =
    let total_length = Lwd.peek recording.total_time in
    List.iter
      (function
        | `Stroke (old_path, old_track, stroke, erase) ->
            let new_track = Int.max 0 (old_track + track_shift) in
            Lwd.set stroke.track new_track;
            let end_ = snd (List.hd old_path) in
            let start = snd (List.hd (List.rev old_path)) in
            let time_shift = Float.min time_shift (total_length -. end_) in
            let time_shift = Float.max time_shift (0. -. start) in
            let () =
              erase
              |> Option.iter @@ fun e ->
                 if Lwd.peek e.at < end_ +. time_shift then
                   Lwd.set e.at (end_ +. time_shift)
            in
            let new_path = Path_editing.translate old_path time_shift in
            Lwd.set stroke.path new_path
        | `Erase (old_t, old_track, (sel : erased), stroke) ->
            let new_track = Int.max 0 (old_track + track_shift) in
            let time_shift = Float.min time_shift (total_length -. old_t) in
            let end_at = very_quick_sample stroke.end_at in
            let time_shift = Float.max time_shift (end_at -. old_t) in
            Lwd.set sel.track new_track;
            Lwd.set sel.at (old_t +. time_shift);
            ())
      strokes

  let timeline_event recording ~stroke_height =
    let translate_of_coords strokes container ~dx ~dy =
      let time_shift =
        let total_length = Lwd.peek recording.total_time in
        let width_in_pixel = Brr.El.bound_w container in
        let scale = total_length /. width_in_pixel in
        dx *. scale
      in
      let track_shift = int_of_float dy / stroke_height in
      move recording time_shift track_shift strokes
    in
    let start _x _y ev =
      let strokes =
        Lwd_table.fold
          (fun acc stroke ->
            let s =
              if not (Lwd.peek stroke.selected) then []
              else
                [
                  `Stroke
                    ( Lwd.peek stroke.path,
                      Lwd.peek stroke.track,
                      stroke,
                      Lwd.peek stroke.erased );
                ]
            in
            let sel =
              match Lwd.peek stroke.erased with
              | Some sel when Lwd.peek sel.selected ->
                  [ `Erase (Lwd.peek sel.at, Lwd.peek sel.track, sel, stroke) ]
              | _ -> []
            in
            s @ sel @ acc)
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

  let drawing_event recording =
    let start _x _y _ev =
      Lwd_table.fold
        (fun acc s ->
          if Lwd.peek s.selected then (Lwd.peek s.path, s.path) :: acc else acc)
        [] recording.strokes
    in
    let drag ~dx ~dy paths _ev =
      List.iter
        (fun (p, v) -> Lwd.set v (Path_editing.translate_space p dx dy))
        paths
    in
    let end_ _ _ev = () in
    Ui_widgets.mouse_drag start drag end_
end
