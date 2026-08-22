open Lwd_infix
open Drawing_state
open Brr_lwd
open Widgets

let panel =
  let content =
    let$* status = Status.get in
    match status with
    | Drawing d -> Drawing_toolbar.v d
    | Editing -> Editing_toolbar.v
    | Gui_mode -> Gui_toolbar.v
  in
  Elwd.div ~at:[ `P (Brr.At.id !!"slipshow-drawing-toolbar") ] [ `R content ]

let init_ui () =
  let body =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
  in
  let _root = Elwd.append_child body panel in
  ()
