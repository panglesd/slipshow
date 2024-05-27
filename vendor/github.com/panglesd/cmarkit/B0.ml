open B0_kit.V000
open Result.Syntax

let commonmark_version =
  (* If you update this, also update Cmarkit.commonmark_version
     and the links in src/*.mli *)
  "0.30"

(* OCaml library names *)

let cmarkit = B0_ocaml.libname "cmarkit"
let cmdliner = B0_ocaml.libname "cmdliner"
let uucp = B0_ocaml.libname "uucp"

let b0_std = B0_ocaml.libname "b0.std"
let b0_file = B0_ocaml.libname "b0.file"

(* Libraries *)

let cmarkit_lib =
  let srcs = [ `Dir ~/"src" ] in
  let requires = [] and name = "cmarkit-lib" in
  B0_ocaml.lib cmarkit ~name ~doc:"The cmarkit library" ~srcs ~requires

(* Tools *)

let cmarkit_tool =
  let srcs = [ `Dir ~/"tool" ] in
  let requires = [cmarkit; cmdliner] in
  B0_ocaml.exe "cmarkit" ~public:true ~doc:"The cmarkit tool" ~srcs ~requires

(* Unicode support

   XXX we could do without both an exe and an action, cf. the Unicode libs. *)

let unicode_data =
  let srcs = [ `File ~/"support/unicode_data.ml" ] in
  let requires = [uucp] in
  let doc = "Generate cmarkit Unicode data" in
  B0_ocaml.exe "unicode_data" ~doc ~srcs ~requires

let update_unicode =
  let doc = "Update Unicode character data " in
  B0_action.make' "update_unicode_data" ~units:[unicode_data] ~doc @@
  fun _ env ~args:_ ->
  let* unicode_data = B0_env.unit_cmd env unicode_data in
  let outf = B0_env.in_scope_dir env ~/"src/cmarkit_data_uchar.ml" in
  let outf = Os.Cmd.out_file ~force:true ~make_path:false outf in
  Os.Cmd.run ~stdout:outf unicode_data

(* Tests *)

let update_spec_tests =
  B0_action.make' "update_spec_tests" ~doc:"Update the CommonMark spec tests" @@
  fun _ env ~args:_ ->
  let tests =
    Fmt.str "https://spec.commonmark.org/%s/spec.json" commonmark_version
  in
  let dest = B0_env.in_scope_dir env ~/"test/spec.json" in
  let dest = Os.Cmd.out_file ~force:true ~make_path:false dest in
  let* curl = B0_env.get_cmd env Cmd.(arg "curl" % "-L" % tests) in
  Os.Cmd.run ~stdout:dest curl

let spec_srcs = [`File ~/"test/spec.mli"; `File ~/"test/spec.ml"]

let bench =
  let doc = "Simple standard CommonMark to HTML renderer for benchmarking" in
  let srcs = [ `File ~/"test/bench.ml" ] in
  let requires = [cmarkit] in
  let meta = B0_meta.(empty |> tag bench) in
  B0_ocaml.exe "bench" ~doc ~meta ~srcs ~requires

let test_spec =
  let doc = "Test CommonMark specification conformance tests" in
  let srcs = `File ~/"test/test_spec.ml" :: spec_srcs in
  let requires = [ b0_std; b0_file; cmarkit ] in
  let meta =
    B0_meta.empty
    |> B0_meta.tag B0_meta.test
    |> B0_meta.add B0_unit.exec_cwd `Scope_dir
  in
  B0_ocaml.exe "test_spec" ~doc ~meta ~srcs ~requires

let trip_spec =
  let doc = "Test CommonMark renderer on conformance tests" in
  let srcs = `File ~/"test/trip_spec.ml" :: spec_srcs in
  let requires = [ b0_std; b0_file; cmarkit ] in
  let meta =
    B0_meta.empty
    |> B0_meta.tag B0_meta.test
    |> B0_meta.add B0_unit.exec_cwd `Scope_dir
  in
  B0_ocaml.exe "trip_spec" ~doc ~meta ~srcs ~requires

let pathological =
  let doc = "Test a CommonMark parser on pathological tests." in
  let srcs = [ `File ~/"test/pathological.ml" ] in
  let requires = [ b0_std ] in
  B0_ocaml.exe "pathological" ~doc ~srcs ~requires

let examples =
  let doc = "Doc sample code" in
  let srcs = [ `File ~/"test/examples.ml" ] in
  let requires = [ cmarkit ] in
  let meta = B0_meta.empty |> B0_meta.(tag test) in
  B0_ocaml.exe "examples" ~doc ~meta ~srcs ~requires

(* Expectation tests *)

let expect_trip_spec ctx =
  let trip_spec = (* TODO b0 something more convenient. *)
    B0_env.unit_cmd (B0_expect.env ctx) trip_spec
    |> B0_expect.result_to_abort
  in
  let cwd = B0_env.scope_dir (B0_expect.env ctx) in
  B0_expect.stdout ctx ~cwd ~stdout:(Fpath.v "spec.trip") trip_spec

let expect_cmarkit_renders ctx =
  let cmarkit = (* TODO b0 something more convenient. *)
    B0_env.unit_cmd (B0_expect.env ctx) cmarkit_tool
    |> B0_expect.result_to_abort
  in
  let renderers = (* command, output suffix *)
    [ Cmd.(arg "html" % "-c" % "--unsafe"), ".html";
      Cmd.(arg "latex"), ".latex";
      Cmd.(arg "commonmark"), ".trip.md";
      Cmd.(arg "locs"), ".locs";
      Cmd.(arg "locs" % "--no-layout"), ".nolayout.locs"; ]
  in
  let test_renderer ctx cmarkit file (cmd, ext) =
    let with_exts = Fpath.has_ext ".exts.md" file in
    let cmd = Cmd.(cmd %% if' with_exts (arg "--exts") %% path file) in
    let cwd = B0_expect.base ctx and stdout = Fpath.(file -+ ext) in
    B0_expect.stdout ctx ~cwd ~stdout Cmd.(cmarkit %% cmd)
  in
  let test_file ctx cmarkit file =
    List.iter (test_renderer ctx cmarkit file) renderers
  in
  let test_files =
    let base_files = B0_expect.base_files ctx ~rel:true ~recurse:false in
    let input f = Fpath.has_ext ".md" f && not (Fpath.has_ext ".trip.md" f) in
    List.filter input base_files
  in
  List.iter (test_file ctx cmarkit) test_files

let expect =
  let doc = "Test expectations" in
  B0_action.make "expect" ~units:[trip_spec; cmarkit_tool] ~doc  @@
  B0_expect.action_func ~base:(Fpath.v "test/expect") @@ fun ctx ->
  expect_cmarkit_renders ctx;
  expect_trip_spec ctx;
  ()

(* Packs *)

let default =
  let meta =
    B0_meta.empty
    |> B0_meta.(add authors) ["The cmarkit programmers"]
    |> B0_meta.(add maintainers)
       ["Daniel Bünzli <daniel.buenzl i@erratique.ch>"]
    |> B0_meta.(add homepage) "https://erratique.ch/software/cmarkit"
    |> B0_meta.(add online_doc) "https://erratique.ch/software/cmarkit/doc"
    |> B0_meta.(add licenses) ["ISC"]
    |> B0_meta.(add repo) "git+https://erratique.ch/repos/cmarkit.git"
    |> B0_meta.(add issues) "https://github.com/dbuenzli/cmarkit/issues"
    |> B0_meta.(add description_tags)
      ["codec"; "commonmark"; "markdown"; "org:erratique"; ]
    |> B0_meta.tag B0_opam.tag
    |> B0_meta.add B0_opam.build
      {|[["ocaml" "pkg/pkg.ml" "build" "--dev-pkg" "%{dev}%"
                  "--with-cmdliner" "%{cmdliner:installed}%"]]|}
    |> B0_meta.add B0_opam.depopts ["cmdliner", ""]
    |> B0_meta.add B0_opam.conflicts [ "cmdliner", {|< "1.1.0"|}]
    |> B0_meta.add B0_opam.depends
      [ "ocaml", {|>= "4.14.0"|};
        "ocamlfind", {|build|};
        "ocamlbuild", {|build|};
        "topkg", {|build & >= "1.0.3"|};
        "uucp", {|dev|};
        "b0", {|dev & with-test|};
      ]
  in
  B0_pack.make "default" ~doc:"cmarkit package" ~meta ~locked:true @@
  B0_unit.list ()
