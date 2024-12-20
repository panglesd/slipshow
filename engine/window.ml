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
  width : int;
  height : int;
}

let pp { scale_container; rotate_container; universe; width; height } =
  Console.(
    log
      [
        ("scale_container", scale_container);
        ("rotate_container", rotate_container);
        ("universe", universe);
        ("width", width);
        ("height", height);
      ])

open Fut.Syntax
module Rescaling = struct end

let setup ~width ~height =
  let find s = El.find_first_by_selector (Jstr.v s) |> Option.get in
  let rotate_container = find ".rotate-container"
  and scale_container = find ".scale-container"
  and universe = find "#universe" in
  let* () = Css.set (Width (float_of_int width)) scale_container in
  let+ () = Css.set (Height (float_of_int height)) scale_container in
  { rotate_container; scale_container; universe; height; width }

let move { scale_container; rotate_container; universe; width; height }
    ({ x; y; scale } : Coordinates.window) ~delay =
  Console.(log [ "moving to"; x; y; scale; delay ]);
  let* () = Css.set (TransitionDuration delay) scale_container in
  let* () = Css.set (TransitionDuration delay) rotate_container in
  let* () = Css.set (TransitionDuration delay) universe in
  let left = -.x +. (float_of_int width /. 2.) in
  let top = -.y +. (float_of_int height /. 2.) in
  let* () = Css.set (Left left) universe in
  let* () = Css.set (Top top) universe in
  Css.set (Css.Scale scale) scale_container

let move_to window elem =
  let coords_e = Coordinates.get elem in
  let coords_w =
    Coordinates.Window_of_elem.focus
      ~win_height:(float_of_int window.height)
      ~win_width:(float_of_int window.width)
      coords_e
  in
  move window coords_w ~delay:1.
