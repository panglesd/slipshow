let all_actions = List.map (fun (module M : Actions.S) -> M.on) Actions.all

let is_action elem =
  List.exists
    (fun action -> Option.is_some @@ Brr.El.at (Jstr.v action) elem)
    all_actions

let all_action_selector =
  all_actions |> List.map (fun s -> "[" ^ s ^ "]") |> String.concat ", "

let find_next_pause_or_step () =
  Brr.El.find_first_by_selector (Jstr.v all_action_selector)

open Undoable.Syntax

module AttributeActions = struct
  let ( let$ ) x f state =
    match x with None -> Undoable.return state | Some x -> f x

  let ( let$$ ) x f state =
    match x with
    | Error (`Msg s) ->
        Brr.Console.(log [ "Error:"; s ]);
        Undoable.return state
    | Ok x -> f x

  let activate state ~mode ?(remove_class = true) (module Action : Actions.S)
      window elem =
    let on = Action.on in
    state
    |> let$ v = Brr.El.at (Jstr.v on) elem in
       Brr.Console.(log [ "Activating"; Action.action_name; "by"; elem ]);
       let> () =
         if remove_class then Undoable.Browser.set_at on None elem
         else Undoable.return ()
       in
       let v = Jstr.to_string v in
       state
       |>
       let$$ args, _warnings = Action.parse_args v in
       Action.do_ state ~mode window elem args

  let do_ state ~mode window elem =
    let do_ = fun state m -> activate state ~mode m window elem in
    Undoable.List.fold_left do_ state Actions.all
end

let setup_actions window () =
  let open Fut.Syntax in
  let+ _ : Actions_.state list =
    Fut.of_list
    @@ List.filter_map
         (fun (module X : Actions.S) ->
           let _ =
             match X.setup_all with None -> Fut.return () | Some f -> f ()
           in
           match X.setup with
           | None -> None
           | Some setup2 ->
               let res =
                 Brr.El.fold_find_by_selector
                   (fun elem acc ->
                     let> state = acc in
                     let open AttributeActions in
                     let mode = Fast.fast in
                     activate state ~mode ~remove_class:false
                       (module struct
                         include X

                         let do_ state ~mode:_ _window el x =
                           setup2 el x |> ignore;
                           Undoable.return state
                       end)
                       window elem)
                   (Jstr.v ("[" ^ X.on ^ "]"))
                   (Undoable.return Actions_.start_state)
               in
               Some (Undoable.discard res))
         Actions.all
  in
  ()

let rec next ~mode window () =
  match find_next_pause_or_step () with
  | None -> None
  | Some pause ->
      let res =
        let> state =
          let> () = Actions.exit ~mode window pause in
          AttributeActions.do_ Actions_.start_state ~mode window pause
        in
        if state.auto_next then
          let n = next ~mode window () in
          Option.value ~default:(Undoable.return ()) n
        else Undoable.return ()
      in
      Some res
