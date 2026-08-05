open Brr
open Brr_lwd
open Lwd_infix

let current = Lwd.var None
let ( !! ) = Jstr.v
let activate_class = !!"slipshow-activated"
let sof x = Printf.sprintf "%.25f" x
let transform_s x y = "translate(" ^ sof x ^ "px, " ^ sof y ^ "px)"

let init () =
  let display =
    let$ status = Lwd.get current in
    match status with
    | Some _ -> (!!"display", !!"block")
    | None -> (!!"display", !!"none")
  in
  let handler =
    let start _x _y _ev = Lwd.peek current in
    let drag ~x:_ ~y:_ ~dx ~dy el _ev =
      let () =
        let ( let> ) x f = Option.iter f x in
        let> el = el in
        let> id =
          El.prop El.Prop.id el |> Jstr.to_string |> function
          | "" -> None
          | s -> Some s
        in
        let new_position = transform_s dx dy in
        let () =
          Messaging.send_gui_coordinate id (int_of_float dx) (int_of_float dy)
        in
        El.set_inline_style !!"transform" !!new_position el
      in
      el
    in
    let end_ _ _ev = () in
    Drawing_controller.Ui_widgets.mouse_drag start drag end_
  in
  let for_events =
    Elwd.div
      ~ev:[ `P handler ]
      ~at:[ `P (Brr.At.id !!"slipshow-gui-for-events") ]
      ~st:
        [
          `P (!!"cursor", !!"move");
          `R display;
          `P (!!"position", !!"absolute");
          `P (!!"top", !!"0");
          `P (!!"left", !!"0");
          `P (!!"right", !!"0");
          `P (!!"bottom", !!"0");
        ]
      []
  in
  let main =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
  in
  let _root = Elwd.append_child main for_events in
  ()

let activate id =
  match El.find_first_by_selector !!("#" ^ id) with
  | None -> ()
  | Some el ->
      let () =
        match Lwd.peek current with
        | Some old_el when old_el <> el ->
            El.set_class activate_class false old_el
        | _ -> ()
      in
      Lwd.set current (Some el);
      El.set_class activate_class true el

let deactivate () =
  match Lwd.peek current with
  | Some old_el ->
      Lwd.set current None;
      El.set_class activate_class false old_el
  | None -> ()
