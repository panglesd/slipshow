open Brr
open Brr_lwd
open Lwd_infix
module Types = Types
module State = State
module Controller = Controller
module Action = Action

let ( !! ) = Jstr.v
let sof x = Printf.sprintf "%.25f" x
let transform_s x y = "translate(" ^ sof x ^ "px, " ^ sof y ^ "px)"
let x_coord = El.Prop.int !!"slipshow-x-coord"
let y_coord = El.Prop.int !!"slipshow-y-coord"
let pos_attr = !!"slipshow-original-loc"

let for_events window =
  let display =
    let$ mode = Lwd.get State.status and$ status = Drawing_state.Status.get in
    match (status, mode) with
    | Gui_mode, (Move | Scale | Dimension) -> (!!"display", !!"block")
    | _ -> (!!"display", !!"none")
  in
  let handler =
    let ( let> ) x f = Option.iter f x in
    let start _x _y _ev =
      let el = Lwd.peek State.current in
      let x0, y0, scale =
        match el with
        | None -> (0, 0, 1.)
        | Some el ->
            let scale0 = Universe.Window.scale_in_universe window el in
            let { Universe.Coordinates.scale; _ } =
              Universe.State.get_coord ()
            in
            let x = El.prop x_coord el in
            let y = El.prop y_coord el in
            (x, y, Normalization.scale @@ (scale0 /. scale))
      in
      (el, 0., 0., x0, y0, scale)
    in
    let drag ~x:_ ~y:_ ~dx ~dy (el, _, _, x0, y0, scale) _ev =
      let dx = dx *. scale in
      let dy = dy *. scale in
      let () =
        let> el = el in
        let new_position =
          transform_s (dx +. float_of_int x0) (dy +. float_of_int y0)
        in
        El.set_inline_style !!"transform" !!new_position el
      in
      (el, dx, dy, x0, y0, scale)
    in
    let end_ (el, dx, dy, x0, y0, _scale) _ev =
      let> el = el in
      let> id =
        El.prop El.Prop.id el |> Jstr.to_string |> function
        | "" -> None
        | s -> Some s
      in
      let dx = int_of_float dx in
      let dy = int_of_float dy in
      El.set_prop x_coord (dx + x0) el;
      El.set_prop y_coord (dy + y0) el;
      Messaging.send_gui_coordinate id (dx + x0) (dy + y0)
    in
    Drawing_controller.Ui_widgets.mouse_drag start drag end_
  in
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

let setup_elem el =
  (* TODO: Use "special_attributes.ml" *)
  match El.at !!"gui" el with
  | None -> ()
  | Some s -> (
      match String.split_on_char ',' (Jstr.to_string s) with
      | [] | [ _ ] | _ :: _ :: _ :: _ -> ()
      | [ a; b ] -> (
          match (int_of_string_opt a, int_of_string_opt b) with
          | Some a, Some b ->
              let new_position =
                transform_s (float_of_int a) (float_of_int b)
              in
              El.set_prop x_coord a el;
              El.set_prop y_coord b el;
              El.set_inline_style !!"transform" !!new_position el
          | _ -> ()))

let make_clickable el =
  (* TODO: Use "special_attributes.ml" *)
  match El.at pos_attr el with
  | None -> ()
  | Some pos ->
      let _unlisten : Ev.listener =
        Ev.listen Ev.click
          (fun _ev ->
            Messaging.send_loc (Jstr.to_string pos);
            if Drawing_state.Status.peek () = Gui_mode then
              Action.activate_el el)
          (El.as_target el)
      in
      ()

let init window =
  let () =
    El.fold_find_by_selector
      (fun el () ->
        setup_elem el;
        make_clickable el)
      (* TODO: make Special_attributes shared and use it *)
      !!("[" ^ "slipshow-original-loc" ^ "]")
      ()
  in
  let for_events = for_events window in
  let main =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
  in
  let _root = Elwd.append_child main for_events in
  ()
