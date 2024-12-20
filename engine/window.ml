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
  mutable coordinate : Coordinates.window;
}

let pp
    {
      scale_container;
      rotate_container;
      universe;
      width;
      height;
      coordinate = _;
    } =
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

let setup ~width ~height =
  let find s = El.find_first_by_selector (Jstr.v s) |> Option.get in
  let rotate_container = find ".rotate-container"
  and scale_container = find ".scale-container"
  and universe = find "#universe" in
  let* () = Css.set (Width (float_of_int width)) scale_container in
  let+ () = Css.set (Height (float_of_int height)) scale_container in
  let coordinate = { Coordinates.x = 0.; y = 0.; scale = 1. } in
  { rotate_container; scale_container; universe; height; width; coordinate }

let move window ({ x; y; scale } as target : Coordinates.window) ~delay =
  Console.(log [ "moving to"; x; y; scale; delay ]);
  window.coordinate <- target;
  let* () = Css.set (TransitionDuration delay) window.scale_container in
  let* () = Css.set (TransitionDuration delay) window.rotate_container in
  let* () = Css.set (TransitionDuration delay) window.universe in
  let left = -.x +. (float_of_int window.width /. 2.) in
  let top = -.y +. (float_of_int window.height /. 2.) in
  let* () = Css.set (Left left) window.universe in
  let* () = Css.set (Top top) window.universe in
  Css.set (Css.Scale scale) window.scale_container

let move_relative ?(x = 0.) ?(y = 0.) ?(scale = 1.) window ~delay =
  let dest =
    {
      Coordinates.x = window.coordinate.x +. x;
      y = window.coordinate.y +. y;
      scale = window.coordinate.scale *. scale;
    }
  in
  move window dest ~delay

let move_to window elem =
  let coords_e = Coordinates.get elem in
  let coords_w =
    Coordinates.Window_of_elem.focus
      ~win_height:(float_of_int window.height)
      ~win_width:(float_of_int window.width)
      coords_e
  in
  move window coords_w ~delay:1.
