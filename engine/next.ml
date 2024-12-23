let find_next_pause () =
  Brr.El.find_first_by_selector (Jstr.v "[pause], [step]")

open UndoMonad.Syntax
open Fut.Syntax

let set_class c b elem : unit UndoMonad.t =
  let c = Jstr.v c in
  let old_class = Brr.El.class' c elem in
  let res = Brr.El.set_class c b elem in
  let undo () = Fut.return @@ Brr.El.set_class c old_class elem in
  UndoMonad.return ~undo res

let set_at at v elem =
  let at = Jstr.v at in
  let old_at = Brr.El.at at elem in
  let res = Brr.El.set_at at v elem in
  let undo () = Fut.return @@ Brr.El.set_at at old_at elem in
  UndoMonad.return ~undo res

module AttributeActions = struct
  let up window elem =
    match Brr.El.at (Jstr.v "up-at-unpause") elem with
    | None -> UndoMonad.return ()
    | Some v when Jstr.equal Jstr.empty v -> Window.up window elem
    | Some v -> (
        let id = Jstr.concat [ Jstr.v "#"; v ] in
        match Brr.El.find_first_by_selector id with
        | None -> UndoMonad.return ()
        | Some elem -> Window.up window elem)

  let do_ window elem = up window elem
end

let update_pause_ancestors () =
  let> () =
    Brr.El.fold_find_by_selector
      (fun elem undoes ->
        let> () = undoes in
        set_class "pauseAncestor" false elem)
      (Jstr.v ".pauseAncestor") (UndoMonad.return ())
  in
  let> () =
    match find_next_pause () with
    | None -> UndoMonad.return ()
    | Some elem ->
        let rec hide_parent elem =
          let> () =
            if Brr.El.class' (Jstr.v "universe") elem then UndoMonad.return ()
            else set_class "pauseAncestor" true elem
          in
          match Brr.El.parent elem with
          | None -> UndoMonad.return ()
          | Some elem -> hide_parent elem
        in
        hide_parent elem
  in
  let+ () = Fut.tick ~ms:0 in
  ((), fun () -> Fut.return ())

let clear_pause window elem =
  let> () = set_at "pause" None elem in
  let> () = set_at "step" None elem in
  let> () = update_pause_ancestors () in
  AttributeActions.do_ window elem

let next window () =
  match find_next_pause () with
  | None -> UndoMonad.return ()
  | Some pause -> clear_pause window pause
