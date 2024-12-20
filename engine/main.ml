let _ : unit Fut.t =
  let open Fut.Syntax in
  let width = 1440 and height = 1080 in
  let* () = Normalization.setup ~width ~height in
  let* window = Window.setup ~width ~height in
  (* TODO: move out of here *)
  let () = Rescaler.setup_rescalers () in
  let* () = Window.move window { x = 0.5; y = 0.5; scale = 1. } ~delay:1. in
  let* () = Fut.tick ~ms:2000 in
  let* () = Window.move window { y = 1.; x = 0.75; scale = 1. } ~delay:1. in
  let* () = Fut.tick ~ms:2000 in
  Window.move_to window
    (Brr.El.find_first_by_selector (Jstr.v "#myid") |> Option.get)
