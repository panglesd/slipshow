(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open B0_std
open Result.Syntax

let range ~first ~last =
  let rec loop acc k = if k < first then acc else loop (k :: acc) (k-1) in
  loop [] last

(* Pathological tests for CommonMark parsers.

   These tests are from:

   https://github.com/commonmark/cmark/blob/master/test/pathological_tests.py

   The test expectations there use regexps with constant n matches
   which Str doesn't support. Instead we make the expectations more
   precise and trim and map newlines to spaces the HTML renders to
   avoid rendering layout discrepancies. *)

let massage s = String.trim (String.map (function '\n' -> ' ' | c -> c) s)

type test = { doc : string; i : string; exp : string; }

let tests =
  let n = 30000 (* should be pair *) in
  let p s = Fmt.str "<p>%s</p>" s in
  let ( + ) = ( ^ ) and cat = String.concat "" in
  let ( * ) s n = cat @@ List.map (Fun.const s) (range ~first:1 ~last:n) in
  [ { doc = "Nested strong emphasis";
      i = "*a **a "*n + "b" + " a** a*"*n;
      exp = p @@ "<em>a <strong>a "*n + "b" + " a</strong> a</em>"*n };
    { doc = "Many emphasis closers with no openers";
      i = "a_ "*n;
      exp = p @@ "a_ "*(n - 1) + "a_" };
    { doc = "Many emphasis openers with no closers";
      i = "_a "*n;
      exp = p @@ "_a "*(n - 1) + "_a" };
    { doc = "Many link closers with no openers";
      i = "a]"*n;
      exp = p @@ "a]"*n };
    { doc = "Many link openers with no closers";
      i = "[a"*n;
      exp = p @@ "[a"*n; };
    { doc = "Mismatched openers and closers";
      i = "*a_ "*n;
      exp = p @@ "*a_ "*(n-1) + "*a_" };
    { doc = "Cmark issue #389";
      i = "*a "*n + "_a*_ "*n;
      exp = p @@ "<em>a "*n + "_a</em>_ "*(n - 1) + "_a</em>_" };
    { doc = "Openers and closers multiple of 3";
      i = "a**b" + "c* "*n;
      exp = p @@ "a**b" + "c* "*(n - 1) + "c*" };
    { doc = "Link openers and emph closers";
      i = "[ a_"*n;
      exp = p @@ "[ a_"*n };
    { doc = "Sequence '[ (](' repeated";
      i = "[ (]("*n;
      exp = p @@ "[ (]("*n; };
    { doc = "Sequence '![[]()' repeated";
      i = "![[]()"*n;
      exp = p @@ {|![<a href=""></a>|}*n; };
    { doc = "Hard link/emphasis case";
      i = "**x [a*b**c*](d)";
      exp = p @@ {|**x <a href="d">a<em>b**c</em></a>|} };
    { doc = "Nested brackets [* a ]*";
      i = "["*n + "a" + "]"*n;
      exp = p @@ "["*n + "a" + "]"*n };
    { doc = "Nested block quotes";
      i = "> "*n + "a";
      exp = "<blockquote> "*n + p "a" + " </blockquote>"*n };
    { doc = "Deeply nested lists";
      i = cat (List.map (fun n -> "  "*n + "* a\n") (range ~first:0 ~last:499));
      exp = "<ul> "+"<li>a <ul> "*499+"<li>a</li> </ul> "+"</li> </ul> "*499 };
    { doc = "U+0000 in input";
      i = "abc\x00de\x00";
      exp = p @@ "abc\u{FFFD}de\u{FFFD}" };
    { doc = "Backticks";
      i = cat (List.map (fun n -> "e" + "`"*n) (range ~first:1 ~last:2500));
      exp =
        p @@ cat (List.map (fun n -> "e" + "`"*n) (range ~first:1 ~last:2500))};
    { doc = "Unclosed inline link <>";
      i = "[a](<b"*n;
      exp = p @@ "[a](&lt;b"*n; };
    { doc = "Unclosed inline link";
      i = "[a](b"*n;
      exp = p @@ "[a](b"*n; };
    { doc = "Unclosed '<!--'";
      i = "</" + "<!--"*n;
      exp = p @@ "&lt;/" + "&lt;!--"*n; };
    { doc = "Nested inlines";
      i = "*"*n + "a" + "*"*n;
      exp = p @@ "<strong>"*(n/2) + "a" + "</strong>"* (n/2); };
    { doc = "Many references";
      i =
        cat (List.map (fun n -> Fmt.str "[%d]: u\n" n) (range ~first:1 ~last:n))
        + "[0]"*n;
      exp = p @@ "[0]"*n; }
  ]

(* Run commands on a deadline. Something like this should be added to B0_kit. *)

type deadline_exit = [ Os.Cmd.status | `Timeout ]
type deadline_run = Mtime.Span.t * deadline_exit

let deadline_run ~timeout ?env ?cwd ?stdin ?stdout ?stderr cmd =
  let rec wait ~deadline dur pid =
    let* st = Os.Cmd.spawn_poll_status pid in
    match st with
    | Some st -> Ok (Os.Mtime.count dur, (st :> deadline_exit))
    | None ->
        if Mtime.Span.compare (Os.Mtime.count dur) deadline < 0
        then (ignore (Os.sleep Mtime.Span.ms); wait ~deadline dur pid) else
        let* () = Os.Cmd.kill pid Sys.sigkill in
        let* _st = Os.Cmd.spawn_wait_status pid in
        Ok (Os.Mtime.count dur, `Timeout)
  in
  let* pid = Os.Cmd.spawn ?env ?cwd ?stdin ?stdout ?stderr cmd in
  wait ~deadline:timeout (Os.Mtime.counter ()) pid

(* Running the tests *)

type test_exit = [ deadline_exit | `Unexpected of string * string ]

let pp_ok = Fmt.st [`Fg `Green]
let pp_err = Fmt.st [`Fg `Red]
let pp_test_exit ppf = function
| `Exited 0 -> Fmt.pf ppf "%a" pp_ok "ok"
| `Exited n -> Fmt.pf ppf "%a with %d" pp_err "exited" n
| `Signaled sg -> Fmt.pf ppf "%a with %a" pp_err "signaled" Fmt.sys_signal sg
| `Timeout -> Fmt.pf ppf "%a" pp_err "timed out"
| `Unexpected (exp, res)->
    let pp_data = Fmt.truncated ~max:50 in
    Fmt.pf ppf "@[<v>%a:@,Expect: %a@,Found : %a@,@]"
      pp_err "unexpected output" pp_data exp pp_data res

let pp_tests_params ppf (timeout_s, cmd) =
  Fmt.pf ppf "@[<v>Testing: %a@,Timeout: %a@]"
    Cmd.pp cmd Mtime.Span.pp timeout_s

let pp_tests_summary ppf (count, fail, dur) = match fail = 0 with
| true ->
    Fmt.pf ppf "[ %a ] All %d tests succeeded in %a"
      pp_ok "OK" count Mtime.Span.pp dur
| false ->
    Fmt.pf ppf "[%a] %d out of %d tests failed in %a"
     pp_err "FAIL" fail count Mtime.Span.pp dur

let run_test ~timeout t cmd =
  Result.join @@ Os.File.with_tmp_fd @@ fun tmpfile fd ->
  let stdin = Os.Cmd.in_string t.i in
  let stdout = Os.Cmd.out_fd ~close:false fd in
  let* dur, exit = deadline_run ~timeout ~stdin ~stdout cmd in
  if exit <> `Exited 0 then Ok (dur, (exit :> test_exit)) else
  let* res = Os.File.read tmpfile in
  let res = massage res in
  if String.equal (String.trim t.exp) res
  then Ok (dur, (exit :> test_exit)) else Ok (dur, `Unexpected (t.exp, res))

let run_tests ~timeout cmd =
  let do_test t (dur, fail, i) =
    Fmt.pr "%2d. %s: @?" i t.doc;
    let* d, exit = run_test ~timeout t cmd in
    let fail = match exit with `Exited 0 -> fail | _ -> fail + 1 in
    Fmt.pr "%a in %a@]@." pp_test_exit exit Mtime.Span.pp d;
    Ok (Mtime.Span.add dur d, fail, i + 1)
  in
  Log.if_error ~use:2 @@
  let* cmd = Os.Cmd.get cmd in
  let init = Mtime.Span.zero, 0, 1 in
  Log.stdout (fun m -> m "%a" pp_tests_params (timeout, cmd));
  let* dur, fail, i = List.fold_stop_on_error do_test tests init in
  Log.stdout (fun m -> m "%a" pp_tests_summary (i - 1, fail, dur));
  Ok (Int.min fail 1)

let dump_tests dir =
  let dump_test dir t i =
    let name = Fmt.str "patho-test-%02d" i in
    let force = true and make_path = true in
    let src = Fpath.(dir / name + ".md") in
    let exp = Fpath.(dir / name + ".exp") in
    let* () = Os.File.write ~force ~make_path src t.i in
    let* () = Os.File.write ~force ~make_path exp t.exp in
    Ok (i + 1)
  in
  Log.if_error ~use:3 @@
  let* dir = Fpath.of_string dir in
  List.fold_stop_on_error (dump_test dir) tests 1

let main () =
  let usage =
    "Usage: pathological -- TOOL ARG…\n\
     TOOL must read CommonMark on stdin and write HTML on stdout."
  in
  let dump_dir = ref None and timeout_s = ref 1 and cmd = ref [] in
  let set_dump_dir s = dump_dir := Some s in
  let add_arg s = cmd := s :: !cmd in
  let args =
    [ "--timeout-s", Arg.Set_int timeout_s, " Timeout in secs (defaults to 1)";
      "-d", Arg.String set_dump_dir, "DIR  Don't test, dump tests to DIR";
      "--", Arg.Rest add_arg, "TOOL ARG…  Executable to test."; ]
  in
  Arg.parse args add_arg usage;
  match !dump_dir with
  | Some dir -> dump_tests dir
  | None ->
      let timeout = Mtime.Span.(!timeout_s * s) in
      let cmd = Cmd.of_list Fun.id (List.rev !cmd) in
      if Cmd.is_empty cmd
      then (Log.err (fun m -> m "No tool specified. Try '--help'."); exit 2)
      else run_tests ~timeout cmd

let () = if !Sys.interactive then () else exit (main ())
