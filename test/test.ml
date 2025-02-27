(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

let test_mapper_table_bug_14 () =
  let table =
    "| a | b | c |\n\
     |---|---|---|\n\
     | a | b | c |\n\
     |   | b | c |\n\
     |   |   | c |\n"
  in
  let doc = Cmarkit.Doc.of_string ~layout:true ~strict:false table in
  let mdoc = Cmarkit.Mapper.map_doc (Cmarkit.Mapper.make ()) doc in
  print_endline "Expectation for mapper table bug #14:\n";
  print_endline (Cmarkit_commonmark.of_doc mdoc);
  ()

let main () =
  test_mapper_table_bug_14 ();
  ()

let () = if !Sys.interactive then () else main ()
