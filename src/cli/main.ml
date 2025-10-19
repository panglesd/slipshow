open Cmdliner

(* Update this on every release! *)
let version_title = "The King's Slipshow"

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  ()

let setup_log =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let handle_error = function Ok _ as x -> x | Error (`Msg msg) -> Error msg

module Custom_conv = struct
  let toplevel_attributes =
    let parser s =
      Slipshow.Frontmatter.String_to.toplevel_attributes s
      |> Result.map @@ fun s -> Some s
    in
    let printer fmt attrs =
      let attrs =
        Option.value ~default:Slipshow.Frontmatter.Default.toplevel_attributes
          attrs
      in
      let doc =
        Cmarkit.Doc.make
          (Cmarkit.Block.Ext_standalone_attributes (attrs, Cmarkit.Meta.none))
      in
      let s =
        let renderer =
          Cmarkit_commonmark.renderer ~include_attributes:true ()
        in
        Cmarkit_renderer.doc_to_string renderer doc
      in
      let s = String.trim s in
      Format.fprintf fmt "%s" s
    in
    Arg.conv (parser, printer)

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

  let theme =
    let parser_ s = Ok (Some (Slipshow.Frontmatter.String_to.theme s)) in
    let rec printer fmt = function
      | Some (`Builtin s) -> Format.fprintf fmt "%s" (Themes.to_string s)
      | Some (`External s) -> Format.fprintf fmt "%s" s
      | None -> printer fmt (Some Slipshow.Frontmatter.Default.theme)
    in
    Arg.conv (parser_, printer)

  let dimension =
    let int_parser = Cmdliner.Arg.(conv_parser int) in
    let int_printer = Cmdliner.Arg.(conv_printer int) in
    let ( let* ) = Result.bind in
    let parser_ s =
      match String.split_on_char 'x' s with
      | [ "4:3" ] -> Ok (Some (1440, 1080))
      | [ "16:9" ] -> Ok (Some (1920, 1080))
      | [ width; height ] ->
          let* width = int_parser width in
          let* height = int_parser height in
          Ok (Some (width, height))
      | _ ->
          Error
            (`Msg
               "Expected \"4:3\", \"16:9\", or two integers separated by a 'x'")
    in
    let rec printer fmt x =
      match x with
      | Some (1440, 1080) -> Format.fprintf fmt "4:3"
      | Some (1920, 1080) -> Format.fprintf fmt "16:9"
      | Some (w, h) -> Format.fprintf fmt "%ax%a" int_printer w int_printer h
      | None -> printer fmt (Some Slipshow.Frontmatter.Default.dimension)
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
    Arg.(value & opt Custom_conv.theme None & info ~docv:"URL" ~doc [ "theme" ])

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
       1440x1080), or 16:9 (which corresponds to 1920x1080)."
    in
    Arg.(
      value
      & opt Custom_conv.dimension None
      & info ~docv:"WIDTHxHEIGHT" ~doc [ "d"; "dimension"; "dim" ])

  let toplevel_attributes =
    let doc =
      "The attributes given to the toplevel element containing all the \
       presentation. Can be enclosed in '{ ... }' or not. Same syntax as \
       attributes in the source file. For experts!"
    in
    Arg.(
      value
      & opt Custom_conv.toplevel_attributes None
      & info ~docv:"ATTRIBUTES" ~doc [ "toplevel-attributes" ])

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
    cli_frontmatter : Slipshow.Frontmatter.unresolved Slipshow.Frontmatter.t;
    input : [ `File of Fpath.t | `Stdin ];
    output : [ `File of Fpath.t | `Stdout ] option;
  }

  let term =
    let open Term.Syntax in
    let+ math_link = math_link
    and+ theme = theme
    and+ css_links = css_links
    and+ input = input
    and+ output = output
    and+ dimension = dim
    and+ toplevel_attributes = toplevel_attributes in
    {
      cli_frontmatter =
        Slipshow.Frontmatter.Unresolved
          { math_link; theme; css_links; dimension; toplevel_attributes };
      input;
      output;
    }
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
      ~compile_args:{ Compile_args.input; output; cli_frontmatter } =
    let output =
      match output with Some o -> o | None -> output_of_input input
    in
    if watch then
      let* input, output = force_file_io input output in
      Run.watch ~cli_frontmatter ~input ~output |> handle_error
    else
      Run.compile ~input ~output ~cli_frontmatter
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
    let info =
      Cmd.info "compile" ~version:("%%VERSION%%: " ^ version_title) ~doc ~man
    in
    Cmd.v info term
end

module Serve = struct
  let ( let* ) = Result.bind

  let serve ~port ~compile_args:{ Compile_args.input; output; cli_frontmatter }
      =
    let output =
      match output with Some o -> o | None -> Compile.output_of_input input
    in
    let* input, output = Compile.force_file_io input output in
    Run.serve ~input ~output ~cli_frontmatter ~port |> handle_error

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
    let info =
      Cmd.info "serve" ~version:("%%VERSION%%: " ^ version_title) ~doc ~man
    in
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
    let info =
      Cmd.info "markdown" ~version:("%%VERSION%%: " ^ version_title) ~doc ~man
    in
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
    let info =
      Cmd.info "list" ~version:("%%VERSION%%: " ^ version_title) ~doc ~man
    in
    Cmd.v info term_all

  let cmd =
    let doc = "Manages themes for slipshow presentations" in
    let man = [] in
    let info =
      Cmd.info "themes" ~version:("%%VERSION%%: " ^ version_title) ~doc ~man
    in
    Cmd.group ~default:term_all info [ all ]
end

let group =
  let doc = "A tool to compile and preview slipshow presentation" in
  let man = [] in
  let info =
    Cmd.info "slipshow" ~version:("%%VERSION%%: " ^ version_title) ~doc ~man
  in
  Cmd.group info [ Compile.cmd; Serve.cmd; Markdownify.cmd; Theme.cmd ]

let main () = exit (Cmd.eval_result group)
let () = main ()
