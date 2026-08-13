open Brr
open Brr_lwd
open Lwd_infix
module Types = Types
module State = State
module Controller = Controller
module Action = Action

let ( !! ) = Jstr.v
let sof x = Printf.sprintf "%.25f" x
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

let setup_gui_elem el gui =
  let coord =
    match Gui_tools.Syntax.parse (Jstr.to_string gui) with
    | Ok (x, _warnings) -> x
    | Error _ ->
        { x = None; y = None; scale = None; width = None; height = None }
  in
  Gui_tools.save_coord_el coord el;
  Gui_tools.apply_coord coord el;
  let () =
    match El.at !!Common_types.Special_strings.gui_loc el with
    | None -> ()
    | Some loc ->
        let _unlisten : Ev.listener =
          Ev.listen Ev.click
            (fun ev ->
              let loc =
                match
                  (El.at block_pos_attr el, Drawing_state.Status.peek ())
                with
                | None, _ | _, Gui_mode -> loc
                | Some loc, _ -> loc
              in
              Messaging.send_loc (Jstr.to_string loc);
              Ev.stop_propagation ev;
              if Drawing_state.Status.peek () = Gui_mode then
                Action.activate_el el)
            (El.as_target el)
        in
        ()
  in
  ()

let setup_non_gui_elem el =
  match El.at block_pos_attr el with
  | None -> ()
  | Some pos ->
      let _unlisten : Ev.listener =
        Ev.listen Ev.click
          (fun ev ->
            Ev.stop_propagation ev;
            Messaging.send_loc (Jstr.to_string pos))
          (El.as_target el)
      in
      ()

let setup_elem el =
  match El.at !!Common_types.Special_strings.gui el with
  | Some gui -> setup_gui_elem el gui
  | None -> setup_non_gui_elem el

let init window =
  let block_with_loc_selector =
    "[" ^ Common_types.Special_strings.original_loc ^ "]"
  in
  let gui_selector = "[" ^ Common_types.Special_strings.gui_loc ^ "]" in
  let () =
    El.fold_find_by_selector
      (fun el () -> setup_elem el)
      !!(block_with_loc_selector ^ "," ^ gui_selector)
      ()
  in
  let for_events = for_events window in
  let main =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
  in
  let _root = Elwd.append_child main for_events in
  ()
