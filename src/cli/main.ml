open Cmdliner

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  ()

let setup_log =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let handle_error = function Ok _ as x -> x | Error (`Msg msg) -> Error msg

let compile =
  let compile input output math_link css_links theme slipshow_js_link watch
      serve markdown_mode () =
    let input = match input with "-" -> `Stdin | s -> `File (Fpath.v s) in
    let theme =
      match theme with
      | None | Some "default" -> `Default
      | Some "none" -> `None
      | Some s -> `Other s
    in
    let output_of_input input =
      match (input, markdown_mode) with
      | `File input, false -> `File (Fpath.set_ext "html" input)
      | `File input, true -> `File (Fpath.set_ext "noattrs.md" input)
      | `Stdin, _ -> `Stdout
    in
    let output =
      match output with
      | Some "-" -> `Stdout
      | Some output -> `File (Fpath.v output)
      | None -> output_of_input input
    in
    Run.go ~input ~output ~math_link ~css_links ~slipshow_js_link ~theme ~watch
      ~serve ~markdown_mode
  in
  let math_link =
    let doc =
      "Where to find the mathjax javascript file. Optional. When absent, use \
       mathjax.3.2.2 embedded in this binary. If URL is an absolute URL, links \
       to it, otherwise the content is embedded in the html file."
    in
    Arg.(
      value & opt (some string) None & info ~docv:"URL" ~doc [ "m"; "mathjax" ])
  in
  let slipshow_js_link =
    let doc =
      "Where to find the slipshow javascript file. Optional. When absent, use \
       slipshow.%%VERSION%%, embedded in this binary. If URL is an absolute \
       URL, links to it, otherwise the content is embedded in the html file."
    in
    Arg.(value & opt (some string) None & info ~docv:"URL" ~doc [ "slipshow" ])
  in
  let theme =
    let doc =
      "Slipshow theme to use in the presentation. Can be \"default\" for the \
       default theme, \"none\" for no theme, a local file or a remote URL."
    in
    Arg.(value & opt (some string) None & info ~docv:"URL" ~doc [ "theme" ])
  in
  let slip_css_links =
    let doc =
      "CSS files to add to the presentation. Can be a local file or a remote \
       URL"
    in
    Arg.(value & opt_all string [] & info ~docv:"URL" ~doc [ "css" ])
  in
  let output =
    let doc =
      "Output file path. When absent, generate a filename based on the input \
       name."
    in
    Arg.(
      value & opt (some string) None & info ~docv:"PATH" ~doc [ "o"; "output" ])
  in
  let input =
    let doc =
      "$(docv) is the CommonMark file to process. Reads from $(b,stdin) if \
       $(b,-) is specified."
    in
    Arg.(value & pos 0 string "-" & info [] ~doc ~docv:"FILE.md")
  in
  let markdown_output =
    let doc =
      "Outputs a markdown file with valid (GFM) syntax, by stripping the \
       attributes. Useful for printing for instance."
    in
    Arg.(value & flag & info [ "markdown-output" ] ~doc ~docv:"FILE.md")
  in
  let watch =
    let doc = "Watch the input for changes, and recompile on edits." in
    Arg.(value & flag & info [ "watch" ] ~doc ~docv:"")
  in
  let serve =
    let doc = "Serve the compiled file on a preview server." in
    Arg.(value & flag & info [ "serve" ] ~doc ~docv:"")
  in
  Term.(
    const handle_error
    $ (const compile $ input $ output $ math_link $ slip_css_links $ theme
     $ slipshow_js_link $ watch $ serve $ markdown_output $ setup_log))

let compile_cmd =
  let doc = "Compile a markdown file into a slipshow presentation" in
  let man = [] in
  let info = Cmd.info "compile" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.v info compile

(* Currently, it seems to not possible to have positioned arguments for a default group command.
   Would have been good!

   let doc = "Compile a markdown file into a slipshow presentation" in
   let man = [] in
   let info = Cmd.info "slip_of_mark" ~version:"%%VERSION%%" ~doc ~man in
   Cmd.group ~default:compile info [ compile_cmd ] *)
let cmd = compile_cmd
let main () = exit (Cmd.eval_result cmd)
let () = main ()
