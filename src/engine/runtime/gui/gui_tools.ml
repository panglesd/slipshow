open Brr
module Syntax = Actions_arguments.Gui

type t = Syntax.t = { x : int option; y : int option; scale : float option }

let ( !! ) = Jstr.v
let x_coord = El.Prop.int !!"slipshow-x-coord"
let y_coord = El.Prop.int !!"slipshow-y-coord"
let gui_prop = El.Prop.jstr !!"slipshow-y-coord"
let scale_coord = El.Prop.float !!"slipshow-scale-coord"
let get_x { x; _ } = Option.value ~default:0 x
let get_y { y; _ } = Option.value ~default:0 y
let get_scale { scale; _ } = Option.value ~default:1. scale

let coord_el el =
  let gui = El.prop gui_prop el |> Jstr.to_string in
  match Syntax.parse gui with
  | Ok (x, _warnings) -> x
  | Error _ -> { x = None; y = None; scale = None }

let save_coord_el coord el =
  let s = Syntax.to_string coord in
  El.set_prop gui_prop !!s el

let sof x = Printf.sprintf "%.25f" x
let soi x = string_of_int x

let transform_s c =
  let x = get_x c and y = get_y c and scale = get_scale c in
  "translate(" ^ soi x ^ "px, " ^ soi y ^ "px) scale(" ^ sof scale ^ ")"

let move window =
  let ( let> ) x f = Option.iter f x in
  let start _x _y _ev =
    let el = Lwd.peek State.current in
    let coord, scale =
      match el with
      | None -> ({ x = None; y = None; scale = None }, 1.)
      | Some el ->
          let scale0 = Universe.Window.scale_in_universe window el in
          let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
          let coord = coord_el el in
          (coord, Normalization.scale @@ (scale0 /. scale))
    in
    (el, coord, coord, scale)
  in
  let drag ~x:_ ~y:_ ~dx ~dy (el, _, coord0, scale) _ev =
    let dx = dx *. scale in
    let dy = dy *. scale in
    let x = Some (int_of_float dx + get_x coord0)
    and y = Some (int_of_float dy + get_y coord0) in
    let coord1 = { coord0 with x; y } in
    let () =
      let> el = el in
      let new_position = transform_s coord1 in
      El.set_inline_style !!"transform" !!new_position el
    in
    (el, coord1, coord0, scale)
  in
  let end_ (el, coord1, _coord0, _scale) _ev =
    let> el = el in
    let> id =
      El.prop El.Prop.id el |> Jstr.to_string |> function
      | "" -> None
      | s -> Some s
    in
    save_coord_el coord1 el;
    Messaging.send_gui_coordinate id coord1
  in
  Drawing_controller.Ui_widgets.mouse_drag start drag end_

(* let move window = *)
(*   let ( let> ) x f = Option.iter f x in *)
(*   let start _x _y _ev = *)
(*     let el = Lwd.peek State.current in *)
(*     let x0, y0, scale = *)
(*       match el with *)
(*       | None -> (0, 0, 1.) *)
(*       | Some el -> *)
(*           let scale0 = Universe.Window.scale_in_universe window el in *)
(*           let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in *)
(*           let x = El.prop x_coord el in *)
(*           let y = El.prop y_coord el in *)
(*           (x, y, Normalization.scale @@ (scale0 /. scale)) *)
(*     in *)
(*     (el, 0., 0., x0, y0, scale) *)
(*   in *)
(*   let drag ~x:_ ~y:_ ~dx ~dy (el, _, _, x0, y0, scale) _ev = *)
(*     let dx = dx *. scale in *)
(*     let dy = dy *. scale in *)
(*     let () = *)
(*       let> el = el in *)
(*       let new_position = *)
(*         transform_s (dx +. float_of_int x0) (dy +. float_of_int y0) *)
(*       in *)
(*       El.set_inline_style !!"transform" !!new_position el *)
(*     in *)
(*     (el, dx, dy, x0, y0, scale) *)
(*   in *)
(*   let end_ (el, dx, dy, x0, y0, _scale) _ev = *)
(*     let> el = el in *)
(*     let> id = *)
(*       El.prop El.Prop.id el |> Jstr.to_string |> function *)
(*       | "" -> None *)
(*       | s -> Some s *)
(*     in *)
(*     let dx = int_of_float dx in *)
(*     let dy = int_of_float dy in *)
(*     El.set_prop x_coord (dx + x0) el; *)
(*     El.set_prop y_coord (dy + y0) el; *)
(*     Messaging.send_gui_coordinate id (dx + x0) (dy + y0) *)
(*   in *)
(*   Drawing_controller.Ui_widgets.mouse_drag start drag end_ *)
