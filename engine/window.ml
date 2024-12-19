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

module Rescaling = struct
  let place_open_window open_window =
    let browser_height = Window.inner_height G.window in
    let browser_width = Window.inner_width G.window in
    let set attr n = El.set_inline_style attr (Css.Units.px_n n) open_window in
    if 4 * browser_height < 3 * browser_width then (
      let openWindowWidth = browser_height * 4 / 3 in
      let openWindowHeight = browser_height in
      set El.Style.left ((browser_width - openWindowWidth) / 2);
      set El.Style.right ((browser_width - openWindowWidth) / 2);
      set El.Style.width openWindowWidth;
      set El.Style.top 0;
      set El.Style.bottom 0;
      set El.Style.height openWindowHeight)
    else
      let openWindowHeight = browser_width * 3 / 4 in
      let openWindowWidth = browser_width in
      set El.Style.top ((browser_height - openWindowHeight) / 2);
      set El.Style.bottom ((browser_height - openWindowHeight) / 2);
      set El.Style.height openWindowHeight;
      set El.Style.width openWindowWidth;
      set El.Style.right 0;
      set El.Style.left 0

  let handle_rescaling open_window =
    place_open_window open_window;
    let resize _ = place_open_window open_window in
    let _listener = Ev.listen Ev.resize resize (Window.as_target G.window) in
    ()
end

let setup ?(width = 1440) ?(height = 1080) () =
  let find s = El.find_first_by_selector (Jstr.v s) |> Option.get in
  let open_window = find "#open-window"
  and rotate_container = find ".rotate-container"
  and scale_container = find ".scale-container"
  and universe = find "#universe" in
  Rescaling.handle_rescaling open_window;
  { rotate_container; scale_container; universe; height; width }

let move { scale_container; rotate_container; universe; width; height } ~x ~y
    ~scale ~rotate ~delay =
  let open Fut.Syntax in
  let foi = float_of_int in
  let* () = Css.set (Css.TransitionDuration delay) scale_container in
  let* () = Css.set (Css.TransitionDuration delay) rotate_container in
  let* () = Css.set (Css.TransitionDuration delay) universe in
  let left = -.((x *. foi width) -. (foi width /. 2.)) in
  let top = -.((y *. foi height) -. (foi height /. 2.)) in
  let* () = Css.set (Css.Left left) universe in
  let* () = Css.set (Css.Top top) universe in
  let* () = Css.set (Css.Scale (1. /. scale)) scale_container in
  let+ () = Css.set (Css.Rotate rotate) rotate_container in
  ()
