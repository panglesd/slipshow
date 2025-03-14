open Monad

let set_class c b elem : unit t =
  let c = Jstr.v c in
  let old_class = Brr.El.class' c elem in
  let () = Brr.El.set_class c b elem in
  let undo () = Fut.return @@ Brr.El.set_class c old_class elem in
  return ~undo ()

let set_at at v elem =
  let at = Jstr.v at in
  let old_at = Brr.El.at at elem in
  let () = Brr.El.set_at at v elem in
  let undo () = Fut.return @@ Brr.El.set_at at old_at elem in
  return ~undo ()

let set_style style value elem =
  let old_value =
    let old_value = Brr.El.inline_style style elem in
    if Jstr.equal old_value Jstr.empty then None else Some old_value
  in
  let () = Brr.El.set_inline_style style value elem in
  let undo _ =
    Fut.return
    @@
    match old_value with
    | None -> Brr.El.remove_inline_style style elem
    | Some old_value -> Brr.El.set_inline_style style old_value elem
  in
  return ~undo ()

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
    return ~undo ()
end
