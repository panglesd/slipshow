(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Std
open Cmdliner

let cmds = [ Cmd_commonmark.v; Cmd_html.v; Cmd_latex.v; Cmd_locs.v; ]

let cmarkit =
  let doc = "Process CommonMark files" in
  let exits = Exit.exits_with_err_diff in
  let man = [
    `S Manpage.s_description;
    `P "$(mname) processes CommonMark files";
    `Blocks Cli.common_man; ]
  in
  Cmd.group (Cmd.info "cmarkit" ~version:"%%VERSION%%" ~doc ~exits ~man) @@
  cmds

let main () = exit (Cmd.eval' cmarkit)
let () = if !Sys.interactive then () else main ()
