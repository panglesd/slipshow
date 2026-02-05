open Fut.Syntax

(* We use the [Actions_] module to avoid a circular dependency: If we had only
   one [Action] module (and not an [Actions] and an [Actions_]) then [Actions]
   would depend on [Javascrip_api] which would depend on [Actions]. *)
module Actions = Actions_

let register_undo undos_ref f =
  let res =
    let+ (), undo = f () in
    undos_ref := undo :: !undos_ref;
    Ok (Jv.callback ~arity:1 undo)
  in
  Fut.to_promise ~ok:Fun.id res

let one_arg conv action undos_ref =
  Jv.callback ~arity:1 @@ fun elem ->
  let elem = conv elem in
  register_undo undos_ref @@ fun () -> action elem

(* let one_elem action = one_arg Brr.El.of_jv action *)
(* let one_elem_list action = one_arg (Jv.to_list Brr.El.of_jv) action *)

let move (module X : Actions.Move) ~mode window undos_ref =
  Jv.callback ~arity:3 @@ fun elems duration margin ->
  let elem = Brr.El.of_jv elems
  and duration = Jv.to_option Jv.to_float duration
  and margin = Jv.to_option Jv.to_float margin in
  register_undo undos_ref @@ fun () ->
  X.do_ ~mode window X.{ duration; margin; elem }

let up = move (module Actions.Up)
let down = move (module Actions.Down)
let center = move (module Actions.Center)
let scroll = move (module Actions.Scroll)

let focus ~mode window undos_ref =
  Jv.callback ~arity:3 @@ fun elems duration margin ->
  let elems = Jv.to_list Brr.El.of_jv elems
  and duration = Jv.to_option Jv.to_float duration
  and margin = Jv.to_option Jv.to_float margin in
  register_undo undos_ref @@ fun () ->
  Actions.Focus.do_ ~mode window { duration; margin; elems }

let unfocus ~mode window =
  one_arg (fun _ -> ()) (Actions.Unfocus.do_ ~mode window)

let class_setter (module X : Actions.SetClass) ~mode window undos_ref =
  Jv.callback ~arity:1 @@ fun elems ->
  let elems = (Jv.to_list Brr.El.of_jv) elems in
  register_undo undos_ref @@ fun () -> X.do_ ~mode window elems

let unstatic = class_setter (module Actions.Unstatic)
let static = class_setter (module Actions.Static)
let reveal = class_setter (module Actions.Reveal)
let unreveal = class_setter (module Actions.Unreveal)
let emph = class_setter (module Actions.Emph)
let unemph = class_setter (module Actions.Unemph)

let play_media ~mode window undos_ref =
  Jv.callback ~arity:1 @@ fun elems ->
  let elems = Jv.to_list Brr.El.of_jv elems in
  register_undo undos_ref @@ fun () -> Actions.Play_media.do_ ~mode window elems

let draw ~mode window undos_ref =
  Jv.callback ~arity:1 @@ fun elems ->
  let elems = Jv.to_list Brr.El.of_jv elems in
  register_undo undos_ref @@ fun () -> Actions.Draw.do_ ~mode window elems

let change_page ~mode _window undos_ref =
  Jv.callback ~arity:2 @@ fun elem change ->
  let target_elem = Brr.El.of_jv elem in
  let change = Jv.to_string change in
  register_undo undos_ref @@ fun () ->
  Actions.Change_page.parse_change change
  |> Undoable.Option.iter @@ fun change ->
     Actions.Change_page.do_javascript_api ~mode ~target_elem ~change

let on_undo =
  one_arg Fun.id @@ fun callback ->
  let undo () = Fut.return @@ ignore @@ Jv.apply callback [||] in
  Undoable.return ~undo ()

let state = Jv.obj [||]

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

let set_prop undos_ref =
  Jv.callback ~arity:3 @@ fun obj prop value ->
  let prop = Jv.to_jstr prop in
  register_undo undos_ref @@ fun () -> Undoable.Browser.set_prop obj prop value

let is_fast mode =
  Jv.callback ~arity:1 (fun _ -> Jv.of_bool @@ Fast.is_fast mode)

let slip ~mode window undos_ref =
  Jv.obj
    [|
      (* Actions *)
      ("up", up ~mode window undos_ref);
      ("center", center ~mode window undos_ref);
      ("down", down ~mode window undos_ref);
      ("scroll", scroll ~mode window undos_ref);
      ("focus", focus ~mode window undos_ref);
      ("unfocus", unfocus ~mode window undos_ref);
      ("static", static ~mode window undos_ref);
      ("unstatic", unstatic ~mode window undos_ref);
      ("reveal", reveal ~mode window undos_ref);
      ("unreveal", unreveal ~mode window undos_ref);
      ("emph", emph ~mode window undos_ref);
      ("unemph", unemph ~mode window undos_ref);
      ("onUndo", on_undo undos_ref);
      (* Scripting utilities *)
      ("state", state);
      ("setStyle", set_style undos_ref);
      ("setClass", set_class undos_ref);
      ("setProp", set_prop undos_ref);
      ("playMedia", play_media ~mode window undos_ref);
      ("draw", draw ~mode window undos_ref);
      ("isFast", is_fast mode);
      ("changePage", change_page ~mode window undos_ref);
    |]
