let keyboard_setup (window : Universe.Window.t) =
  let target = Brr.Window.as_target Brr.G.window in
  let callback ev =
    let key = ev |> Brr.Ev.as_type |> Brr.Ev.Keyboard.key |> Jstr.to_string in
    let current_coord = Universe.State.get_coord () in
    let () =
      let check_modif_key modif f =
        if ev |> Brr.Ev.as_type |> modif then () else f ()
      in
      let check_textarea f =
        (* This checks that we are not typing in a text input, to allow for editing *)
        let is_editable active_elem =
          if Brr.El.is_content_editable active_elem then true
          else
            let tag_name =
              Brr.El.tag_name active_elem |> Jstr.lowercased |> Jstr.to_string
            in
            match tag_name with
            | "input" | "textarea" | "select" | "button" -> true
            | _ -> false
        in
        let active_elem = Brr.Document.active_el Brr.G.document in
        (* We need to go inside shadow roots to check if focused content is editable *)
        let rec check active_elem =
          match active_elem with
          | None -> f ()
          | Some active_elem -> (
              if is_editable active_elem then ()
              else
                match Brr.El.shadow_root active_elem with
                | None -> f ()
                | Some shadow_root ->
                    check (Brr.El.Shadow_root.active_element shadow_root))
        in
        check active_elem
      in
      check_modif_key Brr.Ev.Keyboard.ctrl_key @@ fun () ->
      check_modif_key Brr.Ev.Keyboard.meta_key @@ fun () ->
      check_textarea @@ fun () ->
      match key with
      | "s" -> Messaging.open_speaker_notes ()
      | "t" -> Table_of_content.toggle_visibility ()
      | "w" -> Drawing.State.set_tool Pen
      | "h" -> Drawing.State.set_tool Highlighter
      | "x" -> Drawing.State.set_tool Pointer
      | "e" -> Drawing.State.set_tool Eraser
      | "X" -> Drawing.clear ()
      | "l" ->
          let _ : unit Fut.t =
            Step.Next.Excursion.start ();
            Universe.Move.move_relative_pure
              ~x:(30. *. 1. /. current_coord.scale)
              window ~duration:0.
          in
          ()
      | "j" ->
          let _ : unit Fut.t =
            Step.Next.Excursion.start ();
            Universe.Move.move_relative_pure
              ~x:(-30. *. 1. /. current_coord.scale)
              window ~duration:0.
          in
          ()
      | "k" ->
          let _ : unit Fut.t =
            Step.Next.Excursion.start ();
            Universe.Move.move_relative_pure
              ~y:(30. *. 1. /. current_coord.scale)
              window ~duration:0.
          in
          ()
      | "i" ->
          let _ : unit Fut.t =
            Step.Next.Excursion.start ();
            Universe.Move.move_relative_pure
              ~y:(-30. *. 1. /. current_coord.scale)
              window ~duration:0.
          in
          ()
      | "ArrowRight" | "ArrowDown" | "PageDown" | " " ->
          let _ : unit Fut.t =
            let open Fut.Syntax in
            let+ () = Step.Next.go_next window 1 in
            Messaging.send_step (Step.State.get_step ()) `Normal
          in
          ()
      | "ArrowLeft" | "PageUp" | "ArrowUp" ->
          let _ : unit Fut.t =
            let open Fut.Syntax in
            let+ () = Step.Next.go_prev window 1 in
            Messaging.send_step (Step.State.get_step ()) `Normal
          in
          ()
      | "z" ->
          let _ : unit Fut.t =
            Step.Next.Excursion.start ();
            Universe.Move.move_relative_pure ~scale:1.02 window ~duration:0.
          in
          ()
      | "Z" ->
          let _ : unit Fut.t =
            Step.Next.Excursion.start ();
            Universe.Move.move_relative_pure ~scale:(1. /. 1.02) window
              ~duration:0.
          in
          ()
      | _ -> ()
    in
    Brr.Console.(log [ key ]);
    ()
  in
  let _listener = Brr.Ev.listen Brr.Ev.keydown callback target in
  ()

let touch_setup (window : Universe.Window.t) =
  let () =
    let next =
      Brr.El.find_first_by_selector (Jstr.v "#slip-touch-controls .slip-next")
      |> Option.get
    in
    let _unlisten =
      Brr.Ev.listen Brr.Ev.click
        (fun _ ->
          let _ : unit Fut.t = Step.Next.go_next window 1 in
          ())
        (Brr.El.as_target next)
    in
    ()
  in
  let () =
    let prev =
      Brr.El.find_first_by_selector
        (Jstr.v "#slip-touch-controls .slip-previous")
      |> Option.get
    in
    let _unlisten =
      Brr.Ev.listen Brr.Ev.click
        (fun _ ->
          let _ : unit Fut.t = Step.Next.go_prev window 1 in
          ())
        (Brr.El.as_target prev)
    in
    ()
  in
  let () =
    let fullscreen =
      Brr.El.find_first_by_selector
        (Jstr.v "#slip-touch-controls .slip-fullscreen")
      |> Option.get
    in
    let _unlisten =
      Brr.Ev.listen Brr.Ev.click
        (fun _ ->
          let body = Brr.Document.body Brr.G.document in
          let _ = Brr.El.request_fullscreen body in
          ())
        (Brr.El.as_target fullscreen)
    in
    ()
  in
  let target = Brr.G.document |> Brr.Document.body |> Brr.El.as_target in
  let touchstart (ev : Brr.Ev.Pointer.t Brr.Ev.t) =
    let type_ = Brr.Ev.Pointer.type' (Brr.Ev.as_type ev) |> Jstr.to_string in
    let body = Brr.Document.body Brr.G.document in
    if String.equal "touch" type_ then
      Brr.El.set_class (Jstr.v "mobile") true body;
    let stop_here () =
      Brr.Ev.prevent_default ev;
      Brr.Ev.stop_immediate_propagation ev;
      Brr.Ev.stop_propagation ev
    in
    if
      String.equal "touch" type_
      && Drawing.State.get_tool () = Drawing.Tool.Pointer
    then stop_here ()
  in
  let opts = Brr.Ev.listen_opts ~passive:false () in
  let _listener = Brr.Ev.listen ~opts Brr.Ev.pointerdown touchstart target in
  let touchend (ev : Brr.Ev.Pointer.t Brr.Ev.t) =
    let type_ = Brr.Ev.Pointer.type' (Brr.Ev.as_type ev) |> Jstr.to_string in
    let stop_here () =
      Brr.Ev.prevent_default ev;
      Brr.Ev.stop_immediate_propagation ev;
      Brr.Ev.stop_propagation ev
    in
    if
      String.equal "touch" type_
      && Drawing.State.get_tool () = Drawing.Tool.Pointer
    then stop_here ()
  in
  let _listener = Brr.Ev.listen ~opts Brr.Ev.pointerup touchend target in
  ()

let comm_of_jv m = m |> Jv.to_string |> Communication.of_string

let message_setup window =
  Brr.Ev.listen Brr_io.Message.Ev.message
    (fun event ->
      let raw_data : Jv.t = Brr_io.Message.Ev.data (Brr.Ev.as_type event) in
      let msg = comm_of_jv raw_data in
      match msg with
      | Some { payload = State (i, mode) } ->
          let fast = match mode with `Fast -> true | _ -> false in
          let _ : unit Fut.t =
            if fast then Fast.with_fast @@ fun () -> Step.Next.goto i window
            else Step.Next.goto i window
          in
          ()
      | Some { payload = Drawing d } -> (
          let if_state state f =
            match Drawing.State.of_string state with
            | None -> ()
            | Some state -> f state
          in
          match d with
          | End { state } ->
              if_state state @@ fun state -> Drawing.end_shape_func state
          | Continue { state; coord } ->
              if_state state @@ fun state ->
              Drawing.continue_shape_func state coord
          | Start { state; coord; id } ->
              if_state state @@ fun state ->
              Drawing.start_shape_func id state coord
          | Clear -> Drawing.clear_func ())
      | Some { payload = Send_all_drawing } -> Drawing.send_all_strokes ()
      | Some { payload = Receive_all_drawing all_strokes } ->
          Drawing.receive_all_strokes all_strokes
      | _ -> ())
    (Brr.Window.as_target Brr.G.window)
  |> ignore

let setup (window : Universe.Window.t) =
  keyboard_setup window;
  touch_setup window;
  message_setup window
