open Brr
module Syntax = Actions_arguments.Gui

type t = Syntax.t = {
  x : int option;
  y : int option;
  scale : float option;
  width : int option;
  height : int option;
}

let ( !! ) = Jstr.v
let gui_prop = El.Prop.jstr !!"slipshow-gui-coord"
let get_x { x; _ } = Option.value ~default:0 x
let get_y { y; _ } = Option.value ~default:0 y
let get_scale { scale; _ } = Option.value ~default:1. scale

let get_width el { width; _ } =
  match width with
  | Some width -> width
  | None ->
      El.computed_style !!"width" el |> Jstr.to_int |> Option.value ~default:100

let get_height el { height; _ } =
  match height with
  | Some height -> height
  | None ->
      El.computed_style !!"height" el
      |> Jstr.to_int |> Option.value ~default:100

let coord_el el =
  let gui = El.prop gui_prop el |> Jstr.to_string in
  match Syntax.parse gui with
  | Ok (x, _warnings) -> x
  | Error _ -> { x = None; y = None; scale = None; width = None; height = None }

let save_coord_el coord el =
  let s = Syntax.to_string coord in
  El.set_prop gui_prop !!s el

let sof x = Printf.sprintf "%.25f" x
let soi x = string_of_int x

let apply_coord c el =
  let x = get_x c and y = get_y c and scale = get_scale c in
  let s =
    "translate(" ^ soi x ^ "px, " ^ soi y ^ "px) scale(" ^ sof scale ^ ")"
  in
  El.set_inline_style !!"transform" !!s el;
  El.set_inline_style !!"transform-origin" !!"top left" el;
  let () =
    match c.width with
    | None -> ()
    | Some w ->
        let s = soi w ^ "px" in
        El.set_inline_style !!"width" !!s el
  in
  let () =
    match c.height with
    | None -> ()
    | Some h ->
        let s = soi h ^ "px" in
        El.set_inline_style !!"height" !!s el
  in
  ()

(* None that the "id first then gui_id" is "duplicated" in [gui.ml]. (Just in
   case future me decides to change it) *)
let get_loc_id el =
  let id =
    El.prop El.Prop.id el |> Jstr.to_string |> function
    | "" -> None
    | s -> Some s
  in
  let file =
    El.at !!Common_types.Special_strings.gui_file el
    |> Option.map Jstr.to_string
  in
  let gui_id =
    El.at !!Common_types.Special_strings.gui_id el |> Option.map Jstr.to_string
  in
  match (id, file, gui_id) with
  | Some id, _, _ -> Some (Common_types.Id id)
  | _, Some file, Some gui_id -> Some (Loc { file; gui_id })
  | None, None, _ | None, _, None -> None

let move window =
  let ( let> ) x f = Option.iter f x in
  let start _x _y _ev =
    let el = Lwd.peek State.current in
    let coord, factor =
      match el with
      | None ->
          ({ x = None; y = None; scale = None; width = None; height = None }, 1.)
      | Some el ->
          let scale0 = Universe.Window.scale_in_universe window el in
          let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
          let coord = coord_el el in
          (coord, Normalization.scale @@ (1. /. (scale0 *. scale)))
    in
    (el, coord, coord, factor)
  in
  let drag ~x:_ ~y:_ ~dx ~dy (el, _, coord0, factor) _ev =
    (* translate precedes scale... *)
    let parent_factor = factor *. get_scale coord0 in
    let dx = dx *. parent_factor in
    let dy = dy *. parent_factor in
    let x = Some (int_of_float dx + get_x coord0)
    and y = Some (int_of_float dy + get_y coord0) in
    let coord1 = { coord0 with x; y } in
    let () =
      let> el = el in
      apply_coord coord1 el
    in
    (el, coord1, coord0, factor)
  in
  let end_ (el, coord1, _coord0, _factor) _ev =
    let> el = el in
    let> id = get_loc_id el in
    save_coord_el coord1 el;
    Messaging.send_gui_coordinate id coord1
  in
  Drawing_controller.Ui_widgets.mouse_drag start drag end_

let scale window =
  let ( let> ) x f = Option.iter f x in
  let start _x _y _ev =
    let el = Lwd.peek State.current in
    let coord, factor =
      match el with
      | None ->
          ( { x = None; y = None; scale = None; width = None; height = None },
            (0., 0.) )
      | Some el ->
          let scale0 = Universe.Window.scale_in_universe window el in
          let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
          let coord = coord_el el in
          let factor = Normalization.scale @@ (1. /. (scale0 *. scale)) in
          let per_px size =
            if size = 0 then 0. else factor /. float_of_int size
          in
          (coord, (per_px (get_width el coord), per_px (get_height el coord)))
    in
    (el, coord, coord, factor)
  in
  let drag ~x:_ ~y:_ ~dx ~dy (el, _, coord0, ((fw, fh) as factor)) _ev =
    let s = get_scale coord0 in
    (* pfiou! *)
    let diff = ((dx *. fw) +. (dy *. fh)) *. s /. 2. in
    let scale_coord = Some (Float.max 0.01 (s +. diff)) in
    let coord1 = { coord0 with scale = scale_coord } in
    let () =
      let> el = el in
      apply_coord coord1 el
    in
    (el, coord1, coord0, factor)
  in
  let end_ (el, coord1, _coord0, _factor) _ev =
    let> el = el in
    let> id = get_loc_id el in
    save_coord_el coord1 el;
    Messaging.send_gui_coordinate id coord1
  in
  Drawing_controller.Ui_widgets.mouse_drag start drag end_

let dimension window =
  let ( let> ) x f = Option.iter f x in
  let ( let+ ) x f = Option.map f x in
  let start _x _y _ev =
    let el = Lwd.peek State.current in
    let+ el = el in
    let coord, factor =
      let scale0 = Universe.Window.scale_in_universe window el in
      let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
      let coord = coord_el el in
      (coord, Normalization.scale @@ (1. /. (scale0 *. scale)))
    in
    let coord0 =
      let w0 = get_width el coord and h0 = get_height el coord in
      (w0, h0)
    in
    (el, coord, coord0, factor)
  in
  let drag ~x:_ ~y:_ ~dx ~dy acc _ev =
    let+ el, coord, ((w0, h0) as coord0), factor = acc in
    let dx = dx *. factor in
    let dy = dy *. factor in
    let width = Some (int_of_float dx + w0)
    and height = Some (int_of_float dy + h0) in
    let coord = { coord with width; height } in
    let () = apply_coord coord el in
    (el, coord, coord0, factor)
  in
  let end_ acc _ev =
    let> el, coord1, _coord0, _scale = acc in
    let> id = get_loc_id el in
    save_coord_el coord1 el;
    Messaging.send_gui_coordinate id coord1
  in
  Drawing_controller.Ui_widgets.mouse_drag start drag end_
