let _ : unit Fut.t =
  let open Fut.Syntax in
  let* () = Normalization.setup () in
  let* window = Window.setup () in
  (* TODO: move out of here *)
  let () = Rescaler.setup_rescalers () in
  let () = Controller.setup window in
  let* _ = Next.update_pause_ancestors () in
  let* () =
    match
      Brr.G.window |> Brr.Window.location |> Brr.Uri.fragment |> Jstr.to_string
      |> int_of_string_opt
    with
    | None -> Fut.return ()
    | Some n ->
        List.fold_left
          (fun acc () ->
            let* () = acc in
            let+ _ = Next.next window () in
            ())
          (Fut.return ())
          (List.init n (fun _ -> ()))
  in
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
