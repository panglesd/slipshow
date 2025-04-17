(*---------------------------------------------------------------------------
   Copyright (c) 2016 Thomas Gazagnaire. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Lwt.Infix

let src = Logs.Src.create "irw-inotify" ~doc:"Irmin watcher using Inotify"

module Log = (val Logs.src_log src : Logs.LOG)

let rec mkdir d =
  let perm = 0o0700 in
  try Unix.mkdir d perm with
  | Unix.Unix_error (Unix.EEXIST, "mkdir", _) -> ()
  | Unix.Unix_error (Unix.ENOENT, "mkdir", _) ->
      mkdir (Filename.dirname d);
      Unix.mkdir d perm

let start_watch dir =
  Log.debug (fun l -> l "start_watch %s" dir);
  if not (Sys.file_exists dir) then mkdir dir;
  Lwt_inotify.create () >>= fun i ->
  Lwt_inotify.add_watch i dir
    [ Inotify.S_Create; Inotify.S_Modify; Inotify.S_Move; Inotify.S_Delete ]
  >|= fun u ->
  let stop () = Lwt_inotify.rm_watch i u >>= fun () -> Lwt_inotify.close i in
  (i, stop)

let listen dir i fn =
  let event_kinds (_, es, _, _) = es in
  let pp_kind = Fmt.of_to_string Inotify.string_of_event_kind in
  let path_of_event (_, _, _, p) =
    match p with None -> dir | Some p -> Filename.concat dir p
  in
  let rec iter i =
    Lwt.try_bind
      (fun () ->
        Lwt_inotify.read i >>= fun e ->
        let path = path_of_event e in
        let es = event_kinds e in
        Log.debug (fun l -> l "inotify: %s %a" path Fmt.(Dump.list pp_kind) es);
        fn path;
        Lwt.return_unit)
      (fun () -> iter i)
      (function
        | Unix.Unix_error (Unix.EBADF, _, _) ->
            Lwt.return_unit (* i has just been closed by {!stop} *)
        | e -> Lwt.fail e)
  in
  Core.stoppable (fun () -> iter i)

(* Note: we use Inotify to detect any change, and we re-read the full
   tree on every change (so very similar to active polling, but
   blocking on incoming Inotify events instead of sleeping). We could
   probably do better, but at the moment it is more robust to do so,
   to avoid possible duplicated events. *)
let v =
  let listen dir f =
    Log.info (fun l -> l "Inotify mode");
    let events = ref [] in
    let cond = Lwt_condition.create () in
    start_watch dir >>= fun (i, stop_watch) ->
    let rec wait_for_changes () =
      match List.rev !events with
      | [] -> Lwt_condition.wait cond >>= wait_for_changes
      | h :: t ->
          events := List.rev t;
          Lwt.return (`File h)
    in
    let unlisten =
      listen dir i (fun path ->
          events := path :: !events;
          Lwt_condition.signal cond ())
    in
    Hook.v ~wait_for_changes ~dir f >|= fun unpoll () ->
    stop_watch () >>= fun () ->
    unlisten () >>= fun () -> unpoll ()
  in
  lazy (Core.create listen)

let mode = `Inotify

let uname () =
  try
    let ic = Unix.open_process_in "uname" in
    let uname = input_line ic in
    let () = close_in ic in
    Some uname
  with Unix.Unix_error _ -> None

let is_linux () = Sys.os_type = "Unix" && uname () = Some "Linux"

type mode = [ `Polling | `Inotify ]

let mode, v =
  if is_linux () then ((mode :> mode), v) else Polling.((mode :> mode), v)

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
