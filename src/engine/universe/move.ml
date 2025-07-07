open Fut.Syntax
open Window

open struct
  module Window = Brr.Window
  module G = Brr.G
  module El = Brr.El
  module Ev = Brr.Ev
  module Console = Brr.Console
end

let move window target ~delay =
  let old_coordinate = State.get_coord () in
  let+ () = move_pure window target ~delay in
  let undo () = move_pure window old_coordinate ~delay in
  ((), undo)

let move_relative ?(x = 0.) ?(y = 0.) ?(scale = 1.) window ~delay =
  let coord = State.get_coord () in
  let dest =
    {
      Coordinates.x = coord.x +. x;
      y = coord.y +. y;
      scale = coord.scale *. scale;
    }
  in
  move window dest ~delay

let move_relative_pure ?(x = 0.) ?(y = 0.) ?(scale = 1.) window ~delay =
  move_relative ~x ~y ~scale window ~delay |> Undoable.discard

let focus ?(delay = 1.) ?(margin = 0.) window elems =
  let coords_e = List.map (Coord_computation.elem window) elems in
  let coords_e =
    List.map
      (fun (c : Coordinates.element) ->
        { c with width = c.width +. margin; height = c.height +. margin })
      coords_e
  in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.focus ~current coords_e in
  move window coords_w ~delay

let focus_pure ?margin window elem =
  focus ?margin window elem |> Undoable.discard

let enter window elem =
  let coords_e = Coord_computation.elem window elem in
  let coords_w = Coord_computation.Window.enter coords_e in
  move window coords_w ~delay:1.

let up window elem =
  let coords_e = Coord_computation.elem window elem in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.up ~current coords_e in
  move window coords_w ~delay:1.

let down window elem =
  let coords_e = Coord_computation.elem window elem in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.down ~current coords_e in
  move window coords_w ~delay:1.

let center window elem =
  let coords_e = Coord_computation.elem window elem in
  let current = State.get_coord () in
  let coords_w = Coord_computation.Window.center ~current coords_e in
  move window coords_w ~delay:1.

let scroll window elem =
  let coords_e = Coord_computation.elem window elem in
  let current = State.get_coord () in
  if
    coords_e.y -. (coords_e.height /. 2.)
    < current.y -. (Constants.height () /. 2. *. current.scale)
  then up window elem
  else if
    coords_e.y +. (coords_e.height /. 2.)
    > current.y +. (Constants.height () /. 2. *. current.scale)
  then down window elem
  else Undoable.return ()
