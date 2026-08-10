open Brr_lwd
open Lwd_infix
open Widgets

let v =
  let gui_tool v icon name shortcut =
    let handler =
      Elwd.handler Brr.Ev.click (fun _ -> Lwd.set Gui.State.status v)
    in
    let class_ =
      let$ current_tool = Lwd.get Gui.State.status in
      if current_tool = v then
        Lwd_seq.of_list [ Brr.At.class' !!"slip-set-tool" ]
      else Lwd_seq.of_list []
    in
    let icon = panel_icon ~at:[ `S class_ ] [ `P (Brr.El.txt' icon) ] in
    panel_button ~handler ~icon name ~shortcut
  in
  let select = gui_tool Select "☝" (Lwd.pure "Select") "s" in
  let move = gui_tool Move "⌖" (Lwd.pure "Move") "m" in
  let resize = gui_tool Scale "⇲" (Lwd.pure "Rescale") "r" in
  let dimension = gui_tool Dimension "⌱" (Lwd.pure "Dimension") "d" in
  let block =
    panel_block ~buttons:[ `R select; `R move; `R resize; `R dimension ] ()
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
            (panel_button ~handler ~icon (Lwd.pure "Exit gui mode")
               ~shortcut:"Shift + G");
        ]
      ()
  in

  toplevel_panel_el [ `R block; `R back_mode ]
