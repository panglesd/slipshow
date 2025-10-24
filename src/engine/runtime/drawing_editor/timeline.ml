open Lwd_infix
open State_types

let ( !! ) = Jstr.v
let total_length (recording : t) = Lwd.get recording.total_time
let px_int x = Jstr.append (Jstr.of_int x) !!"px"
let px_float x = Jstr.append (Jstr.of_float x) !!"px"

let block_of_stroke recording (stroke : stro) =
  let stroke_height = 20 in
  let selected =
    let$ selected = State.is_selected stroke
    and$ preselected = State.is_preselected stroke in
    let l =
      if selected then
        let height = px_int (stroke_height - 10) in
        [ (Brr.El.Style.height, height); (!!"border", !!"5px solid black") ]
      else if preselected then
        let height = px_int (stroke_height - 10) in
        [ (Brr.El.Style.height, height); (!!"border", !!"5px solid grey") ]
      else [ (Brr.El.Style.height, px_int stroke_height) ]
    in
    Lwd_seq.of_list ((!!"min-width", !!"1px") :: l)
  in
  let st =
    let left =
      let$ start_time = stroke.starts_at
      and$ total_length = total_length recording in
      let left = start_time *. 100. /. total_length in
      let left = Jstr.append (Jstr.of_float left) !!"%" in
      (Brr.El.Style.left, left)
    in
    let right =
      let$ end_time = stroke.end_at
      and$ total_length = total_length recording in
      let right = (total_length -. end_time) *. 100. /. total_length in
      let right = Jstr.append (Jstr.of_float right) !!"%" in
      (Brr.El.Style.right, right)
    in
    let top =
      let$ track = Lwd.get stroke.track in
      let top = px_int (track * stroke_height) in
      (Brr.El.Style.top, top)
    in
    let color =
      let$ color = Lwd.get stroke.color in
      let color = color |> Drawing.Color.to_string |> ( !! ) in
      (Brr.El.Style.background_color, color)
    in
    [
      `P (Brr.El.Style.cursor, !!"pointer");
      `R left;
      `R right;
      `R top;
      `S selected;
      `P (Brr.El.Style.position, !!"absolute");
      `R color;
    ]
  in
  let _preselected, ev_hover = Ui_widgets.hover ~var:stroke.preselected () in
  let has_moved = ref false in
  let click_handler =
    Brr_lwd.Elwd.handler Brr.Ev.click (fun _ ->
        if !has_moved then () else Lwd.update not stroke.selected)
  in
  let move_handler =
    let$ total_length = total_length recording in
    let mouse_move x y parent path track =
      let width_in_pixel = Brr.El.bound_w parent in
      let scale = total_length /. width_in_pixel in
      let end_ = List.hd path |> snd in
      let start = List.hd (List.rev path) |> snd in
      fun ev ->
        has_moved := true;
        let ev = Brr.Ev.as_type ev in
        let x' = Brr.Ev.Mouse.client_x ev in
        let y' = Brr.Ev.Mouse.client_y ev in
        let translation = scale *. (x' -. x) in
        let y_change = (y' -. y) /. float_of_int 20 |> int_of_float in
        let new_track = Int.max 0 (track + y_change) in
        Lwd.set stroke.track new_track;
        let translation = Float.min translation (total_length -. end_) in
        let translation = Float.max translation (0. -. start) in
        let new_path = Path_editing.translate path translation in
        Lwd.set stroke.path new_path
    in
    Brr_lwd.Elwd.handler Brr.Ev.mousedown (fun ev ->
        Brr.Ev.prevent_default ev;
        has_moved := false;
        let path = Lwd.peek stroke.path in
        let parent =
          ev |> Brr.Ev.target |> Brr.Ev.target_to_jv |> Brr.El.of_jv
          |> Brr.El.parent |> Option.get
        in
        let ev = Brr.Ev.as_type ev in
        let x = Brr.Ev.Mouse.client_x ev in
        let y = Brr.Ev.Mouse.client_y ev in
        let id =
          Brr.Ev.listen Brr.Ev.mousemove
            (mouse_move x y parent path (Lwd.peek stroke.track))
            (Brr.Document.body Brr.G.document |> Brr.El.as_target)
        in
        let opts = Brr.Ev.listen_opts ~once:true () in
        let _id =
          Brr.Ev.listen ~opts Brr.Ev.mouseup
            (fun _ -> Brr.Ev.unlisten id)
            (Brr.Document.body Brr.G.document |> Brr.El.as_target)
        in
        ())
  in
  let ev = `R move_handler :: `P click_handler :: ev_hover in
  let block_of_erased v =
    let move_handler =
      (* TODO: This move handler is duplicated with the selection one, they need
         to be factored out but I delay this because maybe they both will be
         removed when I implement the select tool. *)
      let$ total_length = total_length recording in
      let mouse_move x parent =
        let width_in_pixel = Brr.El.bound_w parent in
        let scale = total_length /. width_in_pixel in
        let current_pos = Lwd.peek v in
        fun ev ->
          let ev = Brr.Ev.as_type ev in
          let x' = Brr.Ev.Mouse.client_x ev in
          let translation = scale *. (x' -. x) in
          let translation =
            Float.min translation (total_length -. current_pos)
          in
          let translation = Float.max translation (0. -. current_pos) in
          Lwd.set v (current_pos +. translation)
      in
      Brr_lwd.Elwd.handler Brr.Ev.mousedown (fun ev ->
          Brr.Ev.prevent_default ev;
          let parent =
            ev |> Brr.Ev.target |> Brr.Ev.target_to_jv |> Brr.El.of_jv
            |> Brr.El.parent |> Option.get
          in
          let ev = Brr.Ev.as_type ev in
          let x = Brr.Ev.Mouse.client_x ev in
          let id =
            Brr.Ev.listen Brr.Ev.mousemove (mouse_move x parent)
              (Brr.Document.body Brr.G.document |> Brr.El.as_target)
          in
          let opts = Brr.Ev.listen_opts ~once:true () in
          let _id =
            Brr.Ev.listen ~opts Brr.Ev.mouseup
              (fun _ -> Brr.Ev.unlisten id)
              (Brr.Document.body Brr.G.document |> Brr.El.as_target)
          in
          ())
    in
    let t = Lwd.get v in
    let left =
      let$ start_time = t and$ total_length = total_length recording in
      let left = start_time *. 100. /. total_length in
      let left = Jstr.append (Jstr.of_float left) !!"%" in
      let left =
        Jstr.(v "calc(" + left + v " - " + of_int (stroke_height / 2) + v "px)")
      in
      (Brr.El.Style.left, left)
    in
    let top =
      let$ track = Lwd.get stroke.track in
      let top = px_int (track * stroke_height) in
      (Brr.El.Style.top, top)
    in
    let width =
      let$ selected = State.is_selected stroke
      and$ preselected = State.is_preselected stroke in
      let width =
        if selected || preselected then stroke_height / 2 else stroke_height
      in
      (Brr.El.Style.width, px_int width)
    in
    let st =
      [
        `P (Brr.El.Style.cursor, !!"pointer");
        `R left;
        `R top;
        `S selected;
        `P (Brr.El.Style.position, !!"absolute");
        `R width;
        `P (Brr.El.Style.background_color, !!"lightgrey");
        `P (!!"border-radius", px_int (stroke_height / 2));
        (* `R color; *)
      ]
    in
    let ev = [ `R move_handler ] in
    Brr_lwd.Elwd.div ~ev ~st []
  in
  let$ erased_block =
    let$ erased_at = Lwd.get stroke.erased_at in
    match erased_at with
    | None -> Lwd_seq.empty
    | Some erased_at -> Lwd_seq.element @@ block_of_erased erased_at
  in
  Lwd_seq.concat (Lwd_seq.element @@ Brr_lwd.Elwd.div ~ev ~st []) erased_block

let strokes recording =
  Lwd_table.map_reduce
    (fun _ s -> block_of_stroke recording s)
    Lwd_seq.lwd_monoid recording.strokes
  |> Lwd.join |> Lwd_seq.lift

let el recording =
  let strokes = strokes recording in
  let st =
    let height =
      let$ n_track = State.Track.n_track recording.strokes in
      ( Brr.El.Style.height,
        Jstr.append (Jstr.of_int ((n_track + 1) * 20)) !!"px" )
    in
    [ `P (Brr.El.Style.position, !!"relative"); `R height ]
  in
  let box_selection_var = Lwd.var None in
  let ev =
    let click _ = Brr.Console.(log [ "HeLLLLLLo clik" ]) in
    let drag ~x ~y ~dx ~dy ~current_target _ev =
      let x =
        let el_x =
          current_target |> Brr.Ev.target_to_jv |> Brr.El.of_jv
          |> Brr.El.bound_x
        in
        x -. el_x
      in
      let y =
        let el_y =
          current_target |> Brr.Ev.target_to_jv |> Brr.El.of_jv
          |> Brr.El.bound_y
        in
        y -. el_y
      in
      let x, dx = if dx < 0. then (x +. dx, -.dx) else (x, dx) in
      let y, dy = if dy < 0. then (y +. dy, -.dy) else (y, dy) in
      match Lwd.peek box_selection_var with
      | None -> Lwd.set box_selection_var (Some (Lwd.var (x, y, dx, dy)))
      | Some v -> Lwd.set v (x, y, dx, dy)
    in
    let end_ () = Lwd.set box_selection_var None in
    Ui_widgets.mouse_drag click drag end_
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
  let box = Lwd_seq.lift @@ box in
  Brr_lwd.Elwd.div ~ev ~st [ `S strokes; `S box ]
