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

let one_arg conv action undos_ref =
  Jv.callback ~arity:1 @@ fun elem ->
  let elem = conv elem in
  register_undo undos_ref @@ fun () -> action elem

let one_elem action = one_arg Brr.El.of_jv action
let one_elem_list action = one_arg (Jv.to_list Brr.El.of_jv) action
let up window = one_elem (Actions.up window)
let center window = one_elem (Actions.center window)
let down window = one_elem (Actions.down window)
let focus window = one_elem_list (Actions.focus window)
let unfocus window = one_arg (fun _ -> ()) (Actions.unfocus window)
let static = one_elem_list Actions.static
let unstatic = one_elem_list Actions.unstatic
let reveal = one_elem_list Actions.reveal
let unreveal = one_elem_list Actions.unreveal
let emph = one_elem_list Actions.emph
let unemph = one_elem_list Actions.unemph

let on_undo =
  one_arg Fun.id @@ fun callback ->
  let undo _ = Fut.return @@ ignore @@ Jv.apply callback [||] in
  Undoable.return ~undo ()

let slip window undos_ref =
  Jv.obj
    [|
      ("setStyle", set_style undos_ref);
      ("setClass", set_class undos_ref);
      ("up", up window undos_ref);
      ("center", center window undos_ref);
      ("down", down window undos_ref);
      ("focus", focus window undos_ref);
      ("unfocus", unfocus window undos_ref);
      ("static", static undos_ref);
      ("unstatic", unstatic undos_ref);
      ("reveal", reveal undos_ref);
      ("unreveal", unreveal undos_ref);
      ("emph", emph undos_ref);
      ("unemph", unemph undos_ref);
      ("onUndo", on_undo undos_ref);
    |]
