open Notty
open Nottui
open Notty_lwt

type event = [
  | `Key of Unescape.key
  | `Mouse of Unescape.mouse
  | `Paste of Unescape.paste
  | `Resize of int * int
]

let copy_until quit ~f input =
  let quit = Lwt.map (fun () -> None) quit in
  let stream, push = Lwt_stream.create () in
  let rec aux () =
    Lwt.bind (Lwt.choose [quit; Lwt_stream.peek input]) @@ fun result ->
    match result with
    | None ->
      push None;
      Lwt.return_unit
    | Some x ->
      push (Some (f x));
      Lwt.bind (Lwt_stream.junk input) aux
  in
  Lwt.async aux;
  stream

let render ?quit ~size events doc =
  let renderer = Renderer.make () in
  let refresh_stream, push_refresh = Lwt_stream.create () in
  let root =
    Lwd.observe ~on_invalidate:(fun _ ->
        if not (Lwt_stream.is_closed refresh_stream) then
          push_refresh (Some ())
      ) doc
  in
  let quit, do_quit = match quit with
    | Some quit -> quit, None
    | None -> let t, u = Lwt.wait () in t, Some u
  in
  let events = copy_until quit events ~f:(fun e ->
      (e : [`Resize of _ | Unescape.event] :> [`Resize of _ | Ui.event]))
  in
  let size = ref size in
  let result, push = Lwt_stream.create () in
  let refresh () =
    (* FIXME This should use [Lwd.sample] with proper release management. *)
    let ui = Lwd.quick_sample root in
    Renderer.update renderer !size ui;
    push (Some (Renderer.image renderer))
  in
  refresh ();
  let process_event = function
    | `Key (`ASCII 'q', [`Meta]) as event ->
      begin match do_quit with
        | Some u -> Lwt.wakeup u ()
        | None -> ignore (Renderer.dispatch_event renderer event)
      end
    | #Ui.event as event ->
      ignore (Renderer.dispatch_event renderer event)
    | `Resize size' ->
      size := size';
      refresh ()
  in
  Lwt.async (fun () ->
      Lwt.finalize
        (fun () -> Lwt_stream.iter process_event events)
        (fun () -> push None; Lwt.return_unit)
    );
  Lwt.async (fun () -> Lwt_stream.iter refresh refresh_stream);
  result

let run ?quit doc =
  let term = Term.create () in
  let images = render ?quit ~size:(Term.size term) (Term.events term) doc in
  Lwt.finalize
    (fun () -> Lwt_stream.iter_s (Term.image term) images)
    (fun () -> (Term.release term))
