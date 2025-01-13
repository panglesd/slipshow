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
  let act_on_elem class_ action elem =
    match Brr.El.at (Jstr.v class_) elem with
    | None -> UndoMonad.return ()
    | Some v when Jstr.equal Jstr.empty v -> action elem
    | Some v -> (
        let id = Jstr.concat [ Jstr.v "#"; v ] in
        match Brr.El.find_first_by_selector id with
        | None -> UndoMonad.return ()
        | Some elem -> action elem)

  let up window elem = act_on_elem "up-at-unpause" (Window.up window) elem
  let down window elem = act_on_elem "down-at-unpause" (Window.down window) elem

  let center window elem =
    act_on_elem "center-at-unpause" (Window.center window) elem

  let unstatic _window elem =
    act_on_elem "unstatic-at-unpause" (set_class "unstatic" true) elem

  let static _window elem =
    act_on_elem "static-at-unpause" (set_class "unstatic" false) elem

  let focus window elem =
    let action elem =
      let> () = State.Focus.push (State.get_coord ()) in
      Window.focus window elem
    in
    act_on_elem "focus-at-unpause" action elem

  let unfocus window elem =
    let action _elem =
      let> coord = State.Focus.pop () in
      Window.move window coord ~delay:1.0
    in
    act_on_elem "unfocus-at-unpause" action elem

  let reveal _window elem =
    act_on_elem "reveal-at-unpause" (set_class "unrevealed" false) elem

  let unreveal _window elem =
    act_on_elem "unreveal-at-unpause" (set_class "unrevealed" true) elem

  let emph _window elem =
    act_on_elem "emph-at-unpause" (set_class "emphasized" true) elem

  let unemph _window elem =
    act_on_elem "unemph-at-unpause" (set_class "emphasized" false) elem

  let execute _window elem =
    let action elem =
      let body = Jv.get (Brr.El.to_jv elem) "innerHTML" |> Jv.to_jstr in
      Brr.Console.(log [ body ]);
      let args = Jv.Function.[ ("slip", fun () -> Jv.undefined) ] in
      let f = Jv.Function.v ~body ~args in
      let u = f () in
      let undo () =
        Fut.return @@ try ignore @@ Jv.call u "undo" [||] with _ -> ()
      in
      UndoMonad.return ~undo ()
    in
    act_on_elem "exec-at-unpause" action elem

  let do_ window elem =
    let do_ =
     fun acc f ->
      let> _acc = acc in
      f window elem
    in
    List.fold_left do_ (UndoMonad.return ())
      [
        unstatic;
        static;
        unreveal;
        reveal;
        up;
        center;
        down;
        focus;
        unfocus;
        emph;
        unemph;
        execute;
      ]
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
          if Brr.El.class' (Jstr.v "universe") elem then UndoMonad.return ()
          else
            let> () = set_class "pauseAncestor" true elem in
            match Brr.El.parent elem with
            | None -> UndoMonad.return ()
            | Some elem -> hide_parent elem
        in
        hide_parent elem
  in
  let+ () = Fut.tick ~ms:0 in
  ((), fun () -> Fut.return ())

let update_history () =
  let prev_step = State.get_step () in
  let> () = State.incr_step () in
  let n = State.get_step () in
  let> () =
    let counter =
      Brr.El.find_first_by_selector (Jstr.v "#slip-counter") |> Option.get
    in
    UndoMonad.return ~undo:(fun () ->
        Fut.return
        @@ Brr.El.set_children counter [ Brr.El.txt' (string_of_int prev_step) ])
    @@ Brr.El.set_children counter [ Brr.El.txt' (string_of_int n) ]
  in
  Browser.History.set_hash (string_of_int n)

let clear_pause window elem =
  let> () = set_at "pause" None elem in
  let> () = set_at "step" None elem in
  let> () = update_pause_ancestors () in
  let> () = AttributeActions.do_ window elem in
  let> () = update_history () in
  UndoMonad.return ()

let next window () =
  match find_next_pause () with
  | None -> UndoMonad.return ()
  | Some pause -> clear_pause window pause
