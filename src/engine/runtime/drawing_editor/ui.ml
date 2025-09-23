open State_types
open Lwd_infix

let slider =
  let el =
    Ui_widgets.float ~type':"range" ~kind:`Input State.time
      [ `P (Brr.At.id (Jstr.v "slipshow-time-slider")) ]
  in
  Brr_lwd.Elwd.div [ `R el ]

let el_of_stroke (stroke : stro) =
  let option = Ui_widgets.of_color stroke.color in
  let selected, ev = Ui_widgets.hover () in
  Lwd.set stroke.selected selected;
  Brr_lwd.Elwd.div ~ev [ `R option ]

let el =
  let display =
    let$ current = State.Recording.current in
    match current with
    | None -> Lwd_seq.element @@ Brr.At.class' (Jstr.v "slipshow-dont-display")
    | Some _ -> Lwd_seq.empty
  in
  let strokes =
    let$ current = State.Recording.current in
    match current with
    | None -> []
    | Some current -> current |> List.rev_map (fun x -> `R (el_of_stroke x))
    (* We reverse as strokes are ordered in reverse (by time) in recordings *)
  in
  let ti =
    let$ time = Lwd.get State.time in
    Brr.El.div [ Brr.El.txt' (string_of_float time) ]
  in
  let strokes =
    let$* strokes = strokes in
    Brr_lwd.Elwd.div strokes
  in
  Brr_lwd.Elwd.div
    ~at:[ `P (Brr.At.id (Jstr.v "slipshow-drawing-editor")); `S display ]
    [ `R ti; `R slider; `R strokes ]
