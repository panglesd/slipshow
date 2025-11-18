open Drawing_state.Live_coding
open Lwd_infix

let very_quick_sample g =
  let root = Lwd.observe g in
  let res = Lwd.quick_sample root in
  Lwd.quick_release root;
  res

let ( !! ) = Jstr.v
let px_float x = Jstr.append (Jstr.of_float x) !!"px"

module Selection = struct
  let promote mode ~selected ~preselected =
    let new_value =
      let selected = Lwd.peek selected and preselected = Lwd.peek preselected in
      match mode with
      | `Replace -> preselected
      | `Add -> selected || preselected
      | `Toggle ->
          let xor a b = (a && not b) || ((not a) && b) in
          xor selected preselected
    in
    Lwd.set selected new_value;
    Lwd.set preselected false

  let promote mode recording =
    Lwd_table.iter
      (fun { selected; preselected; erased; _ } ->
        promote mode ~selected ~preselected;
        Option.iter
          (fun ({ selected; preselected; _ } : erased) ->
            promote mode ~selected ~preselected)
          (Lwd.peek erased))
      recording.strokes

  module Timeline = struct
    let select ~epsilon t0 t1 track0 track1 recording =
      Lwd_table.iter
        (fun { end_at; starts_at; preselected; track; erased; _ } ->
          let end_at = very_quick_sample end_at in
          let starts_at = very_quick_sample starts_at in
          let track = Lwd.peek track in
          let is_selected =
            track0 <= track && track <= track1 && t0 <= end_at
            && starts_at <= t1
          in
          Lwd.set preselected is_selected;
          let () =
            match Lwd.peek erased with
            | None -> ()
            | Some { at; preselected; track; _ } ->
                let at = Lwd.peek at in
                let track = Lwd.peek track in
                let is_selected =
                  track0 <= track && track <= track1
                  && t0 -. epsilon <= at
                  && at <= t1 +. epsilon
                  (* For erase we are more lenient as they are discrete *)
                in
                Lwd.set preselected is_selected
          in
          ())
        recording.strokes

    let box_selection_var = Lwd.var None

    let translate_timeline_coord container recording =
      let total_length = Lwd.peek recording.total_time in
      let width_in_pixel = Brr.El.bound_w container in
      let scale = total_length /. width_in_pixel in
      fun x -> x *. scale

    let event recording ~stroke_height =
      let select_of_coords container ~x ~dx ~y ~dy =
        let t = translate_timeline_coord container recording in
        let x, dx = (t x, t dx) in
        let y, y' =
          ( int_of_float y / stroke_height,
            int_of_float (y +. dy) / stroke_height )
        in
        let epsilon = t 10. in
        select ~epsilon x (x +. dx) y y' recording
      in
      let start x y ev =
        let container =
          ev |> Brr.Ev.current_target |> Brr.Ev.target_to_jv |> Brr.El.of_jv
        in
        let x = x -. Brr.El.bound_x container in
        let y = y -. Brr.El.bound_y container in
        let position_var = (Lwd.var x, Lwd.var y, Lwd.var 0., Lwd.var 0.) in
        Lwd.set box_selection_var (Some position_var);
        select_of_coords container ~x ~y ~dx:0. ~dy:0.;
        (x, y, container, position_var)
      in
      let drag ~x:_ ~y:_ ~dx ~dy ((x, y, container, (vx, vy, vdx, vdy)) as acc)
          _ev =
        let x, dx = if dx < 0. then (x +. dx, -.dx) else (x, dx) in
        let y, dy = if dy < 0. then (y +. dy, -.dy) else (y, dy) in
        select_of_coords container ~x ~y ~dx ~dy;
        Lwd.set vx x;
        Lwd.set vy y;
        Lwd.set vdx dx;
        Lwd.set vdy dy;
        acc
      in
      let end_ _ ev =
        let mode =
          let mouse_ev = Brr.Ev.as_type ev |> Brr.Ev.Pointer.as_mouse in
          if Brr.Ev.Mouse.shift_key mouse_ev then `Add
          else if Brr.Ev.Mouse.ctrl_key mouse_ev then `Toggle
          else `Replace
        in
        promote mode recording;
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
              `P (!!"pointer-events", !!"none");
            ]
          in
          let div = Brr_lwd.Elwd.div ~st [] in
          Lwd_seq.element div

    let box = Lwd_seq.lift box
  end

  module Preview = struct
    let preview_selection_var = Lwd.var None

    let select (x, y, dx, dy) recording =
      let x', y' = Tools.window_coord_in_universe (x +. dx) (y +. dy) in
      let x, y = Tools.window_coord_in_universe x y in
      Lwd_table.iter
        (fun { preselected; path; _ } ->
          let path = Lwd.peek path in
          let is_selected =
            List.exists
              (fun ((a, b), _) -> x <= a && a <= x' && y <= b && b <= y')
              path
          in
          Lwd.set preselected is_selected)
        recording.strokes

    let event recording =
      let start x y _ev =
        let position_var = (Lwd.var x, Lwd.var y, Lwd.var 0., Lwd.var 0.) in
        Lwd.set preview_selection_var (Some position_var);
        position_var
      in
      let drag ~x ~y ~dx ~dy ((vx, vy, vdx, vdy) as acc) _ev =
        let x, dx = if dx < 0. then (x +. dx, -.dx) else (x, dx) in
        let y, dy = if dy < 0. then (y +. dy, -.dy) else (y, dy) in
        Lwd.set vx x;
        Lwd.set vy y;
        Lwd.set vdx dx;
        Lwd.set vdy dy;
        select (x, y, dx, dy) recording;
        acc
      in
      let end_ _ ev =
        let mode =
          let mouse_ev = Brr.Ev.as_type ev |> Brr.Ev.Pointer.as_mouse in
          if Brr.Ev.Mouse.shift_key mouse_ev then `Add
          else if Brr.Ev.Mouse.ctrl_key mouse_ev then `Toggle
          else `Replace
        in
        promote mode recording;
        Lwd.set preview_selection_var None
      in
      Ui_widgets.mouse_drag start drag end_

    let box =
      let$ box_selection = Lwd.get preview_selection_var in
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
end

module Move = struct
  module Timeline = struct
    let move recording time_shift track_shift strokes =
      let total_length = Lwd.peek recording.total_time in
      let time_shift =
        List.fold_left
          (fun time_shift -> function
            | `Stroke (old_path, old_track, stroke, erase, end_, start) ->
                let time_shift = Float.min time_shift (total_length -. end_) in
                Float.max time_shift (0. -. start)
            | `Erase (old_t, old_track, (sel : erased), stroke, end_at) ->
                let time_shift = Float.min time_shift (total_length -. old_t) in
                Float.max time_shift (end_at -. old_t))
          time_shift strokes
      in
      List.iter
        (function
          | `Stroke (old_path, old_track, stroke, erase, end_, start) ->
              let new_track = Int.max 0 (old_track + track_shift) in
              Lwd.set stroke.track new_track;
              let () =
                erase
                |> Option.iter @@ fun e ->
                   if Lwd.peek e.at < end_ +. time_shift then
                     Lwd.set e.at (end_ +. time_shift)
              in
              let new_path =
                Drawing_state.Path_editing.translate old_path time_shift
              in
              Lwd.set stroke.path new_path
          | `Erase (old_t, old_track, (sel : erased), stroke, _) ->
              let new_track = Int.max 0 (old_track + track_shift) in
              Lwd.set sel.track new_track;
              Lwd.set sel.at (old_t +. time_shift);
              ())
        strokes

    let event recording ~stroke_height =
      let scale container =
        let total_length = Lwd.peek recording.total_time in
        let width_in_pixel = Brr.El.bound_w container in
        total_length /. width_in_pixel
      in
      let translate_of_coords strokes container ~dx ~dy =
        let track_shift = int_of_float dy / stroke_height in
        let time_shift = dx *. scale container in
        move recording time_shift track_shift strokes
      in
      let add_stroke stroke =
        let old_path = Lwd.peek stroke.path in
        let end_at = snd (List.hd old_path) in
        `Stroke
          ( old_path,
            Lwd.peek stroke.track,
            stroke,
            Lwd.peek stroke.erased,
            end_at,
            snd (List.hd (List.rev old_path)) )
      in
      let add_erase stroke sel =
        let old_path = Lwd.peek stroke.path in
        let end_at =
          if not (Lwd.peek stroke.selected) then snd (List.hd old_path) else 0.
        in
        `Erase (Lwd.peek sel.at, Lwd.peek sel.track, sel, stroke, end_at)
      in
      let start x _y ev =
        let strokes =
          Lwd_table.fold
            (fun acc stroke ->
              let s =
                if not (Lwd.peek stroke.selected) then []
                else [ add_stroke stroke ]
              in
              let sel =
                match Lwd.peek stroke.erased with
                | Some sel when Lwd.peek sel.selected ->
                    [ add_erase stroke sel ]
                | _ -> []
              in
              s @ sel @ acc)
            [] recording.strokes
        in
        let el =
          ev |> Brr.Ev.current_target |> Brr.Ev.target_to_jv |> Brr.El.of_jv
        in
        let x = x -. Brr.El.bound_x el in
        let select_after_time () =
          let time2 = x *. scale el in
          Brr.Console.(log [ "time_shift"; el; x; Jv.of_float time2 ]);
          let strokes =
            Lwd_table.fold
              (fun acc stroke ->
                let acc =
                  if Lwd.peek stroke.path |> List.hd |> fun (_, x) -> x >= time2
                  then add_stroke stroke :: acc
                  else acc
                in
                let acc =
                  match Lwd.peek stroke.erased with
                  | Some sel when Lwd.peek sel.at >= time2 ->
                      add_erase stroke sel :: acc
                  | _ -> acc
                in
                acc)
              [] recording.strokes
          in
          (strokes, el)
        in
        match strokes with [] -> select_after_time () | _ :: _ -> (strokes, el)
      in
      let drag ~x:_ ~y:_ ~dx ~dy ((strokes, container) as acc) _ev =
        translate_of_coords strokes container ~dx ~dy;
        acc
      in
      let end_ _ _ = () in
      Ui_widgets.mouse_drag start drag end_
  end

  module Preview = struct
    let event recording =
      let start _x _y _ev =
        Lwd_table.fold
          (fun acc s ->
            if Lwd.peek s.selected then
              (Lwd.peek s.path, s.path, s.scale) :: acc
            else acc)
          [] recording.strokes
      in
      let drag ~x:_ ~y:_ ~dx ~dy paths _ev =
        List.iter
          (fun (p, v, scale) ->
            Lwd.set v
              (Drawing_state.Path_editing.translate_space p (dx /. scale)
                 (dy /. scale)))
          paths;
        paths
      in
      let end_ _ _ev = () in
      Ui_widgets.mouse_drag start drag end_
  end
end

module Scale = struct
  module Timeline = struct
    let event recording =
      let start _x _y ev =
        let strokes =
          Lwd_table.fold
            (fun acc stroke ->
              let s =
                if not (Lwd.peek stroke.selected) then []
                else [ `Stroke (Lwd.peek stroke.path, stroke) ]
              in
              let sel =
                match Lwd.peek stroke.erased with
                | Some sel when Lwd.peek sel.selected ->
                    [ `Erase (Lwd.peek sel.at, sel, stroke) ]
                | _ -> []
              in
              s @ sel @ acc)
            [] recording.strokes
        in
        let el =
          ev |> Brr.Ev.current_target |> Brr.Ev.target_to_jv |> Brr.El.of_jv
        in
        let t_begin =
          List.fold_left
            (fun t_begin -> function
              | `Stroke (_, stroke) ->
                  Float.min t_begin (very_quick_sample stroke.starts_at)
              | `Erase (at, _, _) -> Float.min t_begin at)
            Float.infinity strokes
        in
        let t_end =
          List.fold_left
            (fun t_end -> function
              | `Stroke (_, stroke) ->
                  Float.max t_end (very_quick_sample stroke.end_at)
              | `Erase (at, _, _) -> Float.max t_end at)
            0. strokes
        in
        (strokes, el, t_begin, t_end)
      in
      let map_time ~t_begin ~t_end ~scale ~t_max t =
        let scale = Float.max scale 0. in
        let scale =
          Float.min scale ((t_max -. t_begin) /. (t_end -. t_begin))
        in
        if t <= t_begin then t
        else if t >= t_end then
          t_begin +. ((t_end -. t_begin) *. scale) +. (t -. t_end)
        else t_begin +. ((t -. t_begin) *. scale)
      in
      let map_stroke_times f = List.map (fun (pos, t) -> (pos, f t)) in
      let drag ~x:_ ~y:_ ~dx ~dy:_
          ((strokes, _container, t_begin, t_end) as acc) _ev =
        let scale = 1. +. (dx /. 400.) in
        let t_max = Lwd.peek recording.total_time in
        let map_time = map_time ~t_begin ~t_end ~scale ~t_max in
        let map_stroke path = map_stroke_times map_time path in
        List.iter
          (function
            | `Stroke (path, stroke) -> Lwd.set stroke.path (map_stroke path)
            | `Erase (at, erased, _stroke) -> Lwd.set erased.at (map_time at))
          strokes;
        acc
      in
      let end_ _ _ = () in
      Ui_widgets.mouse_drag start drag end_
  end

  module Preview = struct
    let event recording =
      let start _x _y _ev =
        let strokes =
          Lwd_table.fold
            (fun acc s ->
              if Lwd.peek s.selected then (Lwd.peek s.path, s.path) :: acc
              else acc)
            [] recording.strokes
        in
        let minX, minY =
          List.fold_left
            (fun (mx, my) (path, _) ->
              let mx =
                List.fold_left (fun m ((x, _), _) -> Float.min m x) mx path
              in
              let my =
                List.fold_left (fun m ((_, y), _) -> Float.min m y) my path
              in
              (mx, my))
            (Float.infinity, Float.infinity)
            strokes
        in
        (strokes, minX, minY)
      in
      let drag ~x:_ ~y:_ ~dx ~dy ((paths, minX, minY) as acc) _ev =
        List.iter
          (fun (p, v) ->
            Lwd.set v
              (Drawing_state.Path_editing.scale_space p minX minY
                 (1. +. ((dx +. dy) /. 500.))))
          paths;
        acc
      in
      let end_ _ _ev = () in
      Ui_widgets.mouse_drag start drag end_
  end
end
