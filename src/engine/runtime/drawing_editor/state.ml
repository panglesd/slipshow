module Stroke = struct
  let current = Lwd.var None
  let set_current (c : Drawing.Stroke.t) = Lwd.set current (Some c)

  open Lwd_infix

  let el =
    let$* current = current |> Lwd.get in
    let id =
      match current with None -> "custom_id" | Some current -> current.id
    in
    let id_elem = Brr.El.txt' id in
    Brr_lwd.Elwd.div [ `P id_elem ]
end

let time = Lwd.var 0.

open Lwd_infix

let slider =
  let ev =
    let slider_handler =
      Brr_lwd.Elwd.handler Brr.Ev.input (fun ev ->
          let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
          let new_value =
            Jv.get el "value" |> Jv.to_string |> float_of_string
          in
          Brr.Console.(log [ new_value ]);
          Lwd.set time new_value)
    in
    [ `P slider_handler ]
  in
  let at =
    let time =
      let$ time = time |> Lwd.get in
      Brr.At.value (Jstr.of_float time)
    in
    let type' = Brr.At.type' (Jstr.v "range") in
    [ `P type'; `R time ]
  in
  let el = Brr_lwd.Elwd.input ~ev ~at () in
  Brr_lwd.Elwd.div [ `R el ]

module Recording = struct
  let current = Lwd.var None
  let set_current (c : Drawing.Action.Record.record option) = Lwd.set current c
  let peek_current () = Lwd.peek current
  let current = Lwd.get current

  open Lwd_infix

  let el_of_stroke (_stroke : Drawing.Stroke.t) =
    let color =
      Brr.El.select
        [
          Brr.El.option [ Brr.El.txt' "Red" ];
          Brr.El.option [ Brr.El.txt' "Green" ];
        ]
    in
    color

  let el =
    let display =
      let$ current = current in
      match current with
      | None ->
          Lwd_seq.element @@ Brr.At.class' (Jstr.v "slipshow-dont-display")
      | Some _ -> Lwd_seq.empty
    in
    let _strokes =
      let$ current = current in
      match current with
      | None -> Lwd_seq.empty
      | Some current ->
          List.filter_map
            (fun (stroke : Drawing.Action.Record.timed_event) ->
              match stroke.event with Stroke s -> Some s | _ -> None)
            current.evs
          |> List.map el_of_stroke |> Lwd_seq.of_list
    in
    let ti =
      let$ time = Lwd.get time in
      Brr.El.div [ Brr.El.txt' (string_of_float time) ]
    in
    Brr_lwd.Elwd.div
      ~at:[ `P (Brr.At.id (Jstr.v "slipshow-drawing-editor")); `S display ]
      [ `R ti; `R slider ]
end

module Svg = struct
  let el =
    let content =
      let$* time_slider = Lwd.get time in
      let$ recording = Recording.current in
      match recording with
      | None -> Lwd_seq.empty
      | Some recording ->
          let elapsed_time =
            match recording.evs with
            | [] -> time_slider
            | { time; event = Erase _ } :: _ -> time *. time_slider /. 100.
            | { time; event = Stroke { total_duration; _ } } :: _ ->
                (time +. total_duration) *. time_slider /. 100.
          in
          let els = Drawing.Action.Replay.draw_until ~elapsed_time recording in
          Lwd_seq.of_list els
    in
    Brr_lwd.Elwd.v ~ns:`SVG (Jstr.v "svg")
      ~at:
        [
          `P
            (Brr.At.style
               (Jstr.v "overflow:visible; position: absolute; z-index:1001"));
        ]
      [ `S content ]
end
