open Fut.Syntax

let in_queue =
  let running = ref false in
  let queue = Queue.create () in
  let wait_in_queue () =
    if !running then (
      Fast.with_fast @@ fun () ->
      let fut, cont = Fut.create () in
      Queue.add cont queue;
      fut)
    else (
      running := true;
      Fut.return ())
  in
  let next_in_queue () =
    match Queue.take_opt queue with
    | None ->
        running := false;
        ()
    | Some cont -> cont ()
  in
  fun f ->
    let* () = wait_in_queue () in
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
        Universe.Window.move_pure window last_pos ~duration:1.
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

let go_next global window n =
  in_queue @@ fun () ->
  let rec loop n =
    if n <= 0 then Fut.return ()
    else
      match Action_scheduler.next global window () with
      | None -> Fut.return ()
      | Some undos ->
          let* (), undos = with_step_transition 1 @@ fun () -> undos in
          Stack.push undos all_undos;
          loop (n - 1)
  in
  let+ () = loop n in
  actualize ()

let go_prev n =
  in_queue @@ fun () ->
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

let goto global step window =
  let current_step = State.get_step () in
  let* () = Excursion.end_ window () in
  if current_step > step then go_prev (current_step - step)
  else if current_step < step then go_next global window (step - current_step)
  else Fut.return ()

let current_execution = ref None

let go_next global window =
  (* We return a Fut.t Fut.t here to allow to wait for [with_step_transition] to
     update the state, without waiting for the actual transition to be
     finished. *)
  let+ () = Excursion.end_ window () in
  match !current_execution with
  | None -> (
      match Action_scheduler.next global window () with
      | None -> Fut.return ()
      | Some fut ->
          let fut =
            let+ (), undos = with_step_transition 1 @@ fun () -> fut in
            Stack.push undos all_undos;
            actualize ();
            current_execution := None
          in
          current_execution := Some fut;
          fut)
  | Some fut -> Fast.with_fast @@ fun () -> fut

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
        current_execution := Some fut;
        Fut.return ()
  in
  let* () = Excursion.end_ window () in
  match !current_execution with
  | None -> do_the_undo ()
  | Some fut ->
      let* () = Fast.with_fast @@ fun () -> fut in
      do_the_undo ()
