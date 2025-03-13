let set_style undos_ref =
  Jv.callback ~arity:3 @@ fun elem style value ->
  let old_value =
    let old_value = Brr.El.inline_style style elem in
    if Jstr.equal old_value Jstr.empty then None else Some old_value
  in
  Brr.El.set_inline_style style value elem;
  let undo _ =
    Fut.return
    @@
    match old_value with
    | None -> Brr.El.remove_inline_style style elem
    | Some old_value -> Brr.El.set_inline_style style old_value elem
  in
  undos_ref := undo :: !undos_ref;
  Jv.callback ~arity:1 undo

let set_class undos_ref =
  Jv.callback ~arity:3 @@ fun elem class_ bool ->
  let bool = Jv.to_bool bool in
  Brr.Console.(log [ "set_class called with"; elem; class_; bool ]);
  let old_value = Brr.El.class' class_ elem in
  Brr.El.set_class class_ bool elem;
  let undo _ = Fut.return @@ Brr.El.set_class class_ old_value elem in
  undos_ref := undo :: !undos_ref;
  Jv.callback ~arity:1 undo
