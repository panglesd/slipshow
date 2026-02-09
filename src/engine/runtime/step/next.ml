open Fut.Syntax

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
      !!(".slipshow-toc-step-" ^ (State.get_step () |> State.to_string))
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

let go_next ~mode window ~from ~to_ =
  let () = Brr.Console.(log [ "going next from "; from; " to "; to_ ]) in
  let rec loop n =
    if n <= 0 then Fut.return ()
    else
      match Action_scheduler.next ~mode window () with
      | None -> Fut.return ()
      | Some undos ->
          let* (), undos = undos in
          Stack.push undos all_undos;
          loop (n - 1)
  in
  let+ () = loop (to_ - from) in
  actualize ()

let go_prev ~mode:_ ~from ~to_ =
  let rec loop n =
    if n <= 0 then Fut.return ()
    else
      match Stack.pop_opt all_undos with
      | None -> Fut.return ()
      | Some undo ->
          let* () = undo () in
          loop (n - 1)
  in
  let+ () = loop (from - to_) in
  actualize ()

let goto ~mode ~from ~to_ window =
  Brr.Console.(log [ "Goto step"; to_; "from step"; from ]);
  let* () = Excursion.end_ window () in
  if from > to_ then go_prev ~mode ~from ~to_
  else if from < to_ then go_next ~mode window ~from ~to_
  else Fut.return ()

let rec exec_transition transition window =
  let () = State.set_step (State.Transition transition) in
  let* res =
    goto ~mode:transition.mode ~from:transition.from ~to_:transition.to_ window
  in
  match transition.next with
  | None ->
      let () = State.set_step (State.At transition.to_) in
      Fut.return res
  | Some next_transition -> exec_transition next_transition window

let go_to ~mode to_ window =
  (* TODO: check comment below *)
  (* We return a Fut.t Fut.t here to allow to wait for [with_step_transition] to
     update the state, without waiting for the actual transition to be
     finished. *)
  let+ () = Excursion.end_ window () in
  let do_it ~from ~to_ =
    let transition = { State.from; to_; mode; next = None } in
    exec_transition transition window
  in
  match State.get_step () with
  | At from -> do_it ~from ~to_
  | Transition transition ->
      let () =
        match transition.mode with
        | Normal h -> Fast.detonate h
        | Counting_for_toc | Fast | Slow -> ()
      in
      (* TODO: check if it's a problem that activate is never activated *)
      let f, _activate = Fut.create () in
      let from = transition.to_ in
      transition.next <- Some { from; to_; mode; next = None };
      f

let go_next window mode =
  let step =
    match State.get_step () with
    | At n -> n + 1
    | Transition { from; to_; _ } -> Int.max from to_
  in
  go_to step ~mode window

let go_prev window mode =
  let step =
    match State.get_step () with
    | At n -> n - 1
    | Transition { from; to_; _ } -> Int.min from to_
  in
  go_to step ~mode window
