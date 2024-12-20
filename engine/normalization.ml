open Brr
open Fut.Syntax
module Window = Brr.Window

type t = {
  open_window : El.t;
  format_container : El.t;
  width : int;
  height : int;
}

let replace_open_window window =
  let open_window = window.open_window in
  let browser_h = Window.inner_height G.window in
  let browser_w = Window.inner_width G.window in
  let foi = float_of_int in
  let* window_w, _window_h =
    if window.width * browser_h < window.height * browser_w then
      let window_w = browser_h * window.width / window.height in
      let window_h = browser_h in
      let* () = Css.set (Left (foi (browser_w - window_w) /. 2.)) open_window in
      let* () =
        Css.set (Right (foi (browser_w - window_w) /. 2.)) open_window
      in
      let* () = Css.set (Width (foi window_w)) open_window in
      let* () = Css.set (Top 0.) open_window in
      let* () = Css.set (Bottom 0.) open_window in
      let+ () = Css.set (Height (foi window_h)) open_window in
      (window_w, window_h)
    else
      let window_h = browser_w * window.height / window.width in
      let window_w = browser_w in
      let* () = Css.set (Top (foi (browser_h - window_h) /. 2.)) open_window in
      let* () =
        Css.set (Bottom (foi (browser_h - window_h) /. 2.)) open_window
      in
      let* () = Css.set (Height (foi window_h)) open_window in
      let* () = Css.set (Width (foi window_w)) open_window in
      let* () = Css.set (Right 0.) open_window in
      let+ () = Css.set (Left 0.) open_window in
      (window_w, window_h)
  in
  Css.set (Scale (foi window_w /. foi window.width)) window.format_container

let create ~width ~height =
  let find s =
    match El.find_first_by_selector (Jstr.v s) with
    | Some s -> s
    | None -> failwith ("No element with '" ^ s ^ "' id. Cannot continue.")
  in
  let open_window = find "#open-window"
  and format_container = find ".format-container" in
  { open_window; format_container; width; height }

let setup ~width ~height =
  let open_window = create ~width ~height in
  let+ () = replace_open_window open_window in
  let resize _ = ignore @@ replace_open_window open_window in
  let _listener = Ev.listen Ev.resize resize (Window.as_target G.window) in
  ()
