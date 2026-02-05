open Fut.Syntax

(*
  Si on veut en rajouter :
   - C'est quand on finit qu'on clean derrière soi, et débloque le suivant.
   - TODO explain the rest
*)

let in_queue =
  let queue = Queue.create () in
  let wait_in_queue hurry_bomb =
    match Queue.take_opt queue with
    | None -> Fut.return ()
    | Some (_, h) ->
        let () = match h with Fast.Normal h -> Fast.detonate h | _ -> () in
        let fut, cont = Fut.create () in
        Queue.add (cont, hurry_bomb) queue;
        fut
  in
  let next_in_queue () =
    match Queue.take_opt queue with
    | None -> ()
    | Some (cont, _hurry_bomb) -> cont ()
  in
  fun hurry_bomb f ->
    let* () = wait_in_queue hurry_bomb in
    let+ () = f () in
    next_in_queue ()

let all_undos = Stack.create ()
let ( !! ) = Jstr.v

let actualize () =
  let () =
    Brr.El.fold_find_by_selector
      (fun el () -> Brr.El.set_class !!"slipshow-toc-current-step" false el)
      !!".slipshow-toc-current-step"
      ()
  in
  match
    Brr.El.find_first_by_selector
      !!(".slipshow-toc-step-" ^ string_of_int (State.get_step ()))
  with
  | None -> ()
  | Some el ->
      Brr.El.scroll_into_view ~align_v:`Nearest ~behavior:`Smooth el;
      Brr.El.set_class !!"slipshow-toc-current-step" true el

module Excursion = struct
  let excursion = ref None

  let start () =
    match !excursion with
    | None -> excursion := Some (Universe.State.get_coord ())
    | Some _ -> ()

  (* When we [move_away] using [ijkl] and [zZ], we store the position we
     left. When we change the presentation step, we [move_back] to where we
     were. *)

  let end_ window () =
    match !excursion with
    | None -> Fut.return ()
    | Some last_pos ->
        excursion := None;
        Universe.Window.move_pure Fast.slow window last_pos ~duration:1.
end

let counter =
  Brr.El.find_first_by_selector (Jstr.v "#slipshow-counter") |> Option.get

let set_counter s = Brr.El.set_children counter [ Brr.El.txt' s ]

let with_step_transition =
 fun diff f ->
  let from = State.get_step () in
  let to_ = from + diff in
  set_counter (string_of_int from ^ "→" ^ string_of_int to_);
  let () = State.set_step to_ in
  let+ res = f () in
  set_counter (string_of_int to_);
  res

let go_next ~mode window n =
  in_queue mode @@ fun () ->
  let rec loop n =
    if n <= 0 then Fut.return ()
    else
      let mode = failwith "TODO" in
      match Action_scheduler.next ~mode window () with
      | None -> Fut.return ()
      | Some undos ->
          let* (), undos = with_step_transition 1 @@ fun () -> undos in
          Stack.push undos all_undos;
          loop (n - 1)
  in
  let+ () = loop n in
  actualize ()

let go_prev ~mode n =
  (* let hurry_bomb = failwith "TODO" in *)
  in_queue mode @@ fun () ->
  let rec loop n =
    if n <= 0 then Fut.return ()
    else
      match Stack.pop_opt all_undos with
      | None -> Fut.return ()
      | Some undo ->
          let* () = with_step_transition (-1) undo in
          loop (n - 1)
  in
  let+ () = loop n in
  actualize ()

let goto ~mode step window =
  let current_step = State.get_step () in
  let* () = Excursion.end_ window () in
  if current_step > step then go_prev ~mode (current_step - step)
  else if current_step < step then go_next ~mode window (step - current_step)
  else Fut.return ()

let current_execution = ref None

let go_next window =
  (* We return a Fut.t Fut.t here to allow to wait for [with_step_transition] to
     update the state, without waiting for the actual transition to be
     finished. *)
  let+ () = Excursion.end_ window () in
  match !current_execution with
  | None -> (
      let mode = Fast.normal () in
      match Action_scheduler.next window ~mode () with
      | None -> Fut.return ()
      | Some fut ->
          let fut =
            let+ (), undos = with_step_transition 1 @@ fun () -> fut in
            Stack.push undos all_undos;
            actualize ();
            current_execution := None
          in
          current_execution := Some (fut, mode);
          fut)
  | Some (fut, mode) ->
      let () =
        match mode with
        | Normal hurry_bomb -> Fast.detonate hurry_bomb
        | Counting_for_toc | Fast | Slow -> ()
      in
      fut

let go_prev window =
  let do_the_undo () =
    match Stack.pop_opt all_undos with
    | None -> Fut.return ()
    | Some undo ->
        let fut =
          let+ () = with_step_transition (-1) undo in
          actualize ();
          current_execution := None
        in
        current_execution := Some (fut, Fast.fast);
        Fut.return ()
  in
  let* () = Excursion.end_ window () in
  match !current_execution with
  | None -> do_the_undo ()
  | Some (fut, mode) ->
      let () =
        match mode with
        | Normal hurry_bomb -> Fast.detonate hurry_bomb
        | Counting_for_toc | Fast | Slow -> ()
      in
      let* () = fut in
      do_the_undo ()
