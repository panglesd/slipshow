(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr

let test_basic_log () =
  let l = [4;5;6] in
  let a = [|4;5;6|] in
  Console.(log [1; 1.5; true; Jv.true'; "ha!"; str "hi!"; Jstr.v "ho!"]);
  Console.(log [l; a]);
  Console.(log [str "Window: %o\nNavigator: %o"; G.window; G.navigator]);
  ()

let test_levels () =
  Console.(log [str "Log message."]);
  Console.(error [str "Error message."]);
  Console.(warn [str "Warning message."]);
  Console.(info [str "Info message."]);
  Console.(debug [str "Debug message."]);
  ()

let test_assert_and_trace () =
  Console.(assert' true [str "Unfailed assertion!"]);
  Console.(assert' false [str "Failed assertion! This was"; Jv.false']);
  Console.(assert' (Jv.has "zorglub" Jv.global) [str "No globalThis.zorglub!"]);
  Console.(trace [str "Trace me to here!"]);
  Console.dir G.window;
  Console.table
    (Jv.of_jstr_array [|Jstr.v "This"; Jstr.v "That"; Jstr.v "Those"|]);
  ()

let test_grouping () =
  Console.(group [str "That's a group"; str "Yo"]);
  Console.(log [str "Inside the group"]);
  Console.(warn [Jstr.v "Again but warning"]);
  Console.group_end ();
  Console.(group ~closed:true [str "A closed group"; str "Closed"]);
  Console.(log [str "Inside the closed group"]);
  Console.(warn [Jstr.v "Again but warning"]);
  Console.group_end ();
  ()

let test_counting () =
  let ha = Jstr.v "ha" in
  Console.count ha;
  Console.count ha;
  Console.count ha;
  Console.count_reset ha;
  Console.count ha;
  ()

let test_timing () =
  let max = 100 in
  let l = Jstr.v "fun" in
  Console.time l;
  let rec loop i = if i <= max then loop (i + 1) else () in loop 0;
  Console.(time_log l [str "recursive loop from"; 0; str "to"; max]);
  Console.time_end l;
  let l = Jstr.v "loop" in
  Console.time l;
  for i = 0 to 100 do () done;
  Console.(time_log l [str "for loop from"; 0; str "to"; max]);
  Console.time_end l;
  ()

let test_profiling () =
  let max = 200 in
  let p = Jstr.v "myprofile" in
  Console.profile p;
  for i = 0 to max do
    if i mod 50 = 0 then Console.time_stamp (Jstr.of_int i);
  done;
  Console.profile_end p;
  ()

let test () =
  test_basic_log ();
  test_levels ();
  test_assert_and_trace ();
  test_grouping ();
  test_counting ();
  test_timing ();
  test_profiling ();
  ()

let button onclick label =
  let but = El.button [El.txt (Jstr.v label)] in
  ignore (Ev.listen Ev.click onclick (El.as_target but)); but

let main () =
  let h1 = El.h1 [El.txt' "Console test"] in
  let info = El.p [ El.txt' "See the browser console"] in
  let clear = button (fun e -> Console.clear ()) "Clear console" in
  El.set_children (Document.body G.document) [h1; info; clear];
  test ()

let () = main ()
