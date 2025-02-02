let start id step =
  let open Fut.Syntax in
  let el =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-content") |> Option.get
  in
  let body = Brr.El.find_first_by_selector (Jstr.v "body") |> Option.get in
  let* () = Normalization.setup el in
  let* window = Window.setup el in
  let () = Table_of_content.generate window el in
  (* TODO: move out of here *)
  let () = Rescaler.setup_rescalers () in
  let () = Drawing.setup body in
  let initial_step =
    match step with
    | Some _ as step -> step
    | None ->
        Brr.G.window |> Brr.Window.location |> Brr.Uri.fragment
        |> Jstr.to_string |> int_of_string_opt
  in
  let* () = Browser.History.set_hash "" |> UndoMonad.discard in
  let* () = Actions.update_pause_ancestors () |> UndoMonad.discard in
  let* () =
    match initial_step with
    | None -> Fut.return @@ Next.actualize ()
    | Some step -> Window.with_fast_moving @@ fun () -> Next.goto step window
  in
  let () = Controller.setup window in
  let () = Messaging.set_id id in
  let () = Messaging.send_ready () in
  Fut.return ()

let () =
  let start step id =
    start (Jv.to_option Jv.to_string id) (Jv.to_option Jv.to_int step)
  in
  Jv.set Jv.global "startSlipshow" (Jv.callback ~arity:2 start)
