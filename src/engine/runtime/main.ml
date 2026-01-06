open Brr

let start ~window ~width ~height ~step =
  let open Fut.Syntax in
  let* _ : (unit, _) result =
    let window = Window.to_jv window in
    let do_pdf = Jv.get window "slipshow__do_pdf" in
    match Jv.defined do_pdf with
    | true -> Jv.apply do_pdf [||] |> Fut.of_promise ~ok:(fun _ -> ())
    | false -> Fut.return (Ok ())
  in
  Constants.set_height height;
  Constants.set_width width;
  let el =
    let root = window |> Window.document |> Document.body in
    El.find_first_by_selector ~root (Jstr.v "#slipshow-content") |> Option.get
  in
  (* let body = Brr.El.find_first_by_selector (Jstr.v "body") |> Option.get in *)
  let global = window in
  let* () = Normalization.setup global el in
  let* sliding_window = Universe.Window.setup el in
  (* TODO: move out of here (Later: Why?) *)
  let () = Rescale.setup_rescalers () in
  let () = Drawing_controller.Setup.init_ui global () in
  let () = Mouse_disappearing.setup window in
  let initial_step =
    match step with
    | Some _ as step -> step
    | None ->
        window |> Window.location |> Uri.fragment |> Jstr.to_string
        |> int_of_string_opt
  in
  let _history = Browser.History.set_hash "" in
  let* () = Step.Action_scheduler.setup_actions global sliding_window () in
  (* We do one step first, without recording it/updating the hash, to enter in
     the first slip *)
  let* _ =
    Step.Action_scheduler.next global sliding_window ()
    |> Option.value ~default:(Undoable.return ())
    |> Undoable.discard
  in
  let* () =
    (* For some reason, otherwise we things are not properly initialized during
       the toc computation *)
    Fut.tick ~ms:0
  in
  let* () = Table_of_content.generate window sliding_window el in
  let* () =
    match initial_step with
    | None -> Fut.return @@ Step.Next.actualize ()
    | Some step ->
        Fast.with_fast @@ fun () -> Step.Next.goto global step sliding_window
  in
  let () = Controller.setup window sliding_window in
  let () = Messaging.send_ready global () in
  (* let () = Drawing_editor.init () in *)
  Fut.return ()

let () =
  let start window width height step =
    let height = Jv.to_float height in
    let width = Jv.to_float width in
    let step = Jv.to_option Jv.to_int step in
    let window = Window.of_jv window in
    start ~window ~width ~height ~step
  in
  Jv.set Jv.global "startSlipshow" (Jv.callback ~arity:4 start)
