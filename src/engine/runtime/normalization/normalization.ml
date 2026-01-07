open Brr
open Fut.Syntax
module Window = Brr.Window
(* open Constants *)

type t = { open_window : El.t; format_container : El.t }

type state = Global_state.Predef.normalization = {
  left : float;
  top : float;
  scale : float;
}

let translate_coords (global : Global_state.t) (x, y) =
  let x =
    (x -. global.normalization_state.left) /. global.normalization_state.scale
  and y =
    (y -. global.normalization_state.top) /. global.normalization_state.scale
  in
  let x = x -. (global.width /. 2.) and y = y -. (global.height /. 2.) in
  (x, y)

let replace_open_window (global : Global_state.t) window =
  let open_window = window.open_window in
  let set_state ~left ~right ~top ~bottom ~width ~height =
    global.normalization_state <-
      { left; top; scale = global.normalization_state.scale };
    Browser.Css.set
      [
        Left left;
        Right right;
        Width width;
        Top top;
        Bottom bottom;
        Height height;
      ]
      open_window;
    Fut.tick ~ms:0
  in
  let foi = float_of_int in
  let parent = Brr.El.parent open_window |> Option.get in
  let browser_h = foi @@ Brr.El.offset_h parent in
  let browser_w = foi @@ Brr.El.offset_w parent in
  let* window_w, _window_h =
    let body = Brr.Document.body (Brr.Window.document global.window) in
    if global.width *. browser_h < global.height *. browser_w then
      let () =
        Brr.El.set_class (Jstr.v "horizontal") false body;
        Brr.El.set_class (Jstr.v "vertical") true body
      in
      let window_w = browser_h *. global.width /. global.height in
      let window_h = browser_h in
      let+ () =
        set_state
          ~left:((browser_w -. window_w) /. 2.)
          ~right:((browser_w -. window_w) /. 2.)
          ~width:window_w ~height:window_h ~top:0. ~bottom:0.
      in
      (window_w, window_h)
    else
      let () =
        Brr.El.set_class (Jstr.v "horizontal") true body;
        Brr.El.set_class (Jstr.v "vertical") false body
      in
      let window_h = browser_w *. global.height /. global.width in
      let window_w = browser_w in
      let+ () =
        set_state
          ~top:((browser_h -. window_h) /. 2.)
          ~bottom:((browser_h -. window_h) /. 2.)
          ~height:window_h ~width:window_w ~right:0. ~left:0.
      in
      (window_w, window_h)
  in
  global.normalization_state <-
    { global.normalization_state with scale = window_w /. global.width };
  Browser.Css.set [ Scale (window_w /. global.width) ] window.format_container;
  Fut.tick ~ms:0

let create el =
  let format_container =
    Brr.El.div ~at:[ Brr.At.class' (Jstr.v "slipshow-format-container") ] []
  in
  let open_window =
    Brr.El.div
      ~at:[ Brr.At.id (Jstr.v "slipshow-open-window") ]
      [ format_container ]
  in
  Brr.El.insert_siblings `Replace el [ open_window ];
  Brr.El.append_children format_container [ el ];
  { open_window; format_container }

let setup (global : Global_state.t) el =
  let open_window = create el in
  let* () = replace_open_window global open_window in
  let resize_observer =
    Brr.ResizeObserver.create (fun _ _ ->
        ignore @@ replace_open_window global open_window)
  in
  let parent = Brr.El.parent open_window.open_window |> Option.get in
  let _unobser = Brr.ResizeObserver.observe resize_observer parent in
  Fut.tick ~ms:0

let scale (global : Global_state.t) f = f /. global.normalization_state.scale
