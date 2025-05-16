let find_next_pause_or_step ?root () =
  Brr.El.find_first_by_selector ?root (Jstr.v "[pause], [step]")

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

  let enter window =
    act ~on:"enter-at-unpause" ~payload:as_id (Actions.enter window)

  let exit window =
    act ~on:"exit-at-unpause"
      ~payload:(fun _ _ -> Some ())
      (Actions.exit window)

  let scroll window =
    act ~on:"scroll-at-unpause" ~payload:as_id (Actions.scroll window)

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

  let pause elem =
    act ~on:"pause" ~payload:as_id
      (fun target ->
        let> () = Undoable.Browser.set_at "pause" None elem in
        Actions.pause target)
      elem

  let step elem =
    act ~on:"step" ~payload:as_id
      (fun target ->
        let> () = Undoable.Browser.set_at "step" None elem in
        Actions.pause target)
      elem

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
        pause;
        step;
        unstatic;
        static;
        unreveal;
        reveal;
        unfocus window;
        center window;
        exit window;
        enter window;
        down window;
        focus window;
        up window;
        scroll window;
        emph;
        unemph;
        execute window;
      ]
end

let setup_pause_ancestors () =
  Brr.El.fold_find_by_selector
    (fun elem acc ->
      let> () = acc in
      let open AttributeActions in
      act ~on:"pause" ~payload:as_id Actions.setup_pause elem)
    (Jstr.v "[pause]") (Undoable.return ())

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

let next window () =
  match find_next_pause_or_step () with
  | None -> None
  | Some pause ->
      let res =
        let> () = AttributeActions.do_ window pause in
        let> () = update_history () in
        Undoable.return ()
      in
      Some res
