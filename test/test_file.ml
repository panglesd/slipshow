(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr

let file_view file data_uri contents =
  let field_name f = El.strong [El.txt' f] in
  let field f d = [field_name f; El.br (); El.pre [El.txt d] ] in
  let jstr_of_type t = if Jstr.is_empty t then Jstr.v "Unknown" else t in
  List.concat
  [ field "Name" (File.name file);
    field "Modified" (Jstr.of_int @@ File.last_modified_ms file);
    field "Byte size" (Jstr.of_int @@ Blob.byte_length (File.as_blob file));
    field "Type" (jstr_of_type @@ Blob.type' (File.as_blob file));
    field "Data URL" data_uri;
    field "Content" contents ]

let show_file viewer file =
  let muddle_error = function Ok v -> v | Error e -> Jv.Error.message e in
  let blob = File.as_blob file in
  let contents =
    if Jv.has "text" blob then Fut.map muddle_error (Blob.text blob) else
    Fut.return (Jstr.v "text() method unsupported in this browser")
  in
  let data_uri = Fut.map muddle_error (Blob.data_uri blob) in
  let set_viewer (duri, c) = El.set_children viewer (file_view file duri c) in
  El.set_children viewer [];
  Fut.await (Fut.pair data_uri contents) set_viewer

let file_selector ~on_change =
  (* The input file can't be styled we hide it and use a click forwarding
     button instead. *)
  let i = El.input ~at:At.[type' (Jstr.v "file")] () in
  let b = El.button [ El.txt' "Choose file…" ] in
  El.set_inline_style El.Style.display (Jstr.v "none") i;
  ignore (Ev.listen Ev.click (fun e -> El.click i) (El.as_target b));
  ignore (Ev.listen Ev.change (fun e -> on_change (El.Input.files i))
            (El.as_target i));
  El.span [i; b]

let main () =
  let h1 = El.h1 [El.txt' "Show file"] in
  let viewer = El.div [] in
  let on_change files = show_file viewer (List.hd files) in
  let selector = file_selector ~on_change in
  El.set_children (Document.body G.document) [h1; El.p [selector]; viewer]

let () = main ()
