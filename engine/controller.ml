type mode = Normal | Moving

let setup (window : Window.window) =
  let target = Brr.Window.as_target Brr.G.window in
  let mode = ref Normal in
  let change_mode () =
    match !mode with Normal -> mode := Moving | Moving -> mode := Normal
  in
  let callback ev =
    let key = ev |> Brr.Ev.as_type |> Brr.Ev.Keyboard.key |> Jstr.to_string in
    let () =
      match key with
      | "m" -> change_mode ()
      | "ArrowRight" when !mode = Moving ->
          let _ : unit Fut.t =
            Window.move_relative
              ~x:(30. *. 1. /. window.coordinate.scale)
              window ~delay:0.
          in
          ()
      | "ArrowRight" ->
          let _ : unit Fut.t = Next.next () in
          ()
      | "ArrowLeft" ->
          let _ : unit Fut.t =
            Window.move_relative
              ~x:(-30. *. 1. /. window.coordinate.scale)
              window ~delay:0.
          in
          ()
      | "ArrowDown" ->
          let _ : unit Fut.t =
            Window.move_relative
              ~y:(30. *. 1. /. window.coordinate.scale)
              window ~delay:0.
          in
          ()
      | "ArrowUp" ->
          let _ : unit Fut.t =
            Window.move_relative
              ~y:(-30. *. 1. /. window.coordinate.scale)
              window ~delay:0.
          in
          ()
      | "z" ->
          let _ : unit Fut.t =
            Window.move_relative ~scale:1.02 window ~delay:0.
          in
          ()
      | "Z" ->
          let _ : unit Fut.t =
            Window.move_relative ~scale:(1. /. 1.02) window ~delay:0.
          in
          ()
      | _ -> ()
    in
    Brr.Console.(log [ key ]);
    ()
  in
  let _listener = Brr.Ev.listen Brr.Ev.keydown callback target in
  ()
