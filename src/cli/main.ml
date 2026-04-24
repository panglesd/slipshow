open Cmdliner

(* Update this on every release! *)
let version_title = "Don't look {up}"
let slipshow_version = "%%VERSION%%: " ^ version_title

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  ()

let setup_log =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let handle_error = function Ok _ as x -> x | Error (`Msg msg) -> Error msg

module Custom_conv = struct
  let io std =
    let parser_ s =
      match s with "-" -> Ok std | s -> Ok (`File (Fpath.v s))
    in
    let printer fmt = function
      | `File s -> Format.fprintf fmt "%a" Fpath.pp s
      | _ -> Format.fprintf fmt "-"
    in
    Arg.conv (parser_, printer)

  let input = io `Stdin
  let output = io `Stdout
end

module Compile_args = struct
  let output =
    let doc =
      "Output file path. When absent, generate a filename based on the input \
       name. Use - for stdout."
    in
    Arg.(
      value
      & opt (some Custom_conv.output) None
      & info ~docv:"PATH" ~doc [ "o"; "output" ])

  let input =
    let doc =
      "$(docv) is the CommonMark file to process. Reads from $(b,stdin) if \
       $(b,-) is specified."
    in
    Arg.(value & pos 0 Custom_conv.input `Stdin & info [] ~doc ~docv:"FILE.md")

  type compile_args = {
    input : [ `File of Fpath.t | `Stdin ];
    output : [ `File of Fpath.t | `Stdout ] option;
  }

  let term =
    let open Term.Syntax in
    let+ input = input and+ output = output in
    { input; output }
end

module Utils = struct
  let output_of_input ~ext output input =
    let filename_of_input input = Fpath.set_ext ext input in
    match (output, input) with
    | None, `File input -> `File (filename_of_input input)
    | None, `Stdin -> `Stdout
    | Some (`File dir), `File input when Fpath.is_dir_path dir ->
        `File (Fpath.append dir (filename_of_input input))
    | Some f, _ -> f
end

module Compile = struct
  let watch =
    let doc = "Watch the input file, and recompile when changes happen." in
    Arg.(value & flag & info ~docv:"" ~doc [ "watch" ])

  let ( let* ) = Result.bind

  let force_file_io input output =
    let* input =
      match input with
      | `File input -> Ok input
      | `Stdin -> Error "Standard input cannot be used in serve nor watch mode"
    in
    match output with
    | `File o -> Ok (input, o)
    | `Stdout -> Error "Standard output cannot be used in serve nor watch mode"

  let compile ~watch ~compile_args:{ Compile_args.input; output } =
    let output = Utils.output_of_input ~ext:"html" output input in
    if watch then
      let* input, output = force_file_io input output in
      Run.watch ~input ~output |> handle_error
    else Run.compile ~input ~output |> Result.map ignore |> handle_error

  let term =
    let open Term.Syntax in
    let+ watch = watch
    and+ compile_args = Compile_args.term
    and+ () = setup_log in
    compile ~compile_args ~watch

  let cmd =
    let doc =
      "Compile a slipshow source file into a slipshow html presentation"
    in
    let man = [] in
    let info = Cmd.info "compile" ~version:slipshow_version ~doc ~man in
    Cmd.v info term
end

module Serve = struct
  let ( let* ) = Result.bind

  let serve ~port ~compile_args:{ Compile_args.input; output } =
    let output = Utils.output_of_input ~ext:"html" output input in
    let* input, output = Compile.force_file_io input output in
    Run.serve ~input ~output ~port |> handle_error

  let port =
    let doc = "Which port to use." in
    Arg.(value & opt int 8080 & info ~docv:"PORT" ~doc [ "port"; "p" ])

  let term =
    let open Term.Syntax in
    let+ compile_args = Compile_args.term
    and+ () = setup_log
    and+ port = port in
    serve ~port ~compile_args

  let cmd =
    let doc =
      "Serve a live preview of a slipshow presentation, with hot-reloading"
    in
    let man = [] in
    let info = Cmd.info "serve" ~version:slipshow_version ~doc ~man in
    Cmd.v info term
end

module Markdownify = struct
  let do_ ~input ~output =
    let output = Utils.output_of_input ~ext:"noattrs.md" output input in
    Run.markdown_compile ~input ~output |> handle_error

  let term =
    let open Term.Syntax in
    let+ input = Compile_args.input
    and+ output = Compile_args.output
    and+ () = setup_log in
    do_ ~input ~output

  let cmd =
    let doc =
      "Compile a slipshow source into a pure Markdown file, effectively \
       removing presentation attributes"
    in
    let man = [] in
    let info = Cmd.info "markdown" ~version:slipshow_version ~doc ~man in
    Cmd.v info term
end

module Theme = struct
  let term_all =
    let open Term.Syntax in
    let+ () = Term.const () in
    Themes.all
    |> List.iter (fun t ->
        Format.printf "%s\n  %s\n" (Themes.to_string t) (Themes.description t));
    Ok ()

  let all =
    let doc = "List all builtin themes. Default command." in
    let man = [] in
    let info = Cmd.info "list" ~version:slipshow_version ~doc ~man in
    Cmd.v info term_all

  let cmd =
    let doc = "Manages themes for slipshow presentations" in
    let man = [] in
    let info = Cmd.info "themes" ~version:slipshow_version ~doc ~man in
    Cmd.group ~default:term_all info [ all ]
end

let group =
  let doc = "A tool to compile and preview slipshow presentation" in
  let man = [] in
  let info = Cmd.info "slipshow" ~version:slipshow_version ~doc ~man in
  Cmd.group info [ Compile.cmd; Serve.cmd; Markdownify.cmd; Theme.cmd ]

let main () = exit (Cmd.eval_result group)
let () = main ()
