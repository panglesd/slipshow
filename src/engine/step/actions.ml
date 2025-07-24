include Actions_

(* We define the [Actions_] module to avoid a circular dependency: If we had
   only one [Action] module (and not an [Actions] and an [Actions_]) then
   [Actions] would depend on [Javascrip_api] which would depend on [Actions]. *)

module Execute = struct
  type args = Brr.El.t list

  let on = "exec-at-unpause"
  let action_name = "exec"
  let parse_args = Parse.parse_only_els

  open Fut.Syntax

  let do_ window elem =
    try
      let body = Jv.get (Brr.El.to_jv elem) "innerHTML" |> Jv.to_jstr in
      Brr.Console.(log [ body ]);
      let args = Jv.Function.[ ("slip", Fun.id) ] in
      let f = Jv.Function.v ~body ~args in
      let undos_ref = ref [] in
      let arg = Javascript_api.slip window undos_ref in
      let u = f arg in
      let undo () =
        try Fut.return (ignore @@ Jv.call u "undo" [||])
        with _ ->
          List.fold_left
            (fun acc f ->
              let* () = acc in
              f ())
            (Fut.return ()) !undos_ref
      in
      Undoable.return ~undo ()
    with e ->
      Brr.Console.(
        log
          [ "An exception occurred when trying to execute a custom script:"; e ]);
      Undoable.return ()

  let do_ window elems = Undoable.List.iter (do_ window) elems
end

(* Note: the order is important, it's going to be applied in this order *)
let all =
  [
    (module Pause : S);
    (module Actions_.Step : S);
    (* For some reasons, without [Actions_.], this trips (probably ocamldep or
       its driver, dune). *)
    (module Unstatic : S);
    (module Static : S);
    (module Unreveal : S);
    (module Reveal : S);
    (module Unfocus : S);
    (module Center : S);
    (module Enter : S);
    (module Down : S);
    (module Focus : S);
    (module Up : S);
    (module Scroll : S);
    (module Emph : S);
    (module Unemph : S);
    (module Execute : S);
    (module Play_video : S);
    (module Next_page : S);
  ]
