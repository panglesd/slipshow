(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr
open Fut.Result_syntax
open Brr_webmidi

let test log =
  Fut.map (Console.log_if_error ~use:()) @@
  let opts = Midi.Access.opts ~sysex:true () in
  let* a = Midi.Access.of_navigator ~opts G.navigator in
  log El.[txt' "Enumerating IO…"];
  let log_input mi () =
    Console.(log [mi]);
    log El.[txt' "Input: "; txt (Midi.Port.name (Midi.Input.as_port mi))]
  in
  let log_output mo () =
    Console.(log [mo]);
    log El.[txt' "Output: "; txt (Midi.Port.name (Midi.Output.as_port mo))]
  in
  let () = Midi.Access.inputs a log_input () in
  let () = Midi.Access.outputs a log_output () in
  Fut.ok ()

let main () =
  let h1 = El.h1 [El.txt' "Web MIDI test"] in
  let log_view = El.ol [] in
  let log cs = El.append_children log_view [El.li cs] in
  let children = [h1; log_view] in
  El.set_children (Document.body G.document) children;
  test log

let () = ignore (main ())
