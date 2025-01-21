open struct
  module Window = Brr.Window
  module G = Brr.G
  module El = Brr.El
  module Ev = Brr.Ev
  module Console = Brr.Console
end

type window = {
  scale_container : Brr.El.t;
  rotate_container : Brr.El.t;
  universe : Brr.El.t;
}

let translate_coords (x0, y0) =
  let { Coordinates.x; y; scale } = State.get_coord () in
  let x1 = (x0 /. scale) +. x in
  let y1 = (y0 /. scale) +. y in
  (x1, y1)

let pp { scale_container; rotate_container; universe } =
  Console.(
    log
      [
        ("scale_container", scale_container);
        ("rotate_container", rotate_container);
        ("universe", universe);
      ])

open Fut.Syntax

let setup el =
  let open Brr in
  let universe =
    El.div
      ~at:[ At.class' (Jstr.v "universe movable"); At.id (Jstr.v "universe") ]
      []
  in
  let scale_container =
    El.div ~at:[ At.class' (Jstr.v "scale-container") ] [ universe ]
  in
  let rotate_container =
    El.div ~at:[ At.class' (Jstr.v "rotate-container") ] [ scale_container ]
  in
  Brr.El.insert_siblings `Replace el [ rotate_container ];
  Brr.El.append_children universe [ el ];
  let+ () =
    Css.set_pure
      [ Width Constants.width; Height Constants.height ]
      scale_container
  in
  { rotate_container; scale_container; universe }

let fast_move = ref false

let with_fast_moving f =
  fast_move := true;
  let+ () = f () in
  fast_move := false

let move_pure window ({ x; y; scale } as target : Coordinates.window) ~delay =
  let delay = if !fast_move then 0. else delay in
  State.set_coord target;
  let left = -.x +. (Constants.width /. 2.) in
  let top = -.y +. (Constants.height /. 2.) in
  let+ () = Css.set_pure [ TransitionDuration delay ] window.scale_container
  and+ () = Css.set_pure [ TransitionDuration delay ] window.rotate_container
  and+ () = Css.set_pure [ TransitionDuration delay ] window.universe
  and+ () = Css.set_pure [ Left left; Top top ] window.universe
  and+ () = Css.set_pure [ Css.Scale scale ] window.scale_container in
  ()

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
  move_relative ~x ~y ~scale window ~delay |> UndoMonad.discard

let focus window elem =
  let coords_e = Coordinates.get elem in
  let coords_w = Coordinates.Window_of_elem.focus coords_e in
  move window coords_w ~delay:1.

let focus_pure window elem = focus window elem |> UndoMonad.discard

let enter window elem =
  let coords_e = Coordinates.get elem in
  let coords_w = Coordinates.Window_of_elem.enter coords_e in
  move window coords_w ~delay:1.

let up window elem =
  let coords_e = Coordinates.get elem in
  let current = State.get_coord () in
  let coords_w = Coordinates.Window_of_elem.up ~current coords_e in
  move window coords_w ~delay:1.

let down window elem =
  let coords_e = Coordinates.get elem in
  let current = State.get_coord () in
  let coords_w = Coordinates.Window_of_elem.down ~current coords_e in
  move window coords_w ~delay:1.

let center window elem =
  let coords_e = Coordinates.get elem in
  let current = State.get_coord () in
  let coords_w = Coordinates.Window_of_elem.center ~current coords_e in
  move window coords_w ~delay:1.
