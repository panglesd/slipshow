open Cmdliner

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  ()

let setup_log =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

module Conv = struct
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

module Common_args = struct
  let math_link =
    let doc =
      "Where to find the mathjax javascript file. Optional. When absent, use \
       mathjax.3.2.2 embedded in this binary. If URL is an absolute URL, links \
       to it, otherwise the content is embedded in the html file."
    in
    Arg.(
      value & opt (some string) None & info ~docv:"URL" ~doc [ "m"; "mathjax" ])

  let output =
    let doc =
      "Output file path. When absent, generate a filename based on the input \
       name."
    in
    Arg.(
      value
      & opt (some Conv.output) None
      & info ~docv:"PATH" ~doc [ "o"; "output" ])

  let input =
    let doc =
      "$(docv) is the CommonMark file to process. Reads from $(b,stdin) if \
       $(b,-) is specified."
    in

    Arg.(value & pos 0 Conv.input `Stdin & info [] ~doc ~docv:"FILE.md")
end

module Compile = struct
  let watch =
    let doc = "Watch the input file, and recompile when changes happen." in
    Arg.(value & flag & info ~docv:"" ~doc [ "watch" ])

  let ( let* ) = Result.bind

  let output_of_input = function
    | `File input -> `File (Fpath.set_ext "html" input)
    | `Stdin -> `Stdout

  let force_file_io input output =
    let* input =
      match input with
      | `File input -> Ok input
      | `Stdin -> Error "Standard input cannot be used in serve nor watch mode"
    in
    match output with
    | `File o -> Ok (input, o)
    | `Stdout -> Error "Standard output cannot be used in serve nor watch mode"

  let compile ~watch ~input ~output ~math_link =
    let output =
      match output with Some o -> o | None -> output_of_input input
    in
    if watch then
      let* input, output = force_file_io input output in
      Run.watch ~input ~output ~math_link
      |> Result.map_error @@ fun (`Msg s) -> s
    else
      Run.compile ~input ~output ~math_link
      |> Result.map_error @@ fun (`Msg s) -> s

  let term =
    let open Common_args in
    let open Term.Syntax in
    let+ input = input
    and+ output = output
    and+ math_link = math_link
    and+ watch = watch
    and+ () = setup_log in
    compile ~input ~output ~math_link ~watch

  let cmd =
    let doc =
      "Compile a slipshow source file into a slipshow html presentation"
    in
    let man = [] in
    let info = Cmd.info "compile" ~version:"%%VERSION%%" ~doc ~man in
    Cmd.v info term
end

module Serve = struct
  let ( let* ) = Result.bind

  let serve ~input ~output ~math_link =
    let output =
      match output with Some o -> o | None -> Compile.output_of_input input
    in
    let* input, output = Compile.force_file_io input output in
    match Run.serve ~input ~output ~math_link with
    | Ok () -> Ok ()
    | Error (`Msg s) -> Error s

  let term =
    let open Common_args in
    let open Term.Syntax in
    let+ input = input
    and+ output = output
    and+ math_link = math_link
    and+ () = setup_log in
    serve ~input ~output ~math_link

  let cmd =
    let doc =
      "Serve a live preview of a slipshow presentation, with hot-reloading"
    in
    let man = [] in
    let info = Cmd.info "serve" ~version:"%%VERSION%%" ~doc ~man in
    Cmd.v info term
end

module Markdownify = struct
  let do_ ~input ~output =
    let output_of_input = function
      | `File input -> `File (Fpath.set_ext "noattrs.md" input)
      | `Stdin -> `Stdout
    in
    let output =
      match output with Some o -> o | None -> output_of_input input
    in
    match Run.markdown_compile ~input ~output with
    | Ok () -> Ok ()
    | Error (`Msg s) -> Error s

  let term =
    let open Common_args in
    let open Term.Syntax in
    let+ input = input and+ output = output and+ () = setup_log in
    do_ ~input ~output

  let cmd =
    let doc =
      "Compile a slipshow source into a pure Markdown file, effectively \
       removing presentation attributes"
    in
    let man = [] in
    let info = Cmd.info "markdown" ~version:"%%VERSION%%" ~doc ~man in
    Cmd.v info term
end

let group =
  let doc = "A tool to compile and preview slipshow presentation" in
  let man = [] in
  let info = Cmd.info "slipshow" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.group info [ Compile.cmd; Serve.cmd; Markdownify.cmd ]

let main () = exit (Cmd.eval_result group)
let () = main ()
