module History = struct
  let set_hash h =
    let old_uri = Brr.Window.location Brr.G.window in
    match Brr.Uri.scheme old_uri |> Jstr.to_string with
    | "about" -> UndoMonad.return ()
    | _ ->
        let history = Brr.Window.history Brr.G.window in
        let uri =
          let fragment = Jstr.v h in
          Brr.Uri.with_uri ~fragment old_uri |> Result.get_ok
        in
        let () = Brr.Window.History.replace_state ~uri history in
        let undo () =
          Fut.return @@ Brr.Window.History.replace_state ~uri:old_uri history
        in
        UndoMonad.return ~undo ()
end
