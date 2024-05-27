(*---------------------------------------------------------------------------
   Copyright (c) 2021 The cmarkit programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

open B0_std
open Result.Syntax
open B0_json

let status ~pass ex_num =
  Log.app @@ fun m ->
  let pp_ex ppf n =
    Fmt.pf ppf "https://spec.commonmark.org/%s/#example-%d" Spec.version n
  in
  let pp, st = if pass then Spec.ok, "PASS" else Spec.fail, "FAIL" in
  m "[%a] %a" pp st Fmt.(code pp_ex) ex_num

let renderer =
  (* Specification tests render empty elements as XHTML. *)
  Cmarkit_html.xhtml_renderer ~safe:false ()

let test (t : Spec.test) =
  let doc = Cmarkit.Doc.of_string t.markdown in
  let html = Cmarkit_renderer.doc_to_string renderer doc in
  if String.equal html t.html then Ok ((* status ~pass:true t.example *)) else
  let diff = String.concat "\n" [t.markdown; Spec.diff ~spec:t.html html] in
  status ~pass:false t.example;
  Log.app (fun m -> m "%s" diff);
  Error ()

let run_tests test_file examples (* empty is all *) =
  let log_ok n = Log.app @@ fun m ->
    m "[ %a ] All %d tests succeeded." Spec.ok "OK" n
  in
  let log_fail n f = Log.app @@ fun m ->
    m "[%a] %d out of %d tests failed." Spec.fail "FAIL" f n
  in
  Log.if_error ~use:1 @@
  let* tests = Spec.parse_tests test_file in
  let select (t : Spec.test) = examples = [] || List.mem t.example examples in
  let do_test (n, fail as acc) t =
    if not (select t) then acc else
    match test t with
    | Ok () -> (n + 1, fail)
    | Error () -> (n + 1, fail + 1)
  in
  let n, fail = List.fold_left do_test (0, 0) tests in
  if fail = 0 then (log_ok n; Ok 0) else (log_fail n fail; Ok 1)

let main () =
  let _, file, examples = Spec.cli ~exe:"test_spec" () in
  Fmt.set_tty_cap ();
  run_tests file examples

let () = if !Sys.interactive then () else exit (main ())

(*---------------------------------------------------------------------------
   Copyright (c) 2021 The cmarkit programmers

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
