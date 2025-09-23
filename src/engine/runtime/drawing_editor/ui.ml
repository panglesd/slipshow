open State_types
open Lwd_infix

let slider recording =
  let attrs =
    let max = match recording with [] -> 0. | x :: _ -> x.end_at in
    [
      `P (Brr.At.id (Jstr.v "slipshow-time-slider"));
      `P (Brr.At.v (Jstr.v "min") (Jstr.v "0"));
      `P (Brr.At.v (Jstr.v "max") (Jstr.of_float max));
    ]
  in
  let el = Ui_widgets.float ~type':"range" ~kind:`Input State.time attrs in
  Brr_lwd.Elwd.div [ `R el ]

let description_of_stroke (stroke : stro) =
  let option = Ui_widgets.of_color stroke.color in
  let selected, ev = Ui_widgets.hover () in
  Lwd.set stroke.selected selected;
  Brr_lwd.Elwd.div ~ev [ `R option ]

let el_of_stroke (stroke : stro) =
  let start_time = match stroke.path with [] -> 0. | (_, t) :: _ -> t in
  let end_time = stroke.end_at in
  (start_time, end_time)

let el recording =
  let description =
    let$ current = State.Recording.current in
    match current with
    | None -> []
    | Some current ->
        current |> List.rev_map (fun x -> `R (description_of_stroke x))
    (* We reverse as strokes are ordered in reverse (by time) in recordings *)
  in
  let ti =
    let$ time = Lwd.get State.time in
    Brr.El.div [ Brr.El.txt' (string_of_float time) ]
  in
  let _description =
    let$* description = description in
    Brr_lwd.Elwd.div description
  in
  Brr_lwd.Elwd.div [ `R ti; `R (slider recording); `R _description ]

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
