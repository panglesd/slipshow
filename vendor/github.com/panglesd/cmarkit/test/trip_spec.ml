(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open B0_std
open Result.Syntax
open B0_json

let notrip_reasons =
  (* For those renders that are only correct we indicate here
     the reason why they do not round trip. *)
  let tabs = "Tab stop as spaces" in
  let block_quote_regular = "Block quote regularization" in
  let indented_blanks = "Indented blank line" in
  let eager_escape = "Eager escaping" in
  let escape_drop = "Escape drop (not needed)" in
  let charref = "Entity or character reference substitution" in
  let empty_item = "List item with empty first line gets space after marker" in
  let unlazy = "Suppress lazy continuation line" in
  let code_fence_regular = "Code fence regularization" in
  let unindented_blanks = "Unindented blank line after indented code block." in
  [ 1, tabs; 2, tabs; 4, tabs; 5, tabs; 6, tabs; 7, tabs; 8, tabs; 9, tabs;
    (* Backslash escapes. *)
    12, escape_drop; 13, eager_escape; 14, eager_escape;
    22, escape_drop; 23, escape_drop; 24, escape_drop;
    (* Entity and charrefs *)
    25, charref; 26, charref; 27, charref; 28, eager_escape; 29, eager_escape;
    30, eager_escape; 32, charref; 33, charref; 34, charref; 37, charref;
    38, charref; 41, charref (* and eager_escape *);
    (* Precedence *)
    42, eager_escape;
    (* Thematic breaks *)
    44, eager_escape; 45, eager_escape; 46, eager_escape; 49, eager_escape;
    55, eager_escape; 56, eager_escape;
    (* ATX headings *)
    63, eager_escape; 64, eager_escape; 70, eager_escape; 74, eager_escape;
    75, eager_escape; 76, eager_escape;
    (* Setext headings *)
    85, indented_blanks; 87, eager_escape; 88, eager_escape; 90, eager_escape;
    91, eager_escape; 93, eager_escape; 97, eager_escape;
    (* Indented code blocks *)
    108, indented_blanks; 109, indented_blanks; 110, indented_blanks;
    111, indented_blanks; 117, unindented_blanks;
    (* Fenced code blocks *)
    131, code_fence_regular; 132, code_fence_regular; 133, code_fence_regular;
    135, code_fence_regular; 136, code_fence_regular;
    (* Link references *)
    194, eager_escape; 197, eager_escape; 199, eager_escape; 201, eager_escape;
    202, escape_drop; 209, eager_escape; 211, eager_escape; 212, eager_escape;
    213, eager_escape; 216, eager_escape;
    (* Block quotes *)
    229, block_quote_regular; 230, block_quote_regular;
    232, unlazy; 233, unlazy; 238, block_quote_regular (* and eager escape *);
    239, block_quote_regular; 240, block_quote_regular;
    241, block_quote_regular; 244, unlazy;
    247, unlazy; 249, block_quote_regular; 250, unlazy;
    251, unlazy (* and block_quote_regular *); 251, block_quote_regular;
    (* List items *)
    254, indented_blanks; 256, indented_blanks; 258, indented_blanks;
    259, block_quote_regular (* and indented_blanks *) ;
    260, block_quote_regular; 261, eager_escape; 262, indented_blanks;
    263, indented_blanks; 264, indented_blanks; 269, eager_escape;
    270, indented_blanks; 271, indented_blanks; 273, indented_blanks;
    274, indented_blanks; 277, indented_blanks; 278, empty_item;
    280, empty_item; 281, empty_item; 283, empty_item; 284, empty_item;
    285, eager_escape; 286, indented_blanks;
    287, indented_blanks; 288, indented_blanks; 289, indented_blanks;
    290, unlazy (* and indented_blanks *);
    291, unlazy; 292, unlazy; 293, unlazy;
    (* Lists *)
    304, eager_escape;
    306, indented_blanks; 307, indented_blanks; 309, indented_blanks;
    311, indented_blanks; 312, indented_blanks; 313, indented_blanks;
    314, indented_blanks; 315, empty_item; 316, indented_blanks;
    317, indented_blanks; 318, indented_blanks; 319, indented_blanks;
    320, block_quote_regular; 324, indented_blanks; 325, indented_blanks;
    326, indented_blanks;
    (* Code spans *)
    327, eager_escape;
    338, eager_escape; 341, eager_escape; 341, eager_escape; 342, eager_escape;
    343, eager_escape; 344, eager_escape; 345, eager_escape; 346, eager_escape;
    347, eager_escape; 348, eager_escape; 349, eager_escape;
    (* Emphasis and strong emphasis *)
    351, eager_escape; 352, eager_escape; 353, eager_escape; 357, eager_escape;
    358, eager_escape; 359, eager_escape; 360, eager_escape; 361, eager_escape;
    362, eager_escape; 364, eager_escape; 365, eager_escape; 366, eager_escape;
    367, eager_escape; 370, eager_escape; 371, eager_escape; 373, eager_escape;
    374, eager_escape; 375, eager_escape; 378, eager_escape; 379, eager_escape;
    382, eager_escape; 383, eager_escape; 384, eager_escape; 385, eager_escape;
    386, eager_escape; 387, eager_escape; 390, eager_escape; 391, eager_escape;
    396, eager_escape; 397, eager_escape; 399, eager_escape; 400, eager_escape;
    401, eager_escape; 411, eager_escape; 416, eager_escape; 419, eager_escape;
    420, eager_escape; 433, eager_escape; 434, eager_escape; 435, eager_escape;
    437, eager_escape; 438, eager_escape; 440, eager_escape; 441, eager_escape;
    442, eager_escape; 443, eager_escape; 444, eager_escape; 445, eager_escape;
    446, eager_escape; 447, eager_escape; 449, eager_escape; 450, eager_escape;
    452, eager_escape; 453, eager_escape; 454, eager_escape; 455, eager_escape;
    456, eager_escape; 457, eager_escape; 458, eager_escape; 468, eager_escape;
    469, eager_escape; 470, eager_escape; 471, eager_escape; 472, eager_escape;
    473, eager_escape; 474, eager_escape; 475, eager_escape; 476, eager_escape;
    479, eager_escape; 480, eager_escape;
    (* Links *)
    487, eager_escape; 489, eager_escape; 490, eager_escape; 492, eager_escape;
    493, eager_escape; 495, eager_escape; 496, eager_escape; 499, escape_drop;
    502, charref;
    505, eager_escape; 505, eager_escape; 507, eager_escape; 510, eager_escape;
    511, eager_escape; 512, eager_escape; 513, eager_escape; 517, eager_escape;
    518, eager_escape; 519, eager_escape; 520, eager_escape; 521, eager_escape;
    522, eager_escape; 523, eager_escape; 524, eager_escape; 525, eager_escape;
    527, eager_escape; 531, eager_escape; 532, eager_escape; 533, eager_escape;
    534, eager_escape; 535, eager_escape; 536, eager_escape; 537, eager_escape;
    541, eager_escape; 542, eager_escape;
    544, eager_escape; 545, eager_escape; 546, eager_escape; 547, eager_escape;
    550, eager_escape; 551, eager_escape; 555, eager_escape; 558, eager_escape;
    559, eager_escape; 562, eager_escape; 563, eager_escape; 568, eager_escape;
    570, eager_escape;
    (* Images *)
    586, eager_escape; 589, eager_escape; 591, eager_escape;
    (* Autolinks *)
    601, eager_escape; 605, eager_escape (* and escape_drop *);
    606, eager_escape; 607, eager_escape;
    608, eager_escape; 609, eager_escape;
    (* Raw HTML *)
    617, eager_escape; 618, eager_escape; 619, eager_escape; 620, eager_escape;
    621, eager_escape; 623, eager_escape; 625, eager_escape; 626, eager_escape;
    632, eager_escape (* and escape_drop *);
    (* Hard line breaks *)
    644, eager_escape; 646, eager_escape;
    (* Textual content *)
    650, eager_escape;
  ]

let status st ex_num =
  Log.stdout @@ fun m ->
  let pp_ex ppf n =
    Fmt.pf ppf "https://spec.commonmark.org/%s/#example-%d" Spec.version n
  in
  let pp_st, st = match st with
  | `Trip -> Spec.ok, "TRIP"
  | `Ok -> Spec.ok, " OK "
  | `Fail -> Spec.fail, "FAIL"
  in
  m "[%a] %a" pp_st st Fmt.(code' pp_ex) ex_num

let renderer =
  (* Specification tests render empty elements as XHTML. *)
  Cmarkit_html.xhtml_renderer ~safe:false ()

let test (t : Spec.test) ~show_diff =
  (* Parse with layout, render commonmark, if not equal reparse the render
     and render it to HTML, if that succeeds it's a correct rendering. *)
  let doc = Cmarkit.Doc.of_string ~layout:true t.markdown in
  let md = Cmarkit_commonmark.of_doc doc in
  let has_notrip_reason =
    Option.is_some (List.assoc_opt t.example notrip_reasons)
  in
  if String.equal md t.markdown then begin
    if has_notrip_reason then begin
      status `Trip t.example;
      Log.warn (fun m -> m "Example trips but is only supposed to be correct.")
    end;
    `Trip
  end else
  let doc' = Cmarkit.Doc.of_string md in
  let html = Cmarkit_renderer.doc_to_string renderer doc' in
  let pp_reason ppf () = match List.assoc_opt t.example notrip_reasons with
  | None -> () | Some reason -> Fmt.pf ppf "Reason: %s@," reason
  in
  match String.equal html t.html with
  | true ->
      if show_diff || not has_notrip_reason then begin
        let diff = Spec.diff ~spec:t.markdown md in
        status `Ok t.example;
        Log.stdout (fun m -> m "@[<v>%a%s@]" pp_reason () diff)
      end;
      `Ok
  | false ->
      let md_diff = Spec.diff ~spec:t.markdown md in
      let html_diff = Spec.diff ~spec:t.html html in
      let diff = String.concat "\n" [t.markdown; md_diff; html_diff] in
      status `Fail t.example;
      if has_notrip_reason then begin
        Log.warn (fun m -> m "Example fails but should be correct.")
      end;
      Log.stdout (fun m -> m "@[<v>%a%s@]" pp_reason () diff); `Fail

let test_no_layout (t : Spec.test) =
  (* Parse without layout, render commonmark, reparse, render to HTML *)
  let doc = Cmarkit.Doc.of_string ~layout:false t.markdown in
  let md = Cmarkit_commonmark.of_doc doc in
  let doc' = Cmarkit.Doc.of_string md in
  let html = Cmarkit_renderer.doc_to_string renderer doc' in
  if String.equal html t.html then Ok () else
  let md_diff = Spec.diff ~spec:t.markdown md in
  let html_diff = Spec.diff ~spec:t.html html in
  let d = [t.markdown; "Markdown render:"; md_diff; "HTML render:"; html_diff]in
  let diff = String.concat "\n" d in
  status `Fail t.example;
  Log.stdout (fun m -> m "@[<v>Parse without layout render:@,%s@]" diff);
  Error ()

let log_result n valid fail no_layout_fail =
  let trip = n - valid - fail in
  if fail <> 0 then
    (Log.stdout
     @@ fun m -> m "[%a] %d out of %d fail." Spec.fail "FAIL" fail n);
  if valid <> 0 then
    (Log.stdout @@ fun m ->
     m "[%a] %d out of %d are correct."
       Spec.ok " OK " valid n);
  if trip <> 0 then
    (Log.stdout @@ fun m ->
     let count = if n = trip then "All" else Fmt.str "%d out of" trip in
     m "[%a] %s %d round trip." Spec.ok "TRIP" count n);
  Log.stdout @@ fun m ->
  let count, pp, st = match no_layout_fail with
  | 0 -> "All", Spec.ok, " OK "
  | f -> Fmt.str "%d out of" f, Spec.fail, "FAIL"
  in
  Log.stdout @@ fun m ->
  m "[%a] %s %d on parse without layout." pp st count n

let run_tests test_file examples show_diff =
  Log.if_error ~use:1 @@
  let* tests = Spec.parse_tests test_file in
  let select (t : Spec.test) = examples = [] || List.mem t.example examples in
  let do_test (n, ok, fail, no_layout_fail as acc) t =
    if not (select t) then acc else
    let no_layout_fail = match test_no_layout t with
    | Ok () -> no_layout_fail | Error _ -> no_layout_fail + 1
    in
    match test t ~show_diff with
    | `Trip -> (n + 1, ok, fail, no_layout_fail)
    | `Ok -> (n + 1, ok + 1, fail, no_layout_fail)
    | `Fail -> (n + 1, ok, fail + 1, no_layout_fail)
  in
  let counts = (0, 0, 0, 0) in
  let n, ok, fail, no_layout_fail = List.fold_left do_test counts tests in
  log_result n ok fail no_layout_fail;
  Ok 0

let main () =
  let show_diff, file, examples = Spec.cli ~exe:"trip_spec" () in
  run_tests file examples show_diff

let () = if !Sys.interactive then () else exit (main ())
