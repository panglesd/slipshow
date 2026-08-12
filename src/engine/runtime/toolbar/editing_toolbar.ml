open Brr_lwd
open Lwd_infix
open Drawing_state
open Widgets

let v =
  let editing_tool v icon name shortcut =
    let handler = Elwd.handler Brr.Ev.click (fun _ -> Lwd.set editing_tool v) in
    let class_ =
      let$ current_tool = Lwd.get editing_tool in
      if current_tool = v then
        Lwd_seq.of_list [ Brr.At.class' !!"slip-set-tool" ]
      else Lwd_seq.of_list []
    in
    let icon = panel_icon ~at:[ `S class_ ] [ `P (Brr.El.txt' icon) ] in
    panel_button ~handler ~icon name ~shortcut
  in
  let select = editing_tool Select "☝" (Lwd.pure "Select") "s" in
  let move = editing_tool Move "⌖" (Lwd.pure "Move") "m" in
  let resize = editing_tool Rescale "⇲" (Lwd.pure "Resize") "r" in
  let block = panel_block ~buttons:[ `R select; `R move; `R resize ] () in
  let recording_block =
    let$* current_replaying_state = Lwd.get current_replaying_state in
    match current_replaying_state with
    | None -> Lwd.pure @@ Lwd_seq.empty
    | Some current_replaying_state ->
        let record =
          let handler =
            Elwd.handler Brr.Ev.click (fun _ ->
                Drawing_state.start_recording current_replaying_state)
          in
          let icon =
            Brr.El.div
              ~at:
                [
                  Brr.At.style
                    !!"width:10px;height:10px;background:red;border-radius:5px";
                ]
              []
          in
          let icon = panel_icon [ `P icon ] in
          let txt =
            let strokes = current_replaying_state.recording.strokes in
            let$ is_empty =
              Lwd_table.map_reduce
                (fun _ _ -> false)
                (true, fun _ _ -> false)
                strokes
            in
            if is_empty then "Start recording" else "Continue recording"
          in
          panel_button ~handler ~icon txt ~shortcut:"Shift + S"
        in
        let$ panel = panel_block ~buttons:[ `R record ] () in
        Lwd_seq.element panel
  in
  let back_mode =
    let handler =
      Elwd.handler Brr.Ev.click (fun _ ->
          Drawing_state.Status.set (Drawing Presenting))
    in
    let icon = panel_icon [ `P (Brr.El.txt !!"⤶") ] in
    panel_block ~class_:"slipshow-gui-back-block"
      ~buttons:
        [
          `R
            (panel_button ~handler ~icon
               (Lwd.pure "Exit editing mode")
               ~shortcut:"Shift + R");
        ]
      ()
  in
  toplevel_panel_el [ `R block; `S recording_block; `R back_mode ]
