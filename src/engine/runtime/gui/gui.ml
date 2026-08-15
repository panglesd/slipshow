open Brr
open Brr_lwd
open Lwd_infix
module Types = Types
module State = State
module Controller = Controller
module Action = Action

let ( !! ) = Jstr.v
let sof x = Printf.sprintf "%.25f" x
let gui_attr = !!Common_types.Special_strings.gui
let gui_pos_attr = !!Common_types.Special_strings.gui_loc
let block_pos_attr = !!Common_types.Special_strings.original_loc

let for_events window =
  let display =
    let$ mode = Lwd.get State.status and$ status = Drawing_state.Status.get in
    match (status, mode) with
    | Gui_mode, (Move | Scale | Dimension) -> (!!"display", !!"block")
    | _ -> (!!"display", !!"none")
  in
  let cursor =
    let$ mode = Lwd.get State.status in
    match mode with
    | Move -> (!!"cursor", !!"all-scroll")
    | Scale -> (!!"cursor", !!"nwse-resize")
    | Dimension -> (!!"cursor", !!"se-resize")
    | Select -> (!!"cursor", !!"crosshair")
  in
  let handler =
    let$ mode = Lwd.get State.status in
    match mode with
    | Select -> Lwd_seq.empty
    | Move -> Lwd_seq.element @@ Gui_tools.move window
    | Scale -> Lwd_seq.element @@ Gui_tools.scale window
    | Dimension -> Lwd_seq.element @@ Gui_tools.dimension window
  in
  Elwd.div
    ~ev:[ `S handler ]
    ~at:[ `P (Brr.At.id !!"slipshow-gui-for-events") ]
    ~st:
      [
        `R cursor;
        `R display;
        `P (!!"position", !!"absolute");
        `P (!!"top", !!"0");
        `P (!!"left", !!"0");
        `P (!!"right", !!"0");
        `P (!!"bottom", !!"0");
      ]
    []

let is_gui el = El.at gui_pos_attr el
let is_block el = El.at block_pos_attr el

let rec find_up condition el =
  (* JavaScript's "closest" would be a good fit for replacing this *)
  match condition el with
  | None -> (
      if Jstr.equal (El.prop El.Prop.id el) !!"slipshow-main" then None
      else
        match El.parent el with
        | None -> None
        | Some parent -> find_up condition parent)
  | Some gui_loc -> Some (el, gui_loc)

let handle_gui_el_up el =
  match find_up is_gui el with
  | None -> false
  | Some (el, gui_loc) ->
      Messaging.send_loc (Jstr.to_string gui_loc);
      if Drawing_state.Status.peek () = Gui_mode then Action.activate_el el;
      true

let handle_block_el_up el =
  match find_up is_block el with
  | None -> false
  | Some (_el, block_loc) ->
      Messaging.send_loc (Jstr.to_string block_loc);
      true

let handle el =
  if Lwd.peek Drawing_state.can_gui then
    match Drawing_state.Status.peek () with
    | Drawing _ | Editing ->
        let _handled = handle_block_el_up el in
        ()
    | Gui_mode ->
        if handle_gui_el_up el then ()
        else if handle_block_el_up el then ()
        else ()
  else ()

let replace_positioned_el el =
  match El.at gui_attr el with
  | None -> ()
  | Some pos ->
      let coord =
        match Gui_tools.Syntax.parse (Jstr.to_string pos) with
        | Ok (x, _warnings) -> x
        | Error _ ->
            { x = None; y = None; scale = None; width = None; height = None }
      in
      Gui_tools.save_coord_el coord el;
      Gui_tools.apply_coord coord el

let init window =
  let gui_selector = "[" ^ Common_types.Special_strings.gui ^ "]" in
  let () =
    El.fold_find_by_selector
      (fun el () -> replace_positioned_el el)
      !!gui_selector ()
  in
  let main =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
  in
  let _unlisten =
    Ev.listen Ev.click
      (fun ev ->
        let el = Ev.target ev in
        handle (el |> Ev.target_to_jv |> El.of_jv))
      (El.as_target main)
  in
  let for_events = for_events window in
  let _root = Elwd.append_child main for_events in
  ()
