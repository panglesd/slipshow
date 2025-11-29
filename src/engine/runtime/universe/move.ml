open Fut.Syntax
open Window

open struct
  module Window = Brr.Window
  module G = Brr.G
  module El = Brr.El
  module Ev = Brr.Ev
  module Console = Brr.Console
end

let move window target ~duration =
  let old_coordinate = State.get_coord () in
  let+ () = move_pure window target ~duration in
  let undo () = move_pure window old_coordinate ~duration in
  ((), undo)

let move_relative ?(x = 0.) ?(y = 0.) ?(scale = 1.) window ~duration =
  let coord = State.get_coord () in
  let dest =
    {
      Coordinates.x = coord.x +. x;
      y = coord.y +. y;
      scale = coord.scale *. scale;
    }
  in
  move window dest ~duration

let move_relative_pure ?(x = 0.) ?(y = 0.) ?(scale = 1.) window ~duration =
  move_relative ~x ~y ~scale window ~duration |> Undoable.discard

let add_margin margin (c : Coordinates.element) =
  { c with width = c.width +. margin; height = c.height +. margin }

let focus ?(duration = 1.) ?(margin = 0.) window elems =
  let coords_e = List.map (Coord_computation.elem window) elems in
  let coords_e = List.map (add_margin margin) coords_e in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.focus ~current coords_e in
  move window coords_w ~duration

let focus_pure ?margin window elem =
  focus ?margin window elem |> Undoable.discard

let enter ?(duration = 1.) ?(margin = 0.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let coords_e = add_margin margin coords_e in
  let coords_w = Coord_computation.Window.enter coords_e in
  move window coords_w ~duration

let h_enter ?(duration = 1.) ?(margin = 0.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let coords_e = add_margin margin coords_e in
  let coords_w = Coord_computation.Window.h_enter coords_e in
  move window coords_w ~duration

let up ?(duration = 1.) ?(margin = 0.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let coords_e = add_margin margin coords_e in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.up ~current coords_e in
  move window coords_w ~duration

let down ?(duration = 1.) ?(margin = 0.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let coords_e = add_margin margin coords_e in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.down ~current coords_e in
  move window coords_w ~duration

let center ?(duration = 1.) ?(margin = 0.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let coords_e = add_margin margin coords_e in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.center ~current coords_e in
  move window coords_w ~duration

let right ?(duration = 1.) ?(margin = 0.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let coords_e = add_margin margin coords_e in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.right ~current coords_e in
  move window coords_w ~duration

let scroll ?(duration = 1.) ?(margin = 0.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let current = State.get_coord () in
  if
    coords_e.y -. (coords_e.height /. 2.)
    < current.y -. (Constants.height () /. 2. *. current.scale)
  then up window elem ~margin ~duration
  else if
    coords_e.y +. (coords_e.height /. 2.)
    > current.y +. (Constants.height () /. 2. *. current.scale)
  then down window elem ~margin ~duration
  else Undoable.return ()
