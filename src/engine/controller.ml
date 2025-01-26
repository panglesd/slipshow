let keyboard_setup (window : Window.window) =
  let target = Brr.Window.as_target Brr.G.window in
  let callback ev =
    let key = ev |> Brr.Ev.as_type |> Brr.Ev.Keyboard.key |> Jstr.to_string in
    let current_coord = State.get_coord () in
    let () =
      match key with
      | "t" ->
          let body = Brr.Document.body Brr.G.document in
          let c = Jstr.v "slip-toc-mode" in
          Brr.El.set_class c (not @@ Brr.El.class' c body) body
      | "w" -> Drawing.State.set_tool Pen
      | "h" -> Drawing.State.set_tool Highlighter
      | "x" -> Drawing.State.set_tool Pointer
      | "e" -> Drawing.State.set_tool Eraser
      | "X" -> Drawing.clear ()
      | "l" ->
          let _ : unit Fut.t =
            Window.move_relative_pure
              ~x:(30. *. 1. /. current_coord.scale)
              window ~delay:0.
          in
          ()
      | "j" ->
          let _ : unit Fut.t =
            Window.move_relative_pure
              ~x:(-30. *. 1. /. current_coord.scale)
              window ~delay:0.
          in
          ()
      | "k" ->
          let _ : unit Fut.t =
            Window.move_relative_pure
              ~y:(30. *. 1. /. current_coord.scale)
              window ~delay:0.
          in
          ()
      | "i" ->
          let _ : unit Fut.t =
            Window.move_relative_pure
              ~y:(-30. *. 1. /. current_coord.scale)
              window ~delay:0.
          in
          ()
      | "ArrowRight" | "ArrowDown" | " " ->
          let _ : unit Fut.t = Next.go_next window 1 in
          ()
      | "ArrowLeft" | "ArrowUp" ->
          let _ : unit Fut.t = Next.go_prev window 1 in
          ()
      | "z" ->
          let _ : unit Fut.t =
            Window.move_relative_pure ~scale:1.02 window ~delay:0.
          in
          ()
      | "Z" ->
          let _ : unit Fut.t =
            Window.move_relative_pure ~scale:(1. /. 1.02) window ~delay:0.
          in
          ()
      | _ -> ()
    in
    Brr.Console.(log [ key ]);
    ()
  in
  let _listener = Brr.Ev.listen Brr.Ev.keydown callback target in
  ()

let touch_setup (window : Window.window) =
  let target = Brr.G.document |> Brr.Document.body |> Brr.El.as_target in
  let start = ref None in
  let coord_of_event ev =
    let mouse = Brr.Ev.as_type ev |> Brr.Ev.Pointer.as_mouse in
    let x = Brr.Ev.Mouse.client_x mouse and y = Brr.Ev.Mouse.client_y mouse in
    (x, y)
  in
  let check_condition ev f =
    let type_ = Brr.Ev.Pointer.type' (Brr.Ev.as_type ev) |> Jstr.to_string in
    if
      String.equal "touch" type_
      && Drawing.State.get_tool () = Drawing.Tool.Pointer
    then f ()
    else ()
  in
  let touchstart (ev : Brr.Ev.Pointer.t Brr.Ev.t) =
    Brr.Ev.prevent_default ev;
    Brr.Ev.stop_immediate_propagation ev;
    Brr.Ev.stop_propagation ev;
    check_condition ev @@ fun () -> start := Some (coord_of_event ev)
  in
  let opts = Brr.Ev.listen_opts ~passive:false () in
  let _listener = Brr.Ev.listen ~opts Brr.Ev.pointerdown touchstart target in
  let take_decision start (end_x, end_y) =
    match start with
    | None -> `None
    | Some (start_x, start_y) ->
        let mov_x, mov_y = (end_x -. start_x, end_y -. start_y) in
        let mov, abs, win =
          let abs_x = Float.abs mov_x and abs_y = Float.abs mov_y in
          let win_x = Brr.Window.inner_width Brr.G.window |> float_of_int in
          let win_y = Brr.Window.inner_height Brr.G.window |> float_of_int in
          if abs_x > abs_y then (mov_x, abs_x, win_x) else (mov_y, abs_y, win_y)
        in
        if abs /. win < 0.1 then `None
        else if mov <= 0. then `Forward
        else `Backward
  in
  let touchend (ev : Brr.Ev.Pointer.t Brr.Ev.t) =
    Brr.Ev.prevent_default ev;
    Brr.Ev.stop_immediate_propagation ev;
    Brr.Ev.stop_propagation ev;
    check_condition ev @@ fun () ->
    let end_ = coord_of_event ev in
    let () =
      match take_decision !start end_ with
      | `None -> ()
      | `Forward ->
          let _ : unit Fut.t = Next.go_next window 1 in
          ()
      | `Backward ->
          let _ : unit Fut.t = Next.go_prev window 1 in
          ()
    in
    start := None
  in
  let _listener = Brr.Ev.listen ~opts Brr.Ev.pointerup touchend target in

  ()

let setup (window : Window.window) =
  keyboard_setup window;
  touch_setup window
