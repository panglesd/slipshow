open Fut.Syntax

type mode = Normal | Moving

let setup (window : Window.window) =
  let target = Brr.Window.as_target Brr.G.window in
  let mode = ref Normal in
  let change_mode () =
    match !mode with Normal -> mode := Moving | Moving -> mode := Normal
  in
  let all_undos = Stack.create () in
  let callback ev =
    let key = ev |> Brr.Ev.as_type |> Brr.Ev.Keyboard.key |> Jstr.to_string in
    let current_coord = State.get_coord () in
    let () =
      match key with
      | "m" -> change_mode ()
      | "ArrowRight" when !mode = Moving ->
          let _ : unit Fut.t =
            Window.move_relative_pure
              ~x:(30. *. 1. /. current_coord.scale)
              window ~delay:0.
          in
          ()
      | "ArrowRight" ->
          let _ : unit Fut.t =
            let+ (), undos = Next.next window () in
            Stack.push undos all_undos
          in
          ()
      | "ArrowLeft" when !mode = Moving ->
          let _ : unit Fut.t =
            Window.move_relative_pure
              ~x:(-30. *. 1. /. current_coord.scale)
              window ~delay:0.
          in
          ()
      | "ArrowLeft" -> (
          match Stack.pop_opt all_undos with
          | None -> ()
          | Some undos ->
              let _ : unit Fut.t =
                List.fold_left
                  (fun acc f ->
                    let* () = acc in
                    f ())
                  (Fut.return ()) undos
              in
              ())
      | "ArrowDown" ->
          let _ : unit Fut.t =
            Window.move_relative_pure
              ~y:(30. *. 1. /. current_coord.scale)
              window ~delay:0.
          in
          ()
      | "ArrowUp" ->
          let _ : unit Fut.t =
            Window.move_relative_pure
              ~y:(-30. *. 1. /. current_coord.scale)
              window ~delay:0.
          in
          ()
      | "a" ->
          let _ : unit Fut.t =
            let+ (), undos =
              Window.move_relative
                ~y:(-30. *. 1. /. current_coord.scale)
                window ~delay:0.
            in
            Stack.push undos all_undos
          in
          ()
      | "q" ->
          let _ : unit Fut.t =
            let+ (), undos =
              Window.move_relative
                ~y:(30. *. 1. /. current_coord.scale)
                window ~delay:0.
            in
            Stack.push undos all_undos
          in
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
