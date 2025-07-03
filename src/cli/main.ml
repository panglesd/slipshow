open Cmdliner

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  ()

let setup_log =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let handle_error = function Ok _ as x -> x | Error (`Msg msg) -> Error msg

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

  let dimension =
    let int_parser = Cmdliner.Arg.(conv_parser int) in
    let int_printer = Cmdliner.Arg.(conv_printer int) in
    let ( let* ) = Result.bind in
    let parser_ s =
      match String.split_on_char 'x' s with
      | [ "4:3" ] -> Ok (1440, 1080)
      | [ "16:9" ] -> Ok (1920, 1080)
      | [ width; height ] ->
          let* width = int_parser width in
          let* height = int_parser height in
          Ok (width, height)
      | _ ->
          Error
            (`Msg
               "Expected \"4:3\", \"16:9\", or two integers separated by a 'x'")
    in
    let printer fmt (w, h) =
      Format.fprintf fmt "%ax%a" int_printer w int_printer h
    in
    Cmdliner.Arg.conv ~docv:"WIDTHxHEIGHT" (parser_, printer)
end

module Compile_args = struct
  let css_links =
    let doc =
      "CSS files to add to the presentation. Can be a local file or a remote \
       URL"
    in
    Arg.(value & opt_all string [] & info ~docv:"URL" ~doc [ "css" ])

  let theme =
    let doc =
      "Slipshow theme to use in the presentation. Can be \"default\" for the \
       default theme, \"none\" for no theme, a local file or a remote URL."
    in
    Arg.(value & opt (some string) None & info ~docv:"URL" ~doc [ "theme" ])

  let math_link =
    let doc =
      "Where to find the mathjax javascript file. Optional. When absent, use \
       mathjax.3.2.2 embedded in this binary. If URL is an absolute URL, links \
       to it, otherwise the content is embedded in the html file."
    in
    Arg.(
      value & opt (some string) None & info ~docv:"URL" ~doc [ "m"; "mathjax" ])

  let dim =
    let doc =
      "The fixed dimension (in pixels) for your presentation. Can be either \
       WIDTHxHEIGHT where both are integers, or 4:3 (which corresponds to \
       1440x1080), or 16:9 (which corresponds to 1920x1080)"
    in
    Arg.(
      value
      & opt (some Conv.dimension) None
      & info ~docv:"WIDTHxHEIGHT" ~doc [ "d"; "dimension"; "dim" ])

  let output =
    let doc =
      "Output file path. When absent, generate a filename based on the input \
       name. Use - for stdout."
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

  type compile_args = {
    math_link : string option;
    theme : string option;
    css_links : string list;
    input : [ `File of Fpath.t | `Stdin ];
    output : [ `File of Fpath.t | `Stdout ] option;
    dimension : (int * int) option;
  }

  let term =
    let open Term.Syntax in
    let+ math_link = math_link
    and+ theme = theme
    and+ css_links = css_links
    and+ input = input
    and+ output = output
    and+ dimension = dim in
    { math_link; theme; css_links; input; output; dimension }
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

  let compile ~watch
      ~compile_args:
        { Compile_args.input; output; math_link; theme; css_links; dimension } =
    let output =
      match output with Some o -> o | None -> output_of_input input
    in
    if watch then
      let* input, output = force_file_io input output in
      Run.watch ~dimension ~input ~output ~math_link ~theme ~css_links
      |> handle_error
    else
      Run.compile ~input ~output ~math_link ~theme ~css_links ~dimension
      |> Result.map ignore |> handle_error

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
    let info = Cmd.info "compile" ~version:"%%VERSION%%" ~doc ~man in
    Cmd.v info term
end

module Serve = struct
  let ( let* ) = Result.bind

  let serve
      ~compile_args:
        { Compile_args.input; output; math_link; theme; css_links; dimension } =
    let output =
      match output with Some o -> o | None -> Compile.output_of_input input
    in
    let* input, output = Compile.force_file_io input output in
    Run.serve ~dimension ~input ~output ~math_link ~theme ~css_links
    |> handle_error

  let term =
    let open Term.Syntax in
    let+ compile_args = Compile_args.term and+ () = setup_log in
    serve ~compile_args

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
    let info = Cmd.info "markdown" ~version:"%%VERSION%%" ~doc ~man in
    Cmd.v info term
end

module Theme = struct
  let term_all =
    let open Term.Syntax in
    let+ () = Term.const () in
    Themes.all
    |> List.iter (fun t ->
           Format.printf "%s\n  %s\n" (Themes.to_string t)
             (Themes.description t));
    Ok ()

  let all =
    let doc = "List all builtin themes. Default command." in
    let man = [] in
    let info = Cmd.info "list" ~version:"%%VERSION%%" ~doc ~man in
    Cmd.v info term_all

  let cmd =
    let doc = "Manages themes for slipshow presentations" in
    let man = [] in
    let info = Cmd.info "themes" ~version:"%%VERSION%%" ~doc ~man in
    Cmd.group ~default:term_all info [ all ]
end

let group =
  let doc = "A tool to compile and preview slipshow presentation" in
  let man = [] in
  let info = Cmd.info "slipshow" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.group info [ Compile.cmd; Serve.cmd; Markdownify.cmd; Theme.cmd ]

let main () = exit (Cmd.eval_result group)
let () = main ()
