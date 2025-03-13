open B0_kit.V000

(* OCaml library names *)

let js_of_ocaml_toplevel = B0_ocaml.libname "js_of_ocaml-toplevel"
let js_of_ocaml_compiler_runtime =
  B0_ocaml.libname "js_of_ocaml-compiler.runtime"

let brr = B0_ocaml.libname "brr"
let brr_ocaml_poke = B0_ocaml.libname "brr.ocaml_poke"
let brr_ocaml_poke_ui = B0_ocaml.libname "brr.ocaml_poke_ui"
let brr_poke = B0_ocaml.libname "brr.poke"
let brr_poked = B0_ocaml.libname "brr.poked"

(* Units *)

let brr_lib =
  let srcs = [`Dir ~/"src"] in
  let requires = [js_of_ocaml_compiler_runtime] in
  B0_ocaml.lib brr ~srcs ~requires ~doc:"Brr JavaScript FFI and browser API"

let brr_ocaml_poke_lib =
  let doc = "OCaml poke objects interaction" in
  let srcs = [`Dir ~/"src/ocaml_poke"] in
  let requires = [brr] in
  B0_ocaml.lib brr_ocaml_poke ~srcs ~requires ~doc

let brr_ocaml_poke_ui_lib =
  let doc = "OCaml poke user interface (toplevel)" in
  let srcs = [`Dir ~/"src/ocaml_poke_ui"] in
  let requires = [brr; brr_ocaml_poke] in
  B0_ocaml.lib brr_ocaml_poke_ui ~srcs ~requires ~doc

let brr_poke_lib =
  let srcs = [`Dir ~/"src/poke"] in
  let requires = [js_of_ocaml_compiler_runtime; js_of_ocaml_toplevel; brr] in
  B0_ocaml.lib brr_poke ~srcs ~requires ~doc:"Poke explicitely"

let brr_poked_lib =
  let srcs = [`Dir ~/"src/poked"] in
  let requires = [brr_poke] in
  B0_ocaml.lib brr_poked ~srcs ~requires ~doc:"Poke by side effect"

(* Web extension *)

let console =
  let doc = "Browser developer tool OCaml console" in
  let srcs =
    [ `Dir ~/"src/console";
      (* TODO b0: we want something like ext_js *)
      `X ~/"src/console/ocaml_console.js"; (* GNGNGNGN *)
      `X ~/"src/console/devtools.js";
      `X ~/"src/console/highlight.pack.js" ]
  in
  let requires = [brr; brr_ocaml_poke; brr_ocaml_poke_ui] in
  let meta =
    B0_meta.empty
    |> ~~ B0_jsoo.compilation_mode `Whole
    |> ~~ B0_jsoo.source_map (Some `Inline)
    |> ~~ B0_jsoo.compile_opts (Cmd.arg "--pretty")
  in
  B0_jsoo.html_page "ocaml_console" ~requires ~srcs ~meta ~doc

let test_poke =
  let doc = "OCaml console test" in
  let srcs = [`File ~/"test/poke.ml"; `File ~/"test/base.css"] in
  let requires = [brr; brr_poked] in
  let meta = B0_meta.empty |> B0_meta.tag B0_jsoo.toplevel in
  B0_jsoo.html_page "test_poke" ~requires ~srcs ~meta ~doc

let top =
  let doc = "In page toplevel test" in
  let srcs = [
    `File ~/"test/top.ml";
    (* TODO js_of_ocaml chokes `File "src/console/highlight.pack.js";
       TODO it's likely fixed by now. *)
    `File ~/"src/console/ocaml_console.css" ] in
  let requires =
    [ js_of_ocaml_compiler_runtime;
      brr; brr_ocaml_poke_ui; brr_poke; brr_ocaml_poke]
  in
  let meta =
    B0_meta.empty
    |> ~~ B0_jsoo.compilation_mode `Whole
    |> B0_meta.tag B0_jsoo.toplevel
  in
  B0_jsoo.html_page "top" ~requires ~doc ~srcs ~meta

(* Tests and samples *)

let base_css = `File ~/"test/base.css"

let test ?(meta = B0_meta.empty) ?doc ?(requires = []) ?(srcs = []) src =
  let srcs = `File src :: base_css :: srcs in
  let requires = brr :: requires in
  let name = Fpath.basename ~strip_ext:true src in
  let meta =
    meta |> B0_meta.(tag test) |> ~~ B0_jsoo.compile_opts Cmd.(arg "--pretty")
  in
  B0_jsoo.html_page name ~requires ~srcs ~meta ?doc

let test_module ?meta ?doc ?requires ?srcs top m =
  let name = Fmt.str "test_%s" (String.Ascii.uncapitalize m) in
  let doc = Fmt.str "Test %s.%s module" top m in
  let src = Fpath.fmt "test/%s.ml" name in
  test ?meta ?requires ?srcs src ~doc

let test_hello = test ~/"test/test_hello.ml" ~doc:"Brr console hello size"
let test_fact =
  test ~/"test/test_fact.ml" ~doc:"Test export OCaml to JavaScript"

let test_base64 = test_module "Brr" "Base64"
let test_c2d = test_module "Brr_canvas" "C2d"
let test_clipboard = test_module "Brr_io" "Clipboard"
let test_console = test_module "Brr" "Console"
let test_file = test_module "Brr" "File"
let test_geo = test_module "Brr_io" "Geolocation"
let test_gl = test_module "Brr_canvas" "Gl"
let test_history = test_module "Brr" "History"
let test_media = test_module "Brr_io" "Media"
let test_notif = test_module "Brr_io" "Notification"
let test_webaudio = test_module "Brr_webaudio" "Audio"
let test_webcrypto = test_module "Brr_webcrypto" "Crypto"
let test_webmidi = test_module "Brr_webmidi" "Midi"
let test_webgpu = test_module "Brr_webgpu" "Gpu"
let test_worker = test_module "Brr" "Worker"

let min =
  let srcs = [ `File ~/"test/min.ml"; `File ~/"test/min.html" ] in
  let requires = [brr] in
  B0_jsoo.html_page "min" ~requires ~srcs ~doc:"Brr minimal web page"

let nop =
  let srcs = [ `File ~/"test/nop.ml" ] in
  B0_jsoo.html_page "nop" ~srcs ~doc:"js_of_ocaml nop web page"

(* Actions *)

let update_console =
  let doc = "Update dev console" in
  B0_unit.of_action ~units:[console] ~doc "update-console" @@ fun env _ ~args ->
  let jsfile = "ocaml_console.js" in
  let src = B0_env.in_unit_dir env console ~/jsfile in
  let dst = B0_env.in_scope_dir env Fpath.(~/"src/console" / jsfile) in
  Os.File.copy ~force:true ~make_path:false src ~dst

(* Packs *)

let test_pack =
  let us = [ test_console ] in
  let meta = B0_meta.empty |> B0_meta.tag B0_meta.test in
  B0_pack.make ~locked:false "test" ~doc:"Brr test suite" ~meta us

let is_toplevel u = B0_unit.has_tag B0_jsoo.toplevel u

let jsoo_toplevels =
  let us = List.filter is_toplevel (B0_unit.list ()) in
  let doc = "Units with toplevel (slow to build)" in
  B0_pack.make ~locked:false "tops" ~doc us

let default =
  let meta =
    B0_meta.empty
    |> ~~ B0_meta.authors ["The brr programmers"]
    |> ~~ B0_meta.maintainers ["Daniel Bünzli <daniel.buenzl i@erratique.ch>"]
    |> ~~ B0_meta.homepage "https://erratique.ch/software/brr"
    |> ~~ B0_meta.online_doc "https://erratique.ch/software/brr/doc/"
    |> ~~ B0_meta.licenses ["ISC"; "BSD-3-Clause"]
    |> ~~ B0_meta.repo "git+https://erratique.ch/repos/brr.git"
    |> ~~ B0_meta.issues "https://github.com/dbuenzli/brr/issues"
    |> ~~ B0_meta.description_tags
      [ "reactive"; "declarative"; "frp"; "front-end"; "browser";
        "org:erratique"]
    |> ~~ B0_opam.build
      {|[["ocaml" "pkg/pkg.ml" "build" "--dev-pkg" "%{dev}%"]]|}
    |> ~~ B0_opam.depends
      [ "ocaml", {|>= "4.08.0"|};
        "ocamlfind", {|build|};
        "ocamlbuild", {|build|};
        "topkg", {|build & >= "1.0.3"|};
        "js_of_ocaml-compiler", {|>= "5.5.0"|};
        "js_of_ocaml-toplevel", {|>= "5.5.0"|} ]
      |> B0_meta.tag B0_opam.tag
  in
  B0_pack.make "default" ~doc:"brr package" ~meta ~locked:true @@
  List.filter (Fun.negate is_toplevel) (B0_unit.list ())
