let _ : unit Fut.t =
  let open Fut.Syntax in
  let* () = Normalization.setup () in
  let* window = Window.setup () in
  (* TODO: move out of here *)
  let () = Rescaler.setup_rescalers () in
  let () = Controller.setup window in
  let _ = Next.update_pause_ancestors () in
  Fut.return ()
