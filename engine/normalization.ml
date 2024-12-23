open Brr
open Fut.Syntax
module Window = Brr.Window

type t = { open_window : El.t; format_container : El.t }

let replace_open_window window =
  let open_window = window.open_window in
  let foi = float_of_int in
  let browser_h = foi @@ Window.inner_height G.window in
  let browser_w = foi @@ Window.inner_width G.window in
  let* window_w, _window_h =
    if Constants.width *. browser_h < Constants.height *. browser_w then
      let window_w = browser_h *. Constants.width /. Constants.height in
      let window_h = browser_h in
      let+ () =
        Css.set_pure
          [
            Left ((browser_w -. window_w) /. 2.);
            Right ((browser_w -. window_w) /. 2.);
            Width window_w;
            Top 0.;
            Bottom 0.;
            Height window_h;
          ]
          open_window
      in
      (window_w, window_h)
    else
      let window_h = browser_w *. Constants.height /. Constants.width in
      let window_w = browser_w in
      let+ () =
        Css.set_pure
          [
            Top ((browser_h -. window_h) /. 2.);
            Bottom ((browser_h -. window_h) /. 2.);
            Height window_h;
            Width window_w;
            Right 0.;
            Left 0.;
          ]
          open_window
      in
      (window_w, window_h)
  in
  Css.set_pure [ Scale (window_w /. Constants.width) ] window.format_container

let create () =
  let find s =
    match El.find_first_by_selector (Jstr.v s) with
    | Some s -> s
    | None -> failwith ("No element with '" ^ s ^ "' id. Cannot continue.")
  in
  let open_window = find "#open-window"
  and format_container = find ".format-container" in
  { open_window; format_container }

let setup () =
  let open_window = create () in
  let+ () = replace_open_window open_window in
  let resize _ = ignore @@ replace_open_window open_window in
  let _listener = Ev.listen Ev.resize resize (Window.as_target G.window) in
  ()
