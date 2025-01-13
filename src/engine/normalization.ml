open Brr
open Fut.Syntax
module Window = Brr.Window

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
  let x = x -. (Constants.width /. 2.) and y = y -. (Constants.height /. 2.) in
  (x, y)

let replace_open_window window =
  let open_window = window.open_window in
  let set_state ~left ~right ~top ~bottom ~width ~height =
    state := { left; (* right; *) top; (* bottom; *) scale = !state.scale };
    Css.set_pure
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
    if Constants.width *. browser_h < Constants.height *. browser_w then
      let window_w = browser_h *. Constants.width /. Constants.height in
      let window_h = browser_h in
      let+ () =
        set_state
          ~left:((browser_w -. window_w) /. 2.)
          ~right:((browser_w -. window_w) /. 2.)
          ~width:window_w ~height:window_h ~top:0. ~bottom:0.
      in
      (window_w, window_h)
    else
      let window_h = browser_w *. Constants.height /. Constants.width in
      let window_w = browser_w in
      let+ () =
        set_state
          ~top:((browser_h -. window_h) /. 2.)
          ~bottom:((browser_h -. window_h) /. 2.)
          ~height:window_h ~width:window_w ~right:0. ~left:0.
      in
      (window_w, window_h)
  in
  state := { !state with scale = window_w /. Constants.width };
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
