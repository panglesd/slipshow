let start ~width ~height ~step =
  let open Fut.Syntax in
  let* _ : (unit, _) result =
    let window = Brr.G.window |> Brr.Window.to_jv in
    let do_pdf = Jv.get window "slipshow__do_pdf" in
    match Jv.defined do_pdf with
    | true -> Jv.apply do_pdf [||] |> Fut.of_promise ~ok:(fun _ -> ())
    | false -> Fut.return (Ok ())
  in
  Constants.set_height height;
  Constants.set_width width;
  let el =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-content") |> Option.get
  in
  (* let body = Brr.El.find_first_by_selector (Jstr.v "body") |> Option.get in *)
  let* () = Normalization.setup el in
  let* window = Universe.Window.setup el in
  (* TODO: move out of here (Later: Why?) *)
  let () = Rescale.setup_rescalers () in
  let () = Drawing_controller.Setup.init_ui () in
  let () = Mouse_disappearing.setup () in
  let initial_step =
    match step with
    | Some _ as step -> step
    | None ->
        Brr.G.window |> Brr.Window.location |> Brr.Uri.fragment
        |> Jstr.to_string |> int_of_string_opt
  in
  let _history = Browser.History.set_hash "" in
  let* () = Step.Action_scheduler.setup_actions window () in
  (* We do one step first, without recording it/updating the hash, to enter in
     the first slip *)
  let* _ =
    let mode = Fast.slow in
    Step.Action_scheduler.next ~mode window ()
    |> Option.value ~default:(Undoable.return ())
    |> Undoable.discard
  in
  let* () =
    (* For some reason, otherwise we things are not properly initialized during
       the toc computation *)
    Fut.tick ~ms:0
  in
  let* () = Table_of_content.generate window el in
  let* () =
    match initial_step with
    | None -> Fut.return @@ Step.Next.actualize 0
    | Some step ->
        Step.Next.go_to ~send_message:false ~mode:Fast.fast step window
  in
  let () = Controller.setup window in
  let () = Messaging.send_ready () in
  (* let () = Drawing_editor.init () in *)
  Fut.return ()

let () =
  let start width height step =
    let height = Jv.to_float height in
    let width = Jv.to_float width in
    let step = Jv.to_option Jv.to_int step in
    start ~width ~height ~step
  in
  Jv.set Jv.global "startSlipshow" (Jv.callback ~arity:3 start)
