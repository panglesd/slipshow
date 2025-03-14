open Fut.Syntax

let in_queue =
  let running = ref false in
  let queue = Queue.create () in
  let wait_in_queue () =
    if !running then (
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
  let () =
    match
      Brr.El.find_first_by_selector
        !!(".slipshow-toc-step-" ^ string_of_int (State.get_step ()))
    with
    | None -> ()
    | Some el ->
        Brr.El.scroll_into_view ~align_v:`Nearest ~behavior:`Smooth el;
        Brr.El.set_class !!"slipshow-toc-current-step" true el
  in
  Messaging.send_step ()

let go_next window n =
  in_queue @@ fun () ->
  let rec loop n =
    if n <= 0 then Fut.return ()
    else
      match Action_scheduler.next window () with
      | None -> Fut.return ()
      | Some undos ->
          let* (), undos = undos in
          Stack.push undos all_undos;
          loop (n - 1)
  in
  let+ () = loop n in
  actualize ()

let go_prev _window n =
  in_queue @@ fun () ->
  let rec loop n =
    if n <= 0 then Fut.return ()
    else
      match Stack.pop_opt all_undos with
      | None -> Fut.return ()
      | Some undo ->
          let* () = undo () in
          loop (n - 1)
  in
  let+ () = loop n in
  actualize ()

let goto step window =
  let current_step = State.get_step () in
  if current_step > step then go_prev window (current_step - step)
  else if current_step < step then go_next window (step - current_step)
  else Fut.return ()
