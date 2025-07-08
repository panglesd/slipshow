let all_actions =
  [
    "center-at-unpause";
    "down-at-unpause";
    "emph-at-unpause";
    "enter-at-unpause";
    "exec-at-unpause";
    "focus-at-unpause";
    "pause";
    "reveal-at-unpause";
    "scroll-at-unpause";
    "static-at-unpause";
    "step";
    "unemph-at-unpause";
    "unfocus-at-unpause";
    "unreveal-at-unpause";
    "unstatic-at-unpause";
    "up-at-unpause";
  ]

let is_action elem =
  List.exists
    (fun action -> Option.is_some @@ Brr.El.at (Jstr.v action) elem)
    all_actions

let all_action_selector =
  all_actions
  |> List.map (fun s -> Format.sprintf "[%s]" s)
  |> String.concat ", "

let find_next_pause_or_step () =
  Brr.El.find_first_by_selector (Jstr.v all_action_selector)

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

  let act ?(remove_class = true) ~on:at_ ~payload action elem =
    let ( let$ ) x f =
      match x with None -> Undoable.return () | Some x -> f x
    in
    let$ v = Brr.El.at (Jstr.v at_) elem in
    let> () =
      if remove_class then Undoable.Browser.set_at at_ None elem
      else Undoable.return ()
    in
    let$ payload = payload elem v in
    action payload

  let act2 ?(remove_class = true) ~on:at_ action elem =
    let ( let$ ) x f =
      match x with None -> Undoable.return () | Some x -> f x
    in
    let ( let$$ ) x f =
      match x with
      | Error (`Msg s) ->
          Brr.Console.(log [ "Error:"; s ]);
          Undoable.return ()
      | Ok x -> f x
    in
    let$ v = Brr.El.at (Jstr.v at_) elem in
    let> () =
      if remove_class then Undoable.Browser.set_at at_ None elem
      else Undoable.return ()
    in
    let v = Jstr.to_string v in
    let$$ args = Actions.Focus.parse_args elem v in
    action args

  let up window = act ~on:"up-at-unpause" ~payload:as_id (Actions.up window)

  let down window =
    act ~on:"down-at-unpause" ~payload:as_id (Actions.down window)

  let center window =
    act ~on:"center-at-unpause" ~payload:as_id (Actions.center window)

  let enter window =
    act ~on:"enter-at-unpause" ~payload:as_id (Actions.enter window)

  let scroll window =
    act ~on:"scroll-at-unpause" ~payload:as_id (Actions.scroll window)

  let unstatic = act ~on:"unstatic-at-unpause" ~payload:as_ids Actions.unstatic
  let static = act ~on:"static-at-unpause" ~payload:as_ids Actions.static
  let focus window = act2 ~on:"focus-at-unpause" (Actions.Focus.do_ window)

  let unfocus window =
    act ~on:"unfocus-at-unpause"
      ~payload:(fun _ _ -> Some ())
      (Actions.unfocus window)

  let reveal = act ~on:"reveal-at-unpause" ~payload:as_ids Actions.reveal
  let unreveal = act ~on:"unreveal-at-unpause" ~payload:as_ids Actions.unreveal
  let emph = act ~on:"emph-at-unpause" ~payload:as_ids Actions.emph
  let unemph = act ~on:"unemph-at-unpause" ~payload:as_ids Actions.unemph

  let pause elem =
    act ~on:"pause" ~payload:as_id (fun target -> Actions.pause target) elem

  let step elem =
    act ~on:"step" ~payload:as_id (fun _ -> Undoable.return ()) elem

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
      act ~remove_class:false ~on:"pause" ~payload:as_id Actions.setup_pause
        elem)
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
        let> () = Actions.exit window pause in
        let> () = AttributeActions.do_ window pause in
        let> () = update_history () in
        Undoable.return ()
      in
      Some res
