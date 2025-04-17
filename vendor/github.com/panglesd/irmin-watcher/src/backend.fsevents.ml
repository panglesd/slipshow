(*---------------------------------------------------------------------------
   Copyright (c) 2016 Thomas Gazagnaire. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Lwt.Infix

let src = Logs.Src.create "irw-fsevents" ~doc:"Irmin watcher using FSevents"

module Log = (val Logs.src_log src : Logs.LOG)

let create_flags = Fsevents.CreateFlags.detailed_interactive

let run_loop_mode = Cf.RunLoop.Mode.Default

let start_runloop dir =
  Log.debug (fun l -> l "start_runloop %s" dir);
  let watcher = Fsevents_lwt.create 0. create_flags [ dir ] in
  let stream = Fsevents_lwt.stream watcher in
  let event_stream = Fsevents_lwt.event_stream watcher in
  Cf_lwt.RunLoop.run_thread (fun runloop ->
      Fsevents.schedule_with_run_loop event_stream runloop run_loop_mode;
      if not (Fsevents.start event_stream) then
        prerr_endline "failed to start FSEvents stream")
  >|= fun _scheduler ->
  (* FIXME: should probably do something with the scheduler *)
  let stop_scheduler () =
    Fsevents_lwt.flush watcher >|= fun () ->
    Fsevents_lwt.stop watcher;
    Fsevents_lwt.invalidate watcher;
    Fsevents_lwt.release watcher
  in
  (stream, stop_scheduler)

let listen stream fn =
  let path_of_event { Fsevents_lwt.path; _ } = path in
  let iter () =
    Lwt_stream.iter_s
      (fun e ->
        let path = path_of_event e in
        Log.debug (fun l -> l "fsevents: %s" path);
        fn @@ path)
      stream
  in
  Core.stoppable iter

(* Note: we use FSevents to detect any change, and we re-read the full
   tree on every change (so very similar to active polling, but
   blocking on incoming FSevents instead of sleeping). We could
   probably do better, but at the moment it is more robust to do so,
   to avoid possible duplicated events. *)
let v =
  let listen dir f =
    Log.info (fun l -> l "FSevents mode");
    let events = ref [] in
    let cond = Lwt_condition.create () in
    start_runloop dir >>= fun (stream, stop_runloop) ->
    let rec wait_for_changes () =
      match List.rev !events with
      | [] -> Lwt_condition.wait cond >>= wait_for_changes
      | h :: t ->
          events := List.rev t;
          Lwt.return (`File h)
    in
    let unlisten =
      listen stream (fun path ->
          events := path :: !events;
          Lwt_condition.signal cond ();
          Lwt.return_unit)
    in
    Hook.v ~wait_for_changes ~dir f >|= fun unpoll () ->
    stop_runloop () >>= fun () ->
    unlisten () >>= fun () -> unpoll ()
  in
  lazy (Core.create listen)

let mode = `FSEvents

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Thomas Gazagnaire

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
