let find_next_pause () = Brr.El.find_first_by_selector (Jstr.v "[pause]")

let find_next_pause_or_step () =
  Brr.El.find_first_by_selector (Jstr.v "[pause], [step]")

open Undoable.Syntax
open Fut.Syntax

let set_class c b elem : unit Undoable.t =
  let c = Jstr.v c in
  let old_class = Brr.El.class' c elem in
  let res = Brr.El.set_class c b elem in
  let undo () = Fut.return @@ Brr.El.set_class c old_class elem in
  Undoable.return ~undo res

let set_at at v elem =
  let at = Jstr.v at in
  let old_at = Brr.El.at at elem in
  let res = Brr.El.set_at at v elem in
  let undo () = Fut.return @@ Brr.El.set_at at old_at elem in
  Undoable.return ~undo res

module AttributeActions = struct
  let act_on_id action id =
    let id = Jstr.concat [ Jstr.v "#"; id ] in
    match Brr.El.find_first_by_selector id with
    | None -> Undoable.return ()
    | Some elem -> action elem

  let act_on_elem class_ action elem =
    match Brr.El.at (Jstr.v class_) elem with
    | None -> Undoable.return ()
    | Some v when Jstr.equal Jstr.empty v -> action elem
    | Some id -> act_on_id action id

  let act_on_elems class_ action elem =
    match Brr.El.at (Jstr.v class_) elem with
    | None -> Undoable.return ()
    | Some v when Jstr.equal Jstr.empty v -> action elem
    | Some v ->
        Jstr.cuts ~sep:(Jstr.v " ") v |> Undoable.List.iter (act_on_id action)

  let up window elem =
    act_on_elem "up-at-unpause" (Universe.Window.up window) elem

  let down window elem =
    act_on_elem "down-at-unpause" (Universe.Window.down window) elem

  let center window elem =
    act_on_elem "center-at-unpause" (Universe.Window.center window) elem

  let unstatic _window elem =
    act_on_elems "unstatic-at-unpause" (set_class "unstatic" true) elem

  let static _window elem =
    act_on_elems "static-at-unpause" (set_class "unstatic" false) elem

  let focus window elem =
    let action elem =
      let> () = State.Focus.push (Universe.State.get_coord ()) in
      Universe.Window.focus window elem
    in
    act_on_elem "focus-at-unpause" action elem

  let unfocus window elem =
    let action _elem =
      let> coord = State.Focus.pop () in
      match coord with
      | None -> Undoable.return ()
      | Some coord -> Universe.Window.move window coord ~delay:1.0
    in
    act_on_elem "unfocus-at-unpause" action elem

  let reveal _window elem =
    act_on_elems "reveal-at-unpause" (set_class "unrevealed" false) elem

  let unreveal _window elem =
    act_on_elems "unreveal-at-unpause" (set_class "unrevealed" true) elem

  let emph _window elem =
    act_on_elems "emph-at-unpause" (set_class "emphasized" true) elem

  let unemph _window elem =
    act_on_elems "unemph-at-unpause" (set_class "emphasized" false) elem

  let execute _window elem =
    let action elem =
      let body = Jv.get (Brr.El.to_jv elem) "innerHTML" |> Jv.to_jstr in
      Brr.Console.(log [ body ]);
      let args = Jv.Function.[ ("slip", Fun.id) ] in
      let f = Jv.Function.v ~body ~args in
      let arg =
        Jv.obj
          [|
            ( "set_class",
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
              Jv.callback ~arity:1 undo );
          |]
      in
      let u = f arg in
      let undo () =
        Fut.return @@ try ignore @@ Jv.call u "undo" [||] with _ -> ()
      in
      Undoable.return ~undo ()
    in
    act_on_elems "exec-at-unpause" action elem

  let do_ window elem =
    let do_ =
     fun acc f ->
      let> _acc = acc in
      f window elem
    in
    List.fold_left do_ (Undoable.return ())
      [
        unstatic;
        static;
        unreveal;
        reveal;
        unfocus;
        center;
        down;
        focus;
        up;
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
      (Jstr.v ".pauseAncestor") (Undoable.return ())
  in
  let> () =
    match find_next_pause () with
    | None -> Undoable.return ()
    | Some elem ->
        let rec hide_parent elem =
          if Brr.El.class' (Jstr.v "universe") elem then Undoable.return ()
          else
            let> () = set_class "pauseAncestor" true elem in
            match Brr.El.parent elem with
            | None -> Undoable.return ()
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
    Undoable.return ~undo:(fun () ->
        Fut.return
        @@ Brr.El.set_children counter [ Brr.El.txt' (string_of_int prev_step) ])
    @@ Brr.El.set_children counter [ Brr.El.txt' (string_of_int n) ]
  in
  Undoable.Browser.History.set_hash (string_of_int n)

let clear_pause window elem =
  let> () =
    if Option.is_some @@ Brr.El.at (Jstr.v "pause") elem then
      let> () = set_at "pause" None elem in
      update_pause_ancestors ()
    else set_at "step" None elem
  in
  let> () = AttributeActions.do_ window elem in
  let> () = update_history () in
  Undoable.return ()

let next window () =
  match find_next_pause_or_step () with
  | None -> None
  | Some pause -> Some (clear_pause window pause)
