open Cmdliner

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  ()

let setup_log =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let compile =
  let compile input output math_link slip_css_link slipshow_js_link watch serve
      markdown_mode () =
    let input = match input with "-" -> `Stdin | s -> `File (Fpath.v s) in
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
    match
      Compile.compile ~input ~output ~math_link ~slip_css_link ~slipshow_js_link
        ~watch ~serve ~markdown_mode
    with
    | Ok () -> Ok ()
    | Error (`Msg s) -> Error s
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
  let slip_css_link =
    let doc =
      "Where to find the slipshow css file. Optional. When absent, use \
       slipshow.%%VERSION%%, embedded in this binary. If URL is an absolute \
       URL, links to it, otherwise the content is embedded in the html file."
    in
    Arg.(value & opt (some string) None & info ~docv:"URL" ~doc [ "slip-css" ])
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
    let doc = "Watch" in
    Arg.(value & flag & info [ "watch" ] ~doc ~docv:"")
  in
  let serve =
    let doc = "Serve" in
    Arg.(value & flag & info [ "serve" ] ~doc ~docv:"")
  in
  Term.(
    const compile $ input $ output $ math_link $ slip_css_link
    $ slipshow_js_link $ watch $ serve $ markdown_output $ setup_log)

let compile_cmd =
  let doc = "Compile a markdown file into a slipshow presentation" in
  let man = [] in
  let info = Cmd.info "compile" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.v info compile

let cmd = compile_cmd
(* Currently, it seems to not possible to have positioned arguments for a default group command. *)
(* let doc = "Compile a markdown file into a slipshow presentation" in *)
(* let man = [] in *)
(* let info = Cmd.info "slip_of_mark" ~version:"%%VERSION%%" ~doc ~man in *)
(* Cmd.group ~default:compile info [ compile_cmd ] *)

let main () = exit (Cmd.eval_result cmd)
let () = main ()
