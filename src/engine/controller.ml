let setup (window : Window.window) =
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
  let mobile_callback (ev : Brr.Ev.Pointer.t Brr.Ev.t) =
    let type_ = Brr.Ev.Pointer.type' (Brr.Ev.as_type ev) |> Jstr.to_string in
    if String.equal "touch" type_ then
      let _ : unit Fut.t = Next.go_next window 1 in
      ()
    else ()
  in
  let _listener = Brr.Ev.listen Brr.Ev.pointerup mobile_callback target in
  ()
