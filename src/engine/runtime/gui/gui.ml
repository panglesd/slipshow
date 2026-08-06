open Brr
open Brr_lwd
open Lwd_infix
module Types = Types
module State = State
module Controller = Controller
module Action = Action

let ( !! ) = Jstr.v
let sof x = Printf.sprintf "%.25f" x
let pos_attr = !!"slipshow-original-loc"

let for_events window =
  let display =
    let$ mode = Lwd.get State.status and$ status = Drawing_state.Status.get in
    match (status, mode) with
    | Gui_mode, (Move | Scale | Dimension) -> (!!"display", !!"block")
    | _ -> (!!"display", !!"none")
  in
  let handler = Gui_tools.move window in
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
                Gui_tools.transform_s (float_of_int a) (float_of_int b)
              in
              El.set_prop Gui_tools.x_coord a el;
              El.set_prop Gui_tools.y_coord b el;
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
