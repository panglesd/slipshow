open Fut.Syntax

let register_undo undos_ref f =
  let res =
    let+ (), undo = f () in
    undos_ref := undo :: !undos_ref;
    Ok (Jv.callback ~arity:1 undo)
  in
  Fut.to_promise ~ok:Fun.id res

let set_style undos_ref =
  Jv.callback ~arity:3 @@ fun elem style value ->
  let elem = Brr.El.of_jv elem
  and style = Jv.to_jstr style
  and value = Jv.to_jstr value in
  register_undo undos_ref @@ fun () ->
  Undoable.Browser.set_style style value elem

let set_class undos_ref =
  Jv.callback ~arity:3 @@ fun elem class_ bool ->
  let bool = Jv.to_bool bool in
  register_undo undos_ref @@ fun () ->
  Undoable.Browser.set_class class_ bool elem
