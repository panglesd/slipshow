let start id step =
  let open Fut.Syntax in
  let* () = Normalization.setup () in
  let* window = Window.setup () in
  (* TODO: move out of here *)
  let () = Rescaler.setup_rescalers () in
  let initial_step =
    match step with
    | Some _ as step -> step
    | None ->
        Brr.G.window |> Brr.Window.location |> Brr.Uri.fragment
        |> Jstr.to_string |> int_of_string_opt
  in
  let* () = Browser.History.set_hash "" |> UndoMonad.discard in
  let* () = Next.update_pause_ancestors () |> UndoMonad.discard in
  let* () = Controller.setup ?initial_step window in
  let () = Messaging.set_id id in
  let () = Messaging.send_ready () in
  Fut.return ()

let () =
  let start step id =
    start (Jv.to_option Jv.to_string id) (Jv.to_option Jv.to_int step)
  in
  Jv.set Jv.global "startSlipshow" (Jv.callback ~arity:2 start)
