module History = struct
  let set_hash h =
    let old_uri = Brr.Window.location Brr.G.window in
    let history = Browser.History.set_hash h in
    let undo () =
      match history with
      | None -> Fut.return ()
      | Some history ->
          Fut.return @@ Brr.Window.History.replace_state ~uri:old_uri history
    in
    Fut.return ((), undo)
end
