open Ocamlbuild_plugin

let jsoo () =
  let dep = "%.byte" in
  let prod = "%.js" in
  let f env _ =
    let dep = env dep in
    let prod = env prod in
    let tags = tags_of_pathname prod ++ "js_of_ocaml" in
    Cmd
      (S [ A "js_of_ocaml" ; T tags ; A "-o" ; Px prod; P dep])
  in
  rule "js_of_ocaml: .byte -> .js" ~dep ~prod f;
  flag [ "js_of_ocaml"; "debug" ]
    (S [ A "--pretty"; A "--debug-info"; A "--source-map" ]);
  flag [ "js_of_ocaml"; "pretty" ] (A "--pretty");
  flag [ "js_of_ocaml"; "debuginfo" ] (A "--debug-info");
  flag [ "js_of_ocaml"; "noinline" ] (A "--no-inline");
  flag [ "js_of_ocaml"; "sourcemap" ] (A "--source-map");
  pflag [ "js_of_ocaml" ] "opt" (fun n -> S [ A "--opt"; A n ]);
  pflag [ "js_of_ocaml" ] "set" (fun n -> S [ A "--set"; A n ])

let () = Ocamlbuild_plugin.dispatch @@ function
| After_rules ->
    jsoo ();
| _ -> ()
