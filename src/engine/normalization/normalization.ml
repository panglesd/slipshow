open Brr
open Fut.Syntax
module Window = Brr.Window

let width = 1440.
let height = 1080.

type t = { open_window : El.t; format_container : El.t }

type state = {
  left : float;
  (* right : float; *)
  top : float;
  (* bottom : float; *)
  scale : float;
}

let state =
  ref { left = 0.; (* right = 0.; *) top = 0. (* ; bottom = 0. *); scale = 1. }

let translate_coords (x, y) =
  let x = (x -. !state.left) /. !state.scale
  and y = (y -. !state.top) /. !state.scale in
  let x = x -. (width /. 2.) and y = y -. (height /. 2.) in
  (x, y)

let replace_open_window window =
  let open_window = window.open_window in
  let set_state ~left ~right ~top ~bottom ~width ~height =
    state := { left; (* right; *) top; (* bottom; *) scale = !state.scale };
    Css.set
      [
        Left left;
        Right right;
        Width width;
        Top top;
        Bottom bottom;
        Height height;
      ]
      open_window
  in
  let foi = float_of_int in
  let browser_h = foi @@ Window.inner_height G.window in
  let browser_w = foi @@ Window.inner_width G.window in
  let* window_w, _window_h =
    if width *. browser_h < height *. browser_w then
      let window_w = browser_h *. width /. height in
      let window_h = browser_h in
      let+ () =
        set_state
          ~left:((browser_w -. window_w) /. 2.)
          ~right:((browser_w -. window_w) /. 2.)
          ~width:window_w ~height:window_h ~top:0. ~bottom:0.
      in
      (window_w, window_h)
    else
      let window_h = browser_w *. height /. width in
      let window_w = browser_w in
      let+ () =
        set_state
          ~top:((browser_h -. window_h) /. 2.)
          ~bottom:((browser_h -. window_h) /. 2.)
          ~height:window_h ~width:window_w ~right:0. ~left:0.
      in
      (window_w, window_h)
  in
  state := { !state with scale = window_w /. width };
  Css.set [ Scale (window_w /. width) ] window.format_container

let create el =
  let format_container =
    Brr.El.div ~at:[ Brr.At.class' (Jstr.v "format-container") ] []
  in
  let open_window =
    Brr.El.div ~at:[ Brr.At.id (Jstr.v "open-window") ] [ format_container ]
  in
  Brr.El.insert_siblings `Replace el [ open_window ];
  Brr.El.append_children format_container [ el ];
  { open_window; format_container }

let setup el =
  let open_window = create el in
  let* () = replace_open_window open_window in
  let resize _ = ignore @@ replace_open_window open_window in
  let _listener = Ev.listen Ev.resize resize (Window.as_target G.window) in
  Fut.tick ~ms:0
