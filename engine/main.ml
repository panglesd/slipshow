let _ : unit Fut.t =
  let open Fut.Syntax in
  let* () = Normalization.setup () in
  let* window = Window.setup () in
  (* TODO: move out of here *)
  let () = Rescaler.setup_rescalers () in
  let initial_step =
    Brr.G.window |> Brr.Window.location |> Brr.Uri.fragment |> Jstr.to_string
    |> int_of_string_opt
  in
  let* () = Browser.History.set_hash "" |> UndoMonad.discard in
  let* () = Next.update_pause_ancestors () |> UndoMonad.discard in
  let* () = Controller.setup ?initial_step window in
  (* let* () = *)
  (*   match Brr.Window.parent Brr.G.window with *)
  (*   | None -> *)
  (*       Brr.Console.(log [ "no parent" ]); *)
  (*       Fut.return () *)
  (*   | Some parent -> *)
  (*       Brr.Console.(log [ "a parent"; parent ]); *)
  (*       Brr.Window.post_message parent ~msg:(Jv.of_string "YOOOOOOOOOO"); *)
  (*       Fut.return () *)
  (* in *)
  Fut.return ()
