open Brr
open Brr_lwd
open Lwd_infix
module Types = Types
module State = State
module Controller = Controller
module Action = Action

let ( !! ) = Jstr.v

let is_mac =
  let navigator = Navigator.user_agent G.navigator in
  let substrings = [ !!"Mac"; !!"iPod"; !!"iPhone"; !!"iPad" ] in
  List.exists (fun affix -> Jstr.includes ~affix navigator) substrings

let sof x = Printf.sprintf "%.25f" x
let gui_attr = !!Common_types.Special_strings.gui
let gui_file_attr = !!Common_types.Special_strings.gui_file
let gui_id_attr = !!Common_types.Special_strings.gui_id

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

let ( !? ) = Jstr.to_string

let is_gui el =
  match (El.at gui_attr el, El.at gui_file_attr el, El.at gui_id_attr el) with
  | Some coord, Some file, Some gui_id -> Some (!?coord, !?file, !?gui_id)
  | None, _, _ | _, None, _ | _, _, None -> None

let is_block el =
  match (El.at gui_file_attr el, El.at gui_id_attr el) with
  | Some file, Some gui_id -> Some (!?file, !?gui_id)
  | None, _ | _, None -> None

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

let send_loc ~file ~gui_id elem =
  match El.at At.Name.id elem with
  | None -> Messaging.send_loc (Loc { file; gui_id })
  | Some id -> Messaging.send_loc (Id !?id)

let handle_gui_el_up el =
  match find_up is_gui el with
  | None -> ()
  | Some (el, (_coord, file, gui_id)) ->
      let () = send_loc ~file ~gui_id el in
      if Drawing_state.Status.peek () = Gui_mode then Action.activate_el el

let handle_block_el_up el =
  match find_up is_block el with
  | None -> ()
  | Some (el, (file, gui_id)) -> send_loc ~file ~gui_id el

let handle is_ctrl_pressed el =
  let is_gui_selection =
    Drawing_state.Status.peek () = Gui_mode
    && Lwd.peek State.status = Types.Select
  in
  if Lwd.peek Drawing_state.can_gui then
    if is_ctrl_pressed then handle_block_el_up el
    else if is_gui_selection then handle_gui_el_up el
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
        let is_ctrl_pressed =
          ev |> Ev.as_type
          |> if is_mac then Ev.Mouse.meta_key else Ev.Mouse.ctrl_key
        in
        handle is_ctrl_pressed (el |> Ev.target_to_jv |> El.of_jv))
      (El.as_target main)
  in
  let for_events = for_events window in
  let _root = Elwd.append_child main for_events in
  ()
