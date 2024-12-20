let _ : unit Fut.t =
  let open Fut.Syntax in
  let width = 1440 and height = 1080 in
  let* () = Normalization.setup ~width ~height in
  let* window = Window.setup ~width ~height in
  (* TODO: move out of here *)
  let () = Rescaler.setup_rescalers () in
  let () = Controller.setup window in
  Next.update_pause_ancestors ()
