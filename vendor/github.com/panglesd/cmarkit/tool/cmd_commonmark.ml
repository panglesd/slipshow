(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Std
open Result.Syntax

let diff src render =
  let env = ["GIT_CONFIG_SYSTEM=/dev/null"; "GIT_CONFIG_GLOBAL=/dev/null"; ] in
  let set_env = match Sys.win32 with
  | true -> String.concat "" (List.map (fun e -> "set " ^ e ^ " && ") env)
  | false -> String.concat " " env
  in
  let diff = "git diff --ws-error-highlight=all --no-index --patience " in
  let src_file = "src" and render_file = "render" in
  let cmd = String.concat " " [set_env; diff; src_file; render_file] in
  Result.join @@ Result.join @@ Os.with_tmp_dir @@ fun dir ->
  Os.with_cwd dir @@ fun () ->
  let* () = Os.write_file src_file src in
  let* () = Os.write_file render_file render in
  Ok (Sys.command cmd)

let commonmark files strict no_layout dodiff html_diff =
  let op = match html_diff, dodiff with
  | true, _ -> `Html_diff | false, true -> `Diff | false, false -> `Render
  in
  let layout = not no_layout in
  let commonmark ~file contents =
    let doc = Cmarkit.Doc.of_string ~file ~layout ~strict contents in
    Cmarkit_commonmark.of_doc doc
  in
  match op with
  | `Render ->
      let output_cmark ~file src = print_string (commonmark ~file src) in
      Std.process_files output_cmark files
  | `Diff ->
      let trips = ref [] in
      let add ~file src = trips := (src, commonmark ~file src) :: !trips in
      let c = Std.process_files add files in
      if c <> 0 then c else
      let src = String.concat "\n" (List.rev_map fst !trips) in
      let outs = String.concat "\n" (List.rev_map snd !trips) in
      (match diff src outs with
      | Ok exit -> if exit = 0 then 0 else Exit.err_diff
      | Error err -> Log.err "%s" err; Cmdliner.Cmd.Exit.some_error)
  | `Html_diff ->
      let htmls = ref [] in
      let add ~file src =
        let doc = Cmarkit.Doc.of_string ~file ~layout ~strict src in
        let doc_html = Cmarkit_html.of_doc ~safe:false doc in
        let md = Cmarkit_commonmark.of_doc doc in
        let doc' = Cmarkit.Doc.of_string ~layout ~strict md in
        let doc_html' = Cmarkit_html.of_doc ~safe:false doc' in
        htmls := (doc_html, doc_html') :: !htmls
      in
      let c = Std.process_files add files in
      if c <> 0 then c else
      let html = String.concat "\n" (List.rev_map fst !htmls) in
      let html' = String.concat "\n" (List.rev_map snd !htmls) in
      match diff html html' with
      | Ok exit -> if exit = 0 then 0 else Exit.err_diff
      | Error err -> Log.err "%s" err; Cmdliner.Cmd.Exit.some_error

(* Command line interface *)

open Cmdliner

let diff =
  let doc = "Output difference between the source and its CommonMark \
             rendering (needs $(b,git) in your $(b,PATH)). If there are \
             differences check that the HTML renderings do not differ with \
             option $(b,--html-diff)."
  in
  Arg.(value & flag & info ["diff"] ~doc)

let html_diff =
  let doc = "Output difference between the source HTML rendering \
             and the HTML rendering of its CommonMark rendering \
             (needs $(b,git) in your $(b,PATH)). If there are no \
             differences the CommonMark rendering is said to be correct."
  in
  Arg.(value & flag & info ["html-diff"] ~doc)

let v =
  let doc = "Render CommonMark to CommonMark" in
  let exits = Exit.exits_with_err_diff in
  let man = [
    `S Manpage.s_description;
    `P "$(tname) outputs a CommonMark document. Multiple input
        files are concatenated and separated by a newline.";
    `Pre "$(mname) $(tname) $(b,README.md > README-trip.md)"; `Noblank;
    `Pre "$(mname) $(tname) $(b,--diff README.md)"; `Noblank;
    `Pre "$(mname) $(tname) $(b,--html-diff README.md)";
    `P "Layout is preserved on a best-effort basis. Some things are not \
        attempted like preserving entities and character references, \
        preserving the exact line by line indentation layout of container \
        blocks, preserving lazy continuation lines, preserving the \
        identation of blank lines, keeping track of used newlines \
        except for the first one.";
    `P "Consult the documentation of the $(b,cmarkit) OCaml library for \
        more details about the limitations.";
    `Blocks Cli.common_man; ]
  in
  Cmd.v (Cmd.info "commonmark" ~doc ~exits ~man) @@
  Term.(const commonmark $ Cli.files $ Cli.strict $ Cli.no_layout $
        diff $ html_diff)
