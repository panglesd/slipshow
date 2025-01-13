open Fut.Syntax

type mode = Normal | Moving | Drawing of Drawing.t

let string_of_mode mode =
  match mode with
  | Normal -> "Normal"
  | Moving -> "Moving"
  | Drawing _ -> "Drawing"

let setup ?initial_step (window : Window.window) =
  let svg =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing") |> Option.get
  in
  let target = Brr.Window.as_target Brr.G.window in
  let mode = ref Normal in
  let change_mode () =
    let () =
      match !mode with
      | Normal -> mode := Moving
      | Moving ->
          let listeners = Drawing.connect svg in
          mode := Drawing listeners
      | Drawing l ->
          Drawing.disconnect l;
          mode := Normal
    in
    Brr.Console.(log [ "mode is"; string_of_mode !mode ])
  in
  let all_undos = Stack.create () in
  let go_next () =
    match Next.next window () with
    | None -> Fut.return ()
    | Some undos ->
        let+ (), undos = undos in
        Stack.push undos all_undos
  in
  let+ () =
    match initial_step with
    | None -> Fut.return ()
    | Some n ->
        List.fold_left
          (fun acc () ->
            let* () = acc in
            go_next ())
          (Fut.return ())
          (List.init n (fun _ -> ()))
  in
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
            let+ () = go_next () in
            Messaging.send_step ()
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
          | Some undo ->
              let _ : unit Fut.t =
                let+ () = undo () in
                Messaging.send_step ()
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
