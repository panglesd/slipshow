let find_next_pause () = Brr.El.find_first_by_selector (Jstr.v "[pause]")

let find_next_pause_or_step () =
  Brr.El.find_first_by_selector (Jstr.v "[pause], [step]")

open Undoable.Syntax
open Fut.Syntax

module AttributeActions = struct
  let as_id elem v =
    if Jstr.equal Jstr.empty v then Some elem
    else
      let id = Jstr.concat [ Jstr.v "#"; v ] in
      match Brr.El.find_first_by_selector id with
      | None -> None
      | Some elem -> Some elem

  let as_ids elem v =
    if Jstr.equal Jstr.empty v then Some [ elem ]
    else
      Some
        (Jstr.cuts ~sep:(Jstr.v " ") v
        |> List.filter_map (fun id ->
               Brr.El.find_first_by_selector (Jstr.concat [ Jstr.v "#"; id ])))

  let act ~on:class_ ~payload action elem =
    let ( let$ ) x f =
      match x with None -> Undoable.return () | Some x -> f x
    in
    let$ v = Brr.El.at (Jstr.v class_) elem in
    let$ payload = payload elem v in
    action payload

  let up window = act ~on:"up-at-unpause" ~payload:as_id (Actions.up window)

  let down window =
    act ~on:"down-at-unpause" ~payload:as_id (Actions.down window)

  let center window =
    act ~on:"center-at-unpause" ~payload:as_id (Actions.center window)

  let unstatic = act ~on:"unstatic-at-unpause" ~payload:as_ids Actions.unstatic
  let static = act ~on:"static-at-unpause" ~payload:as_ids Actions.static

  let focus window =
    act ~on:"focus-at-unpause" ~payload:as_ids (Actions.focus window)

  let unfocus window =
    act ~on:"unfocus-at-unpause"
      ~payload:(fun _ _ -> Some ())
      (Actions.unfocus window)

  let reveal = act ~on:"reveal-at-unpause" ~payload:as_ids Actions.reveal
  let unreveal = act ~on:"unreveal-at-unpause" ~payload:as_ids Actions.unreveal
  let emph = act ~on:"emph-at-unpause" ~payload:as_ids Actions.emph
  let unemph = act ~on:"unemph-at-unpause" ~payload:as_ids Actions.unemph

  let execute window elem =
    let action elem =
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
    in
    try
      act ~on:"exec-at-unpause" ~payload:as_ids (Undoable.List.iter action) elem
    with e ->
      Brr.Console.(
        log
          [ "An exception occurred when trying to execute a custom script:"; e ]);
      Undoable.return ()

  let do_ window elem =
    let do_ =
     fun acc f ->
      let> _acc = acc in
      f elem
    in
    List.fold_left do_ (Undoable.return ())
      [
        unstatic;
        static;
        unreveal;
        reveal;
        unfocus window;
        center window;
        down window;
        focus window;
        up window;
        emph;
        unemph;
        execute window;
      ]
end

let update_pause_ancestors () =
  let> () =
    Brr.El.fold_find_by_selector
      (fun elem undoes ->
        let> () = undoes in
        Undoable.Browser.set_class "pauseAncestor" false elem)
      (Jstr.v ".pauseAncestor") (Undoable.return ())
  in
  let> () =
    match find_next_pause () with
    | None -> Undoable.return ()
    | Some elem ->
        let rec hide_parent elem =
          if Brr.El.class' (Jstr.v "slipshow-universe") elem then
            Undoable.return ()
          else
            let> () = Undoable.Browser.set_class "pauseAncestor" true elem in
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
      Brr.El.find_first_by_selector (Jstr.v "#slipshow-counter") |> Option.get
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
      let> () = Undoable.Browser.set_at "pause" None elem in
      update_pause_ancestors ()
    else Undoable.Browser.set_at "step" None elem
  in
  let> () = AttributeActions.do_ window elem in
  let> () = update_history () in
  Undoable.return ()

let next window () =
  match find_next_pause_or_step () with
  | None -> None
  | Some pause -> Some (clear_pause window pause)
