open Notty
open Notty_unix
open Nottui

(* FIXME Uses of [quick_sample] and [quick_release] should be replaced by
         [sample] and [release] with the appropriate release management. *)

let step ?(process_event=true) ?(timeout=(-1.0)) ~renderer term root =
  let size = Term.size term in
  let image =
    let rec stabilize () =
      let tree = Lwd.quick_sample root in
      Renderer.update renderer size tree;
      let image = Renderer.image renderer in
      if Lwd.is_damaged root
      then stabilize ()
      else image
    in
    stabilize ()
  in
  Term.image term image;
  if process_event then
    let i, _ = Term.fds term in
    let has_event =
      let rec select () =
        match Unix.select [i] [] [i] timeout with
        | [], [], [] -> false
        | _ -> true
        | exception (Unix.Unix_error (Unix.EINTR, _, _)) -> select ()
      in
      select ()
    in
    if has_event then
      match Term.event term with
      | `End -> ()
      | `Resize _ -> ()
      | #Unescape.event as event ->
        let event = (event : Unescape.event :> Ui.event) in
        ignore (Renderer.dispatch_event renderer event : [`Handled | `Unhandled])

let run_with_term term ?tick_period ?(tick=ignore) ~renderer quit t =
  let quit = Lwd.observe (Lwd.get quit) in
  let root = Lwd.observe t in
  let rec loop () =
    let quit = Lwd.quick_sample quit in
    if not quit then (
      step ~process_event:true ?timeout:tick_period ~renderer term root;
      tick ();
      loop ()
    )
  in
  loop ();
  ignore (Lwd.quick_release root);
  ignore (Lwd.quick_release quit)

let run ?tick_period ?tick ?term ?(renderer=Renderer.make ())
        ?quit ?(quit_on_escape=true) ?(quit_on_ctrl_q=true) t =
  let quit = match quit with
    | Some quit -> quit
    | None -> Lwd.var false
  in
  let t = Lwd.map t ~f:(Ui.event_filter (function
      | `Key (`ASCII 'Q', [`Ctrl]) when quit_on_ctrl_q ->
        Lwd.set quit true; `Handled
      | `Key (`Escape, []) when quit_on_escape ->
        Lwd.set quit true; `Handled
      | _ -> `Unhandled
    ))
  in
  match term with
  | Some term -> run_with_term term ?tick_period ?tick ~renderer quit t
  | None ->
    let term = Term.create () in
    run_with_term term ?tick_period ?tick ~renderer quit t;
    Term.release term
