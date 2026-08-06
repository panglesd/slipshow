open Brr

let ( !! ) = Jstr.v
let x_coord = El.Prop.int !!"slipshow-x-coord"
let y_coord = El.Prop.int !!"slipshow-y-coord"
let sof x = Printf.sprintf "%.25f" x
let transform_s x y = "translate(" ^ sof x ^ "px, " ^ sof y ^ "px)"

let move window =
  let ( let> ) x f = Option.iter f x in
  let start _x _y _ev =
    let el = Lwd.peek State.current in
    let x0, y0, scale =
      match el with
      | None -> (0, 0, 1.)
      | Some el ->
          let scale0 = Universe.Window.scale_in_universe window el in
          let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
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
