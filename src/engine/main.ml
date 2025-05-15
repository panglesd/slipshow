let start id step =
  let open Fut.Syntax in
  let el =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-content") |> Option.get
  in
  let body = Brr.El.find_first_by_selector (Jstr.v "body") |> Option.get in
  let* () = Normalization.setup el in
  let* window = Universe.Window.setup el in
  let () = Table_of_content.generate window el in
  (* TODO: move out of here (Later: Why?) *)
  let () = Rescale.setup_rescalers () in
  let () = Drawing.setup body in
  let () = Mouse_disappearing.setup () in
  let initial_step =
    match step with
    | Some _ as step -> step
    | None ->
        Brr.G.window |> Brr.Window.location |> Brr.Uri.fragment
        |> Jstr.to_string |> int_of_string_opt
  in
  let _history = Browser.History.set_hash "" in
  let* () =
    Brr.El.fold_find_by_selector
      (fun root _ -> Step.Action_scheduler.setup_pause_ancestors root)
      (Jstr.v ".slip") (Undoable.return ())
    |> Undoable.discard
  in
  let* () =
    match initial_step with
    | None -> Fut.return @@ Step.Next.actualize ()
    | Some step ->
        Universe.Window.with_fast_moving @@ fun () -> Step.Next.goto step window
  in
  let () = Controller.setup window in
  let () = Step.Messaging.set_id id in
  let () = Step.Messaging.send_ready () in
  Fut.return ()

let () =
  let start step id =
    start (Jv.to_option Jv.to_string id) (Jv.to_option Jv.to_int step)
  in
  Jv.set Jv.global "startSlipshow" (Jv.callback ~arity:2 start)
