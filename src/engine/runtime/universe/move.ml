open Fut.Syntax
open Window

open struct
  module Window = Brr.Window
  module G = Brr.G
  module El = Brr.El
  module Ev = Brr.Ev
  module Console = Brr.Console
end

let move global window target ~duration =
  let old_coordinate = State.get_coord global in
  let+ () = move_pure global window target ~duration in
  let undo () = move_pure global window old_coordinate ~duration in
  ((), undo)

let move_relative global ?(x = 0.) ?(y = 0.) ?(scale = 1.) window ~duration =
  let coord = State.get_coord global in
  let dest =
    {
      Coordinates.x = coord.x +. x;
      y = coord.y +. y;
      scale = coord.scale *. scale;
    }
  in
  move global window dest ~duration

let move_relative_pure global ?(x = 0.) ?(y = 0.) ?(scale = 1.) window ~duration
    =
  move_relative global ~x ~y ~scale window ~duration |> Undoable.discard

let add_margin margin (c : Coordinates.element) =
  { c with width = c.width +. margin; height = c.height +. margin }

let focus global ?(duration = 1.) ?(margin = 0.) window elems =
  let coords_e = List.map (Coord_computation.elem global window) elems in
  let coords_e = List.map (add_margin margin) coords_e in
  let current = State.get_coord global in
  let coords_w = Coord_computation.Window.focus global ~current coords_e in
  move global window coords_w ~duration

let focus_pure global ?margin window elem =
  focus global ?margin window elem |> Undoable.discard

let enter global ?(duration = 1.) ?(margin = 0.) window elem =
  let coords_e = Coord_computation.elem global window elem in
  let coords_e = add_margin margin coords_e in
  let coords_w = Coord_computation.Window.enter global coords_e in
  move global window coords_w ~duration

let up global ?(duration = 1.) ?(margin = 0.) window elem =
  let coords_e = Coord_computation.elem global window elem in
  let coords_e = add_margin margin coords_e in
  let current = State.get_coord global in
  let coords_w = Coord_computation.Window.up global ~current coords_e in
  move global window coords_w ~duration

let down global ?(duration = 1.) ?(margin = 0.) window elem =
  let coords_e = Coord_computation.elem global window elem in
  let coords_e = add_margin margin coords_e in
  let current = State.get_coord global in
  let coords_w = Coord_computation.Window.down global ~current coords_e in
  move global window coords_w ~duration

let center global ?(duration = 1.) ?(margin = 0.) window elem =
  let coords_e = Coord_computation.elem global window elem in
  let coords_e = add_margin margin coords_e in
  let current = State.get_coord global in
  let coords_w = Coord_computation.Window.center global ~current coords_e in
  move global window coords_w ~duration

let scroll global ?(duration = 1.) ?(margin = 0.) window elem =
  let coords_e = Coord_computation.elem global window elem in
  let current = State.get_coord global in
  if
    coords_e.y -. (coords_e.height /. 2.)
    < current.y -. (global.height /. 2. *. current.scale)
  then up global window elem ~margin ~duration
  else if
    coords_e.y +. (coords_e.height /. 2.)
    > current.y +. (global.height /. 2. *. current.scale)
  then down global window elem ~margin ~duration
  else Undoable.return ()
