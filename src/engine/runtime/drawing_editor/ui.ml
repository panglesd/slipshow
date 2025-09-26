open State_types
open Lwd_infix

let total_length (recording : t) =
  match recording with [] -> Lwd.pure 0. | x :: _ -> x.end_at

let slider recording =
  let attrs =
    let max =
      let$ max = total_length recording in
      Brr.At.v (Jstr.v "max") (Jstr.of_float max)
    in
    [
      `P (Brr.At.id (Jstr.v "slipshow-time-slider"));
      `P (Brr.At.class' (Jstr.v "time-slider"));
      `P (Brr.At.v (Jstr.v "min") (Jstr.v "0"));
      `R max;
    ]
  in
  let el = Ui_widgets.float ~type':"range" ~kind:`Input State.time attrs in
  Brr_lwd.Elwd.div [ `R el ]

let left_selection recording =
  let attrs =
    let max =
      let$ max = total_length recording in
      Brr.At.v (Jstr.v "max") (Jstr.of_float max)
    in
    [
      `P (Brr.At.id (Jstr.v "slipshow-right-selection-slider"));
      `P (Brr.At.class' (Jstr.v "time-slider"));
      `P (Brr.At.v (Jstr.v "min") (Jstr.v "0"));
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
      Brr.At.v (Jstr.v "max") (Jstr.of_float max)
    in
    [
      `P (Brr.At.id (Jstr.v "slipshow-right-selection-slider"));
      `P (Brr.At.class' (Jstr.v "time-slider"));
      `P (Brr.At.v (Jstr.v "min") (Jstr.v "0"));
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

let description_of_stroke (stroke : stro) =
  let color = Ui_widgets.of_color stroke.color in
  let color = Brr_lwd.Elwd.div [ `P (Brr.El.txt' "Color: "); `R color ] in
  let size =
    Ui_widgets.float
      ~st:[ `P (Brr.El.Style.width, Jstr.v "50px") ]
      ~type':"number" stroke.options.size []
  in
  let size = Brr_lwd.Elwd.div [ `P (Brr.El.txt' "Size: "); `R size ] in
  let close =
    let click_handler =
      Brr_lwd.Elwd.handler Brr.Ev.click (fun _ -> Lwd.set State.selected None)
    in
    Brr_lwd.Elwd.button ~ev:[ `P click_handler ] [ `P (Brr.El.txt' "Close") ]
  in
  let duration =
    let duration =
      let at = [ `P (Brr.At.type' (Jstr.v "number")) ] in
      let prop =
        let v =
          let$ end_at = stroke.end_at and$ starts_at = stroke.starts_at in
          (Jstr.v "value", Jv.of_float (end_at -. starts_at))
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
  Brr_lwd.Elwd.div [ `R color; `R size; `R duration; `R close ]

let block_of_stroke recording (stroke : stro) =
  let left =
    let$* start_time = stroke.starts_at in
    let$ total_length = total_length recording in
    let left = start_time *. 100. /. total_length in
    let left = Jstr.append (Jstr.of_float left) (Jstr.v "%") in
    (Brr.El.Style.left, left)
  in
  let right =
    let$* end_time = stroke.end_at in
    let$ total_length = total_length recording in
    let right = (total_length -. end_time) *. 100. /. total_length in
    let right = Jstr.append (Jstr.of_float right) (Jstr.v "%") in
    (Brr.El.Style.right, right)
  in
  let color =
    let$ color = Lwd.get stroke.color in
    let color = color |> Drawing.Color.to_string |> Jstr.v in
    (Brr.El.Style.background_color, color)
  in
  let selected =
    let$* selected = State.is_selected stroke in
    let$ preselected = State.is_preselected stroke in
    let l =
      if selected then
        [
          (Brr.El.Style.height, Jstr.v "40px");
          (Jstr.v "border", Jstr.v "5px solid black");
        ]
      else if preselected then
        [
          (Brr.El.Style.height, Jstr.v "40px");
          (Jstr.v "border", Jstr.v "5px solid grey");
        ]
      else [ (Brr.El.Style.height, Jstr.v "50px") ]
    in
    Lwd_seq.of_list l
  in
  let st =
    [
      `P (Brr.El.Style.cursor, Jstr.v "pointer");
      `R left;
      `R right;
      `S selected;
      `P (Brr.El.Style.position, Jstr.v "absolute");
      `R color;
    ]
  in
  let _preselected, ev_hover =
    Ui_widgets.hover ~var:State.preselected stroke ()
  in
  let click_handler =
    Brr_lwd.Elwd.handler Brr.Ev.click (fun _ ->
        match Lwd.peek State.selected with
        | Some stroke2 when stroke2 == stroke -> Lwd.set State.selected None
        | _ -> Lwd.set State.selected (Some stroke))
  in
  let move_handlers =
    let state = ref None in
    let mouse_down =
      let$ total_length = total_length recording in
      let path = Lwd.peek stroke.path in
      let mouse_move x path ev =
        let parent =
          ev |> Brr.Ev.target |> Brr.Ev.target_to_jv |> Brr.El.of_jv
          |> Brr.El.parent |> Option.get
        in
        let width_in_pixel = Brr.El.bound_w parent in
        let scale = total_length /. width_in_pixel in
        let ev = Brr.Ev.as_type ev in
        let y = Brr.Ev.Mouse.client_x ev in
        let new_pos = scale *. (y -. x) in
        let new_path = Path_editing.translate path new_pos in
        Lwd.set stroke.path new_path;
        Brr.Console.(log [ "new pos"; y -. x ])
      in
      Brr_lwd.Elwd.handler Brr.Ev.mousedown (fun ev ->
          let ev = Brr.Ev.as_type ev in
          let x = Brr.Ev.Mouse.client_x ev in
          let id_to_remove = ref None in
          let id =
            Brr.Ev.listen Brr.Ev.mousemove (mouse_move x path)
              (Brr.Document.body Brr.G.document |> Brr.El.as_target)
          in
          id_to_remove := Some id)
    in
    let mouse_move =
      match initial_mouse_pos with
      | None -> Lwd_seq.empty
      | Some x ->
          let path = Lwd.peek stroke.path in
          Lwd_seq.element
          @@ Brr_lwd.Elwd.handler Brr.Ev.mousemove (fun ev ->
                 let parent =
                   ev |> Brr.Ev.target |> Brr.Ev.target_to_jv |> Brr.El.of_jv
                   |> Brr.El.parent |> Option.get
                 in
                 let width_in_pixel = Brr.El.bound_w parent in
                 let scale = total_length /. width_in_pixel in
                 let ev = Brr.Ev.as_type ev in
                 let y = Brr.Ev.Mouse.client_x ev in
                 let new_pos = scale *. (y -. x) in
                 let new_path = Path_editing.translate path new_pos in
                 Lwd.set stroke.path new_path;
                 Brr.Console.(log [ "new pos"; y -. x ]))
    in
    let mouse_up =
      let$ initial_mouse_pos' = Lwd.get initial_mouse_pos in
      match initial_mouse_pos' with
      | None -> Lwd_seq.empty
      | Some _ ->
          Lwd_seq.element
          @@ Brr_lwd.Elwd.handler Brr.Ev.mouseup (fun _ ->
                 Lwd.set initial_mouse_pos None)
    in
    [ `P mouse_down; `S mouse_move; `S mouse_up ]
  in
  let ev = (`P click_handler :: ev_hover) @ move_handlers in
  Brr_lwd.Elwd.div ~ev ~st []

let play (recording : t) =
  Lwd.set State.is_playing true;
  let now () = Brr.Performance.now_ms Brr.G.performance in
  let max =
    match recording with
    | [] -> 0.
    | stroke :: _ -> List.hd (Lwd.peek stroke.path) |> snd
  in
  let start_time = now () -. Lwd.peek State.time in
  let rec loop _ =
    let now = now () -. start_time in
    Lwd.set State.time now;
    if now <= max && Lwd.peek State.is_playing then
      let _animation_frame_id = Brr.G.request_animation_frame loop in
      ()
    else Lwd.set State.is_playing false
  in
  loop 0.

let stop () = Lwd.set State.is_playing false

let play_panel recording =
  let$* is_playing = Lwd.get State.is_playing in
  if is_playing then
    let click = Brr_lwd.Elwd.handler Brr.Ev.click (fun _ -> stop ()) in
    Brr_lwd.Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Pause") ]
  else
    let click = Brr_lwd.Elwd.handler Brr.Ev.click (fun _ -> play recording) in
    Brr_lwd.Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Play") ]

let el (recording : t) =
  let description =
    let$* current_stroke = Lwd.get State.selected in
    match current_stroke with
    | None -> (* play_panel recording *) Brr_lwd.Elwd.div []
    | Some current_stroke -> description_of_stroke current_stroke
  in
  let strokes =
    recording |> List.rev_map (fun x -> `R (block_of_stroke recording x))
  in
  let ti =
    Ui_widgets.float State.time []
    (* Brr.El.div [ Brr.El.txt' (string_of_float time) ] *)
  in
  let description =
    Brr_lwd.Elwd.div
      ~st:[ `P (Brr.El.Style.width, Jstr.v "20%") ]
      [ `R description ]
  in
  let strokes =
    let st =
      [
        `P (Brr.El.Style.position, Jstr.v "relative");
        `P (Brr.El.Style.height, Jstr.v "50px");
      ]
    in
    Brr_lwd.Elwd.div ~st strokes
  in
  let time_panel =
    Brr_lwd.Elwd.div
      ~st:[ `P (Jstr.v "flex-grow", Jstr.v "1") ]
      [
        `R ti;
        `R (play_panel recording);
        `R (slider recording);
        `R strokes;
        `R (left_selection recording);
        `R (right_selection recording);
      ]
  in
  Brr_lwd.Elwd.div
    ~st:[ `P (Brr.El.Style.display, Jstr.v "flex") ]
    [ `R description; `R time_panel ]

let el =
  let display =
    let$ current = State.Recording.current in
    match current with
    | None -> Lwd_seq.element @@ Brr.At.class' (Jstr.v "slipshow-dont-display")
    | Some _ -> Lwd_seq.empty
  in
  let el =
    let$* current = State.Recording.current in
    match current with
    | None -> Lwd.pure (Brr.El.div [])
    | Some recording -> el recording
  in
  Brr_lwd.Elwd.div
    ~at:[ `P (Brr.At.id (Jstr.v "slipshow-drawing-editor")); `S display ]
    ~st:[ `P (Brr.El.Style.height, Jstr.v "200px") ]
    [ `R el ]
