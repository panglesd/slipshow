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
  let ( let$ ) x f = match x with None -> Undoable.return () | Some x -> f x

  let ( let$$ ) x f =
    match x with
    | Error (`Msg s) ->
        Brr.Console.(log [ "Error:"; s ]);
        Undoable.return ()
    | Ok x -> f x

  let activate ~mode ?(remove_class = true) (module Action : Actions.S) window
      elem =
    let on = Action.on in
    let$ v = Brr.El.at (Jstr.v on) elem in
    Brr.Console.(log [ "Activating"; Action.action_name; "by"; elem ]);
    let> () =
      if remove_class then Undoable.Browser.set_at on None elem
      else Undoable.return ()
    in
    let v = Jstr.to_string v in
    let$$ args = Action.parse_args elem v in
    Action.do_ ~mode window args

  let do_ ~mode window elem =
    let do_ = fun m -> activate ~mode m window elem in
    Undoable.List.iter do_ Actions.all
end

let setup_actions window () =
  let open Fut.Syntax in
  let+ _ : unit list =
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
                     let> () = acc in
                     let open AttributeActions in
                     let mode = Fast.fast in
                     activate ~mode ~remove_class:false
                       (module struct
                         include X

                         let do_ ~mode:_ _window x =
                           setup2 x |> ignore;
                           Undoable.return ()
                       end)
                       window elem)
                   (Jstr.v ("[" ^ X.on ^ "]"))
                   (Undoable.return ())
               in
               Some (Undoable.discard res))
         Actions.all
  in
  ()

let next ~mode window () =
  match find_next_pause_or_step () with
  | None -> None
  | Some pause ->
      let res =
        let> () = Actions.exit ~mode window pause in
        let> () = AttributeActions.do_ ~mode window pause in
        Undoable.return ()
      in
      Some res
