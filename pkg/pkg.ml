#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let () =
  Pkg.describe "brr" @@ fun c ->
  Ok [ Pkg.mllib "src/brr.mllib";
       Pkg.mllib "src/ocaml_poke/brr_ocaml_poke.mllib" ~dst_dir:"ocaml_poke/";
       Pkg.mllib "src/ocaml_poke_ui/brr_ocaml_poke_ui.mllib"
         ~dst_dir:"ocaml_poke_ui/";
       Pkg.mllib "src/poke/brr_poke.mllib" ~dst_dir:"poke/";
       Pkg.mllib "src/poked/brr_poked.mllib" ~dst_dir:"poked/";
       Pkg.share "src/console/devtools.html" ~dst:"console/";
       Pkg.share "src/console/devtools.js" ~dst:"console/";
       Pkg.share "src/console/highlight.pack.js" ~dst:"console/";
       Pkg.share "src/console/manifest.json" ~dst:"console/";
       Pkg.share "src/console/ocaml.png" ~dst:"console/";
       Pkg.share "src/console/ocaml_console.css" ~dst:"console/";
       Pkg.share "src/console/ocaml_console.html" ~dst:"console/";
       Pkg.share "src/console/ocaml_console.js" ~dst:"console/";

       (* Samples *)
       Pkg.doc "test/poke.ml";

       (* Doc *)
       Pkg.doc "doc/index.mld" ~dst:"odoc-pages/index.mld";
       Pkg.doc "doc/ffi_manual.mld" ~dst:"odoc-pages/ffi_manual.mld";
       Pkg.doc "doc/ffi_cookbook.mld" ~dst:"odoc-pages/ffi_cookbook.mld";
       Pkg.doc "doc/ocaml_console.mld" ~dst:"odoc-pages/ocaml_console.mld";
       Pkg.doc "doc/web_page_howto.mld" ~dst:"odoc-pages/web_page_howto.mld";
       Pkg.doc ~built:false "doc/ocaml_console.png" ~dst:"odoc-assets/";
     ]
