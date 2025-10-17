open State_types
open Lwd_infix

let ( !! ) = Jstr.v
let total_length (recording : t) = Lwd.get recording.total_time

let slider recording =
  let attrs =
    [
      `P (Brr.At.id !!"slipshow-time-slider");
      `P (Brr.At.class' !!"time-slider");
      `P (Brr.At.v !!"min" !!"0");
    ]
  in
  let prop =
    let max =
      let$ max = total_length recording in
      (!!"max", Jv.of_float max)
    in
    [ `R max ]
  in
  let el =
    Ui_widgets.float ~prop ~type':"range" ~kind:`Input State.time attrs
  in
  Brr_lwd.Elwd.div [ `R el ]

let left_selection recording =
  let attrs =
    let max =
      let$ max = total_length recording in
      Brr.At.v !!"max" (Jstr.of_float max)
    in
    [
      `P (Brr.At.id !!"slipshow-right-selection-slider");
      `P (Brr.At.class' !!"time-slider");
      `P (Brr.At.v !!"min" !!"0");
      `R max;
    ]
  in
  let callback n =
    Lwd.may_update
      (fun m -> if m >= n then None else Some n)
      State.right_selection
  in
  let el =
    Ui_widgets.float ~callback ~type':"range" ~kind:`Input State.left_selection
      attrs
  in
  Brr_lwd.Elwd.div [ `R el ]

let right_selection recording =
  let attrs =
    let max =
      let$ max = total_length recording in
      Brr.At.v !!"max" (Jstr.of_float max)
    in
    [
      `P (Brr.At.id !!"slipshow-right-selection-slider");
      `P (Brr.At.class' !!"time-slider");
      `P (Brr.At.v !!"min" !!"0");
      `R max;
    ]
  in
  let callback n =
    Lwd.may_update
      (fun m -> if m <= n then None else Some n)
      State.left_selection
  in
  let el =
    Ui_widgets.float ~callback ~type':"range" ~kind:`Input State.right_selection
      attrs
  in
  Brr_lwd.Elwd.div [ `R el ]

let description_of_stroke row (stroke : stro) =
  let color = Ui_widgets.of_color stroke.color in
  let color = Brr_lwd.Elwd.div [ `P (Brr.El.txt' "Color: "); `R color ] in
  let size =
    Ui_widgets.float
      ~st:[ `P (Brr.El.Style.width, !!"50px") ]
      ~type':"number" stroke.options.size []
  in
  let size = Brr_lwd.Elwd.div [ `P (Brr.El.txt' "Size: "); `R size ] in
  let close =
    let click_handler =
      Brr_lwd.Elwd.handler Brr.Ev.click (fun _ -> Lwd.set stroke.selected false)
    in
    Brr_lwd.Elwd.button ~ev:[ `P click_handler ] [ `P (Brr.El.txt' "Close") ]
  in
  let delete =
    let click_handler =
      Brr_lwd.Elwd.handler Brr.Ev.click (fun _ -> Lwd_table.remove row)
    in
    Brr_lwd.Elwd.button ~ev:[ `P click_handler ] [ `P (Brr.El.txt' "Remove") ]
  in
  let duration =
    let duration =
      let at = [ `P (Brr.At.type' !!"number") ] in
      let prop =
        let v =
          let$ end_at = stroke.end_at and$ starts_at = stroke.starts_at in
          (!!"value", Jv.of_float (end_at -. starts_at))
        in
        [ `R v ]
      in
      let ev =
        let$ path = Lwd.get stroke.path in
        let begin_ = List.hd (List.rev path) |> snd in
        let end_ = List.hd path |> snd in
        Brr_lwd.Elwd.handler Brr.Ev.change (fun ev ->
            let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
            let new_value =
              Jv.get el "value" |> Jv.to_string |> float_of_string
            in
            let new_path =
              Path_editing.change_path path begin_ end_ new_value
            in
            Lwd.set stroke.path new_path)
      in
      let ev = [ `R ev ] in
      Brr_lwd.Elwd.input ~prop ~ev ~at ()
    in
    Brr_lwd.Elwd.div [ `P (Brr.El.txt' "Duration: "); `R duration ]
  in
  Brr_lwd.Elwd.div [ `R color; `R size; `R duration; `R delete; `R close ]

let global_panel recording =
  let total_time = Ui_widgets.float ~type':"number" recording.total_time [] in
  let total_time =
    Brr_lwd.Elwd.div [ `P (Brr.El.txt' "Total duration: "); `R total_time ]
  in
  Brr_lwd.Elwd.div [ `R total_time ]

let block_of_stroke recording (stroke : stro) =
  let left =
    let$* start_time = stroke.starts_at in
    let$ total_length = total_length recording in
    let left = start_time *. 100. /. total_length in
    let left = Jstr.append (Jstr.of_float left) !!"%" in
    (Brr.El.Style.left, left)
  in
  let right =
    let$* end_time = stroke.end_at in
    let$ total_length = total_length recording in
    let right = (total_length -. end_time) *. 100. /. total_length in
    let right = Jstr.append (Jstr.of_float right) !!"%" in
    (Brr.El.Style.right, right)
  in
  let stroke_height = 20 in
  let px_int x = Jstr.append (Jstr.of_int x) !!"px" in
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
  let selected =
    let$* selected = State.is_selected stroke in
    let$ preselected = State.is_preselected stroke in
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
  Brr_lwd.Elwd.div ~ev ~st []

let play_panel recording =
  let$* is_playing = Lwd.get State.is_playing in
  if is_playing then
    let click = Brr_lwd.Elwd.handler Brr.Ev.click (fun _ -> State.stop ()) in
    Brr_lwd.Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Pause") ]
  else
    let click =
      Brr_lwd.Elwd.handler Brr.Ev.click (fun _ -> State.play recording)
    in
    Brr_lwd.Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Play") ]

let save_panel recording =
  let click =
    Brr_lwd.Elwd.handler Brr.Ev.click (fun _ ->
        let recording = State_conversion.record_to_record recording in
        let s = Drawing.Action.Record.to_string recording in
        let blob =
          let init = Brr.Blob.init ~type':(Jstr.v "application/json") () in
          Brr.Blob.of_jstr ~init (Jstr.v s)
        in
        let a = Brr.El.a [] in
        let revoke_url =
          let url = Jv.get Jv.global "URL" in
          let object_url =
            Jv.call url "createObjectURL" [| Brr.Blob.to_jv blob |]
          in
          Jv.set (Brr.El.to_jv a) "href" object_url;
          fun () -> Jv.call url "revokeObjectURL" [| object_url |] |> ignore
        in
        Jv.set (Brr.El.to_jv a) "download" (Jv.of_string "drawing.draw");
        Jv.call (Brr.El.to_jv a) "click" [||] |> ignore;
        revoke_url ())
  in
  Brr_lwd.Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Save") ]

let el (recording : t) =
  let description =
    let$* s =
      Lwd_table.map_reduce
        (fun row s ->
          Lwd.get s.selected
          |> Lwd.map ~f:(fun x ->
                 if x then Lwd_seq.element (row, s) else Lwd_seq.empty))
        Lwd_seq.lwd_monoid recording.strokes
      |> Lwd.join
    in
    let l = Lwd_seq.to_list s in
    match l with
    | [] -> global_panel recording
    | [ (row, current_stroke) ] -> description_of_stroke row current_stroke
    | _ :: _ :: _ -> Brr_lwd.Elwd.div [ `P (Brr.El.txt' "Not implemented") ]
  in
  let strokes =
    Lwd_table.map_reduce
      (fun _ s -> Lwd_seq.element @@ block_of_stroke recording s)
      Lwd_seq.monoid recording.strokes
    |> Lwd_seq.lift
  in
  let ti = Ui_widgets.float State.time [] in
  let description =
    Brr_lwd.Elwd.div ~st:[ `P (Brr.El.Style.width, !!"20%") ] [ `R description ]
  in
  let strokes =
    let st =
      let height =
        let$ n_track = State.Track.n_track recording.strokes in
        ( Brr.El.Style.height,
          Jstr.append (Jstr.of_int ((n_track + 1) * 20)) !!"px" )
      in
      [ `P (Brr.El.Style.position, !!"relative"); `R height ]
    in
    Brr_lwd.Elwd.div ~st [ `S strokes ]
  in
  let time_panel =
    Brr_lwd.Elwd.div
      ~st:[ `P (!!"flex-grow", !!"1") ]
      [
        `R ti;
        `R (play_panel ());
        `R (save_panel recording);
        `R (slider recording);
        `R strokes;
        `R (left_selection recording);
        `R (right_selection recording);
      ]
  in
  Brr_lwd.Elwd.div
    ~st:[ `P (Brr.El.Style.display, !!"flex") ]
    [ `R description; `R time_panel ]

let el =
  let display =
    let$ current = State.Recording.current in
    match current with
    | None -> Lwd_seq.element @@ Brr.At.class' !!"slipshow-dont-display"
    | Some _ -> Lwd_seq.empty
  in
  let el =
    let$* current = State.Recording.current in
    match current with
    | None -> Lwd.pure (Brr.El.div [])
    | Some recording -> el recording
  in
  Brr_lwd.Elwd.div
    ~at:[ `P (Brr.At.id !!"slipshow-drawing-editor"); `S display ]
    ~st:[ `P (Brr.El.Style.height, !!"200px") ]
    [ `R el ]
