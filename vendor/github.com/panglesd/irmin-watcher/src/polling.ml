(*---------------------------------------------------------------------------
   Copyright (c) 2016 Thomas Gazagnaire. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Lwt.Infix

let src = Logs.Src.create "irw-polling" ~doc:"Irmin watcher using using polling"

module Log = (val Logs.src_log src : Logs.LOG)

let listen ~wait_for_changes dir =
  Log.info (fun l -> l "Polling mode");
  Hook.v ~wait_for_changes ~dir

let with_delay delay =
  let wait_for_changes () = Lwt_unix.sleep delay >|= fun () -> `Unknown in
  Core.create (listen ~wait_for_changes)

let mode = `Polling

let v =
  let wait_for_changes () =
    Lwt_unix.sleep !Core.default_polling_time >|= fun () -> `Unknown
  in
  lazy (Core.create (listen ~wait_for_changes))

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
