open State_types
open Lwd_infix

let slider =
  let el =
    Ui_widgets.float ~type':"range" ~kind:`Input State.time
      [ `P (Brr.At.id (Jstr.v "slipshow-time_slider")) ]
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
    | None -> Lwd_seq.empty
    | Some current ->
        List.map (fun (stroke : timed_event) -> stroke.event) current.evs
        |> List.map el_of_stroke |> List.rev (* TODO: Why rev? *)
        |> Lwd_seq.of_list
  in
  let strokes = Lwd_seq.lift strokes in
  let ti =
    let$ time = Lwd.get State.time in
    Brr.El.div [ Brr.El.txt' (string_of_float time) ]
  in
  Brr_lwd.Elwd.div
    ~at:[ `P (Brr.At.id (Jstr.v "slipshow-drawing-editor")); `S display ]
    [ `R ti; `R slider; `S strokes ]
