open State_types
open Lwd_infix

let total_length recording =
  match recording with [] -> 0. | x :: _ -> x.end_at

let slider recording =
  let attrs =
    let max = total_length recording in
    [
      `P (Brr.At.id (Jstr.v "slipshow-time-slider"));
      `P (Brr.At.v (Jstr.v "min") (Jstr.v "0"));
      `P (Brr.At.v (Jstr.v "max") (Jstr.of_float max));
    ]
  in
  let el = Ui_widgets.float ~type':"range" ~kind:`Input State.time attrs in
  Brr_lwd.Elwd.div [ `R el ]

let description_of_stroke (stroke : stro) =
  let color = Ui_widgets.of_color stroke.color in
  let color = Brr_lwd.Elwd.div [ `P (Brr.El.txt' "Color:"); `R color ] in
  let size = Ui_widgets.float ~type':"number" stroke.options.size [] in
  let size = Brr_lwd.Elwd.div [ `P (Brr.El.txt' "Size:"); `R size ] in
  let close =
    let click_handler =
      Brr_lwd.Elwd.handler Brr.Ev.click (fun _ -> Lwd.set State.selected None)
    in
    Brr_lwd.Elwd.button ~ev:[ `P click_handler ] [ `P (Brr.El.txt' "Close") ]
  in
  Brr_lwd.Elwd.div [ `R color; `R size; `R close ]

let block_of_stroke recording (stroke : stro) =
  let start_time =
    match List.rev stroke.path with [] -> 0. | (_, t) :: _ -> t
  in
  let end_time = stroke.end_at in
  let total_length = total_length recording in
  let left =
    let left = start_time *. 100. /. total_length in
    Jstr.append (Jstr.of_float left) (Jstr.v "%")
  in
  let right =
    let right = (total_length -. end_time) *. 100. /. total_length in
    Jstr.append (Jstr.of_float right) (Jstr.v "%")
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
      `P (Brr.El.Style.left, left);
      `P (Brr.El.Style.right, right);
      `S selected;
      `P (Brr.El.Style.position, Jstr.v "absolute");
      `R color;
    ]
  in
  let _preselected, ev1 = Ui_widgets.hover ~var:State.preselected stroke () in
  let click_handler =
    Brr_lwd.Elwd.handler Brr.Ev.click (fun _ ->
        match Lwd.peek State.selected with
        | Some stroke2 when stroke2 == stroke -> Lwd.set State.selected None
        | _ -> Lwd.set State.selected (Some stroke))
  in
  let ev = `P click_handler :: ev1 in
  Brr_lwd.Elwd.div ~ev ~st []

let el recording =
  let description =
    let$ current_stroke = Lwd.get State.selected in
    match current_stroke with
    | None -> Lwd_seq.empty
    | Some current_stroke ->
        Lwd_seq.element @@ description_of_stroke current_stroke
  in
  let strokes =
    recording |> List.rev_map (fun x -> `R (block_of_stroke recording x))
  in
  let ti =
    let$ time = Lwd.get State.time in
    Brr.El.div [ Brr.El.txt' (string_of_float time) ]
  in
  let description = Brr_lwd.Elwd.div [ `S (Lwd_seq.lift description) ] in
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
      [ `R ti; `R (slider recording); `R strokes ]
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
    [ `R el ]
