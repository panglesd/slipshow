open Fut.Syntax

let all_undos = Stack.create ()
let ( !! ) = Jstr.v

let actualize n =
  let () =
    Brr.El.fold_find_by_selector
      (fun el () -> Brr.El.set_class !!"slipshow-toc-current-step" false el)
      !!".slipshow-toc-current-step"
      ()
  in
  match
    Brr.El.find_first_by_selector !!(".slipshow-toc-step-" ^ string_of_int n)
  with
  | None -> ()
  | Some el ->
      Brr.El.scroll_into_view ~align_v:`Nearest ~behavior:`Smooth el;
      Brr.El.set_class !!"slipshow-toc-current-step" true el

let go_next ~mode window ~from ~to_ =
  let () = Brr.Console.(log [ "going next from "; from; " to "; to_ ]) in
  let rec loop n continue =
    if n <= 0 then Fut.return (to_, continue)
    else
      match Action_scheduler.next ~mode window () with
      | None -> Fut.return (to_ - n, false)
      | Some undos ->
          Brr.Console.(log [ "MYRSK CONTINUINF 33"; continue ]);
          let* continue, undos = undos in
          Stack.push undos all_undos;
          loop (n - 1) continue
  in
  let+ res, continue = loop (to_ - from) false in
  actualize to_;
  (res, continue)

let go_prev ~mode:_ ~from ~to_ =
  let rec loop n =
    if n <= 0 then Fut.return to_
    else
      match Stack.pop_opt all_undos with
      | None -> Fut.return (to_ + n)
      | Some undo ->
          let* () = undo () in
          loop (n - 1)
  in
  let+ res = loop (from - to_) in
  actualize to_;
  res

let goto ~mode ~from ~to_ window =
  Brr.Console.(log [ "Goto step"; to_; "from step"; from ]);
  if from > to_ then Fut.map (fun x -> (x, false)) (go_prev ~mode ~from ~to_)
  else if from < to_ then go_next ~mode window ~from ~to_
  else Fut.return (from, false)

let rec exec_transition transition window =
  let () = State.set_step (State.Transition transition) in
  if transition.send_message then
    Messaging.send_step transition.to_
      (if Fast.is_fast transition.mode then `Fast else `Normal);
  let* new_to, continue =
    goto ~mode:transition.mode ~from:transition.from ~to_:transition.to_ window
  in
  transition.signal continue;
  let () =
    if (not @@ Int.equal new_to transition.to_) && transition.send_message then (
      Messaging.send_step new_to
        (if Fast.is_fast transition.mode then `Fast else `Normal);
      actualize new_to)
  in
  match transition.next with
  | None ->
      let () = State.set_step (State.At new_to) in
      Fut.return continue
  | Some next_transition ->
      let _ = exec_transition { next_transition with from = new_to } window in
      Fut.return continue

let go_to ~mode ~send_message to_ window =
  match State.get_step () with
  | At from ->
      let transition =
        {
          State.from;
          to_;
          mode;
          next = None;
          send_message;
          signal = (fun _ -> ());
        }
      in
      exec_transition transition window
  | Transition transition ->
      let () =
        match transition.mode with
        | Normal h -> Fast.detonate h
        | Counting_for_toc | Fast | Slow -> ()
      in
      (* TODO: check if it's a problem that activate is never activated *)
      let f, activate = Fut.create () in
      let from = transition.to_ in
      transition.next <-
        Some { from; to_; mode; next = None; send_message; signal = activate };
      f

let rec go_next ~send_message window mode =
  let step =
    match State.get_step () with
    | At n -> n + 1
    | Transition { from; to_; _ } -> Int.max from to_
  in
  let* res = go_to step ~mode ~send_message window in
  match (res, mode) with
  | true, Normal hb when not @@ Fast.has_detonated hb ->
      go_next ~send_message:false window mode
  | _ -> Fut.return ()

let go_prev ~send_message window mode =
  let step =
    match State.get_step () with
    | At n -> n - 1
    | Transition { from; to_; _ } -> Int.min from to_
  in
  go_to step ~send_message ~mode window
