(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr
open Brr_io
open Brr_webworkers

let recv_from_page e =
  let data = (Message.Ev.data (Ev.as_type e) : Jstr.t) in
  match Jstr.to_string data with
  | "Work!" -> Worker.G.post Jstr.(v "Page said: " + data + v " I say Revolt!")
  | _ -> assert false

let worker_main () =
  Console.(log [str "Worker hello!"]);
  let msg = Ev.next Message.Ev.message G.target in
  let _ = Fut.map recv_from_page msg in
  ()

let spawn_worker () = try Ok (Worker.create (Jstr.v "test_worker.js")) with
| Jv.Error e -> Error e

let recv_from_worker ~view e =
  let data : Jstr.t = Message.Ev.data (Ev.as_type e) in
  El.set_children view [El.p El.[txt Jstr.(v "Worker says: " + data)]]

let page_main () =
  let h1 = El.h1 [El.txt' "Test workers"] in
  let info = El.p [ El.strong [El.txt' "Note."];
                    El.txt' " Doesn't work over the file:// protocol."]
  in
  let view = El.div [] in
  El.set_children (Document.body G.document) [h1; info; view];
  match spawn_worker () with
  | Error e -> El.set_children view [El.p El.[txt (Jv.Error.message e)]]
  | Ok w ->
      let msg = Ev.next Message.Ev.message (Worker.as_target w) in
      let _ = Fut.map (recv_from_worker ~view) msg in
      Worker.post w (Jstr.v "Work!");
      ()

let main () = if Worker.ami () then worker_main () else page_main ()
let () = main ()
