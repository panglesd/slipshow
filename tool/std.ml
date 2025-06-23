(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

type fpath = string

module Result = struct
  include Result
  let to_failure = function Ok v -> v | Error err -> failwith err
  module Syntax = struct
    let ( let* ) = Result.bind
  end
end

module Log = struct
  let exec = Filename.basename Sys.executable_name

  let err fmt =
    Format.fprintf Format.err_formatter ("%s: @[" ^^ fmt ^^ "@]@.") exec

  let warn fmt =
    Format.fprintf Format.err_formatter ("@[" ^^ fmt ^^ "@]@.")

  let on_error ~use r f = match r with
  | Ok v -> f v | Error e -> err "%s" e; use
end

module Label_resolver = struct
  (* A label resolver that warns on redefinitions *)

  let warn_label_redefinition ~current ~prev =
    let open Cmarkit in
    let pp_loc = Textloc.pp_ocaml in
    let current_text = Label.text_to_string current in
    let current = Meta.textloc (Label.meta current) in
    let prev = Meta.textloc (Label.meta prev) in
    if Textloc.is_none current then
      Log.warn "Warning: @[<v>Ignoring redefinition of label %S.@,\
                Invoke with option --locs to get file locations.@,@]"
        current_text
    else
    Log.warn "@[<v>%a:@,Warning: \
              @[<v>Ignoring redefinition of label %S. \
              Previous definition:@,%a@]@,@]"
      pp_loc current current_text pp_loc prev

  let v ~quiet = function
  | `Ref (_, _, ref) -> ref
  | `Def (None, current) -> Some current
  | `Def (Some prev, current) ->
      if not quiet then warn_label_redefinition ~current ~prev; None
end

module Os = struct

  (* Emulate B0_std.Os functionality to eschew the dep *)

  let read_file file =
    try
      let ic = if file = "-" then stdin else open_in_bin file in
      let finally () = if file = "-" then () else close_in_noerr ic in
      Fun.protect ~finally @@ fun () -> Ok (In_channel.input_all ic)
    with
    | Sys_error err -> Error err

  let write_file file s =
    try
      let oc = if file = "-" then stdout else open_out_bin file in
      let finally () = if file = "-" then () else close_out_noerr oc in
      Fun.protect ~finally @@ fun () -> Ok (Out_channel.output_string oc s)
    with
    | Sys_error err -> Error err

  let with_tmp_dir f =
    try
      let tmpdir =
        let file = Filename.temp_file "cmarkit" "dir" in
        (Sys.remove file; Sys.mkdir file 0o700; file)
      in
      let finally () = try Sys.rmdir tmpdir with Sys_error _ -> () in
      Fun.protect ~finally @@ fun () -> Ok (f tmpdir)
    with
    | Sys_error err -> Error ("Making temporary dir: " ^ err)

  let with_cwd cwd f =
    try
      let curr = Sys.getcwd () in
      let () = Sys.chdir cwd in
      let finally () = try Sys.chdir curr with Sys_error _ -> () in
      Fun.protect ~finally @@ fun () -> Ok (f ())
    with
    | Sys_error err -> Error ("With cwd: " ^ err)
end

module Exit = struct
  open Cmdliner

  type code = Cmdliner.Cmd.Exit.code
  let err_file = 1
  let err_diff = 2

  let exits =
    Cmd.Exit.info err_file ~doc:"on file read errors." ::
    Cmd.Exit.defaults

  let exits_with_err_diff =
    Cmd.Exit.info err_diff ~doc:"on render differences." :: exits
end

let process_files f files =
  let rec loop = function
  | [] -> 0
  | file :: files ->
      Log.on_error ~use:Exit.err_file (Os.read_file file) @@ fun content ->
      f ~file content; loop files
  in
  loop files

module Cli = struct
  open Cmdliner

  let accumulate_defs =
    let doc =
      "Accumulate label definitions from one input file to the other \
       (in left to right command line order). Link reference definitions and \
       footnote definitions of previous files can be used and override \
       those made in subsequent ones."
    in
    Arg.(value & flag & info ["D"; "accumulate-defs"] ~doc)

  let backend_blocks ~doc =
    Arg.(value & flag & info ["b"; "backend-blocks"] ~doc)

  let docu =
    let doc = "Output a complete document rather than a fragment." in
    Arg.(value & flag & info ["c"; "doc"] ~doc)

  let files =
    let doc = "$(docv) is the CommonMark file to process (repeatable). Reads \
               from $(b,stdin) if none or $(b,-) is specified." in
    Arg.(value & pos_all string ["-"] & info [] ~doc ~docv:"FILE.md")

  let heading_auto_ids =
    let doc = "Automatically generate heading identifiers." in
    Arg.(value & flag & info ["h"; "heading-auto-ids"] ~doc)

  let lang =
    let doc = "Language (BCP47) of the document when $(b,--doc) is used." in
    let docv = "LANG" in
    Arg.(value & opt string "en" & info ["l"; "lang"] ~doc ~docv)

  let no_layout =
    let doc = "Drop layout information during parsing." in
    Arg.(value & flag & info ["no-layout"] ~doc)

  let quiet =
    let doc = "Be quiet. Do not report label redefinition warnings." in
    Arg.(value & flag & info ["q"; "quiet"] ~doc)

  let safe =
    let safe =
      let doc = "Drop raw HTML and dangerous URLs (default). If \
                 you are serious about XSS prevention, better pipe \
                 the output to a dedicated HTML sanitizer."
      in
      Arg.info ["safe"] ~doc
    in
    let unsafe =
      let doc = "Keep raw HTML and dangerous URLs. See option $(b,--safe)." in
      Arg.info ["u"; "unsafe"] ~doc
    in
    Arg.(value & vflag true [true, safe; false, unsafe])

  let strict =
    let extended =
      let doc = "Activate supported extensions: strikethrough ($(b,~~)), \
                 LaTeX math ($(b,\\$), $(b,\\$\\$) and $(b,math) code blocks), \
                 footnotes ($(b,[^id])), task items \
                 ($(b,[ ]), $(b,[x]), $(b,[~])) and pipe tables. \
                 See the library documentation for more information."
      in
      Arg.(value & flag & info ["e"; "exts"] ~doc)
    in
    Term.app (Term.const Bool.not) extended

  let title =
    let doc = "Title of the document when $(b,--doc) is used. Derived from \
               the filename of the first input file if unspecified."
    in
    let docv = "TITLE" in
    Arg.(value & opt (some string) None & info ["t"; "title"] ~doc ~docv)

  let common_man =
    [ `S Manpage.s_bugs;
      `P "This program is distributed with the $(b,cmarkit) OCaml library. \
          See $(i,https://erratique.ch/software/cmarkit) for contact \
          information.";
      `S Manpage.s_see_also;
      `P "More information about the renderers can be found in the \
          documentation of the $(b,cmarkit) OCaml library. Consult \
          $(b,odig doc cmarkit) or the online documentation." ]
end
