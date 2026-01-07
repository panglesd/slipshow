let keyboard_setup (global : Global_state.t) (window : Universe.Window.t) =
  let target = Brr.Window.as_target global.window in
  let callback ev =
    let key = ev |> Brr.Ev.as_type |> Brr.Ev.Keyboard.key |> Jstr.to_string in
    let current_coord = Universe.State.get_coord global in
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
        let active_elem =
          Brr.Document.active_el (Brr.Window.document global.window)
        in
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
      let try_handle handler k =
        match handler ev with true -> () | false -> k ()
      in
      try_handle (Drawing_controller.Controller.handle global) @@ fun () ->
      check_modif_key Brr.Ev.Keyboard.ctrl_key @@ fun () ->
      check_modif_key Brr.Ev.Keyboard.meta_key @@ fun () ->
      check_textarea @@ fun () ->
      match key with
      | "s" -> Messaging.open_speaker_notes global ()
      | "t" -> Table_of_content.toggle_visibility global.window
      | "l" ->
          let _ : unit Fut.t =
            Step.Next.Excursion.start global ();
            Universe.Move.move_relative_pure global
              ~x:(30. *. 1. /. current_coord.scale)
              window ~duration:0.
          in
          ()
      | "j" ->
          let _ : unit Fut.t =
            Step.Next.Excursion.start global ();
            Universe.Move.move_relative_pure global
              ~x:(-30. *. 1. /. current_coord.scale)
              window ~duration:0.
          in
          ()
      | "k" ->
          let _ : unit Fut.t =
            Step.Next.Excursion.start global ();
            Universe.Move.move_relative_pure global
              ~y:(30. *. 1. /. current_coord.scale)
              window ~duration:0.
          in
          ()
      | "i" ->
          let _ : unit Fut.t =
            Step.Next.Excursion.start global ();
            Universe.Move.move_relative_pure global
              ~y:(-30. *. 1. /. current_coord.scale)
              window ~duration:0.
          in
          ()
      | "ArrowRight" | "ArrowDown" | "PageDown" | " " ->
          let _ : unit Fut.t =
            let open Fut.Syntax in
            let+ _ : unit Fut.t = Step.Next.go_next global window in
            Messaging.send_step global (Step.State.get_step global) `Normal
          in
          ()
      | "ArrowLeft" | "PageUp" | "ArrowUp" ->
          let _ : unit Fut.t =
            let open Fut.Syntax in
            let+ () = Step.Next.go_prev global window in
            Messaging.send_step global (Step.State.get_step global) `Normal
          in
          ()
      | "z" ->
          let _ : unit Fut.t =
            Step.Next.Excursion.start global ();
            Universe.Move.move_relative_pure global ~scale:1.02 window
              ~duration:0.
          in
          ()
      | "Z" ->
          let _ : unit Fut.t =
            Step.Next.Excursion.start global ();
            Universe.Move.move_relative_pure global ~scale:(1. /. 1.02) window
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

let touch_setup (global : Global_state.t) (window : Universe.Window.t) =
  let global_root = global.window |> Brr.Window.document |> Brr.Document.body in
  let open Fut.Syntax in
  let () =
    let next =
      Brr.El.find_first_by_selector ~root:global_root
        (Jstr.v "#slip-touch-controls .slip-next")
      |> Option.get
    in
    let _unlisten =
      Brr.Ev.listen Brr.Ev.click
        (fun _ ->
          let _ : unit Fut.t =
            let+ _ : unit Fut.t = Step.Next.go_next global window in
            Messaging.send_step global (Step.State.get_step global) `Normal
          in
          ())
        (Brr.El.as_target next)
    in
    ()
  in
  let () =
    let prev =
      Brr.El.find_first_by_selector ~root:global_root
        (Jstr.v "#slip-touch-controls .slip-previous")
      |> Option.get
    in
    let _unlisten =
      Brr.Ev.listen Brr.Ev.click
        (fun _ ->
          let _ : unit Fut.t = Step.Next.go_prev global window in
          ())
        (Brr.El.as_target prev)
    in
    ()
  in
  let () =
    let fullscreen =
      Brr.El.find_first_by_selector ~root:global_root
        (Jstr.v "#slip-touch-controls .slip-fullscreen")
      |> Option.get
    in
    let _unlisten =
      Brr.Ev.listen Brr.Ev.click
        (fun _ ->
          let body = Brr.Document.body (Brr.Window.document global.window) in
          let _ = Brr.El.request_fullscreen body in
          ())
        (Brr.El.as_target fullscreen)
    in
    ()
  in
  let body = global.window |> Brr.Window.document |> Brr.Document.body in
  let target = Brr.El.as_target body in
  let touchstart (ev : Brr.Ev.Pointer.t Brr.Ev.t) =
    let type_ = Brr.Ev.Pointer.type' (Brr.Ev.as_type ev) |> Jstr.to_string in
    if String.equal "touch" type_ then
      Brr.El.set_class (Jstr.v "mobile") true body;
    let stop_here () =
      Brr.Ev.prevent_default ev;
      Brr.Ev.stop_immediate_propagation ev;
      Brr.Ev.stop_propagation ev
    in
    if
      String.equal "touch" type_
      && Lwd.peek Drawing_state.live_drawing_state.tool = Pointer
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
      && Lwd.peek Drawing_state.live_drawing_state.tool = Pointer
    then stop_here ()
  in
  let _listener = Brr.Ev.listen ~opts Brr.Ev.pointerup touchend target in
  ()

let comm_of_jv m = m |> Jv.to_string |> Communication.of_string

type ('a, 'b) dragger = {
  start : Drawing_state.strokes -> 'a -> float -> float -> 'b;
  drag : x:float -> y:float -> dx:float -> dy:float -> 'b -> 'b;
  end_ : 'b -> unit;
}

let handle_drag (dragger : (_, 'b) dragger) =
  let acc : 'b option ref = ref None in
  let strokes = Drawing_state.workspaces.live_drawing in
  fun (s : 'a Drawing_controller.Messages.drag_event) ->
    match s with
    | Start (arg, x, y) ->
        let res = dragger.start strokes arg x y in
        acc := Some res
    | Drag { x; y; dx; dy } -> (
        match !acc with
        | None -> ()
        | Some acc' ->
            let res = dragger.drag ~x ~y ~dx ~dy acc' in
            acc := Some res)
    | End -> (
        match !acc with
        | None -> ()
        | Some acc' ->
            dragger.end_ acc';
            acc := None)

let draw_stroke_dragger global =
  let open Drawing_controller.Tools.Draw_stroke in
  let start = start global ~replaying_state:None in
  let drag = drag global in
  { start; drag; end_ }

let erase_dragger global =
  let open Drawing_controller.Tools.Erase in
  let start = start ~replayed_strokes:None in
  let drag = drag global in
  { start; drag; end_ }

let handle_erase global = handle_drag (erase_dragger global)
let handle_draw_stroke global = handle_drag (draw_stroke_dragger global)

let handle_drawing global d =
  let modu = Drawing_controller.Messages.event_of_string d in
  match modu with
  | Some (Draw s) -> handle_draw_stroke global s
  | Some (Erase s) -> handle_erase global s
  | Some (Clear started_time) ->
      Drawing_controller.Tools.Clear.clear global ~replayed_strokes:None
        started_time Drawing_state.workspaces.live_drawing
  | None ->
      Brr.Console.(
        error [ "There was an error when decoding a drawing message: "; d ])

let message_setup global window =
  Brr.Ev.listen Brr_io.Message.Ev.message
    (fun event ->
      let raw_data : Jv.t = Brr_io.Message.Ev.data (Brr.Ev.as_type event) in
      let msg = comm_of_jv raw_data in
      match msg with
      | Some { payload = State (i, mode); id = _ } ->
          let fast = match mode with `Fast -> true | _ -> false in
          let _ : unit Fut.t =
            if fast then
              Fast.with_fast @@ fun () -> Step.Next.goto global i window
            else Step.Next.goto global i window
          in
          ()
      | Some { payload = Drawing d; id = _window_id } -> handle_drawing global d
      | Some { payload = Send_all_drawing; id = _ } ->
          Drawing_controller.Messages.send_all_strokes global ()
      | Some { payload = Receive_all_drawing all_strokes; id = _ } ->
          Drawing_controller.Messages.receive_all_strokes all_strokes
      | _ -> ())
    (Brr.Window.as_target global.window)
  |> ignore

let setup global (window : Universe.Window.t) =
  keyboard_setup global window;
  touch_setup global window;
  message_setup global window
