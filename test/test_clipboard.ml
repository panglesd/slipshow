(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr
open Brr_io
open Fut.Result_syntax

let handle_error ~view = function
| Ok () ->  ()
| Error e ->
    let err = Jv.Error.message e in
    let msg = El.p [El.txt Jstr.(v "An error occured: " + err)] in
    El.set_children view [msg]

let show_clipboard view () =
  ignore @@ Fut.map (handle_error ~view) @@
  let c = Clipboard.of_navigator G.navigator in
  let* t = Clipboard.read_text c in
  let contents = El.strong [El.txt' "Contents:"] in
  El.set_children view [El.p [contents; El.pre [El.txt t]]];
  Fut.ok ()

let put_clipboard view () =
  ignore @@ Fut.map (handle_error ~view) @@
  let c = Clipboard.of_navigator G.navigator in
  let* t = Clipboard.write_text c (Jstr.v "Brr!") in
  El.set_children view [El.p [El.txt' "Done!"]];
  Fut.ok ()

let button ?at onclick label =
  let but = El.button ?at [El.txt (Jstr.v label)] in
  ignore (Ev.listen Ev.click (fun _e -> onclick ()) (El.as_target but)); but

let main () =
  let h1 = El.h1 [El.txt' "Clipboard test"] in
  let view = El.p [] in
  let show = button (show_clipboard view) "Show clipboard text" in
  let put = button (put_clipboard view) "Put ‘Brr!’ in the clipboard" in
  let children = [h1; El.p [show; put]; view] in
  El.set_children (Document.body G.document) children

let () = main ()
