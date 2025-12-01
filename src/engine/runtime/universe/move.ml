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

let focus ?(margin = 0.) ?(duration = 1.) window elems =
  let coords_e = List.map (Coord_computation.elem window) elems in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.focus ~margin ~current coords_e in
  move window coords_w ~duration

let focus_pure ?margin window elem =
  focus ?margin window elem |> Undoable.discard

let enter ?(duration = 1.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let coords_w = Coord_computation.Window.enter coords_e in
  move window coords_w ~duration

let h_enter ?(duration = 1.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let coords_w = Coord_computation.Window.h_enter coords_e in
  move window coords_w ~duration

let up ?(margin = 1.5) ?(duration = 1.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.up ~margin ~current coords_e in
  move window coords_w ~duration

let down ?(margin = 1.5) ?(duration = 1.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.down ~margin ~current coords_e in
  move window coords_w ~duration

let center ?(duration = 1.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.center ~current coords_e in
  move window coords_w ~duration

let right ?(margin = 0.) ?(duration = 1.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.right ~margin ~current coords_e in
  move window coords_w ~duration

let left ?(margin = 0.) ?(duration = 1.) window elem =
  let coords_e = Coord_computation.elem window elem in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.left ~margin ~current coords_e in
  move window coords_w ~duration

let scroll ?(margin = 1.5) ?(duration = 1.) window elem =
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
