let env_flag name =
  match Sys.getenv_opt name with
  | Some ("1" | "true" | "yes") -> true
  | Some _ | None -> false

(* Homebrew formulae whose shared libraries must not be linked against. This
   mirrors the depexts installed in release/Dockerfile. *)
let homebrew_formulae = [ "libev"; "gmp"; "openssl@3"; "libffi" ]

let homebrew_prefixes =
  match Sys.getenv_opt "HOMEBREW_PREFIX" with
  | Some prefix -> [ prefix ]
  | None -> [ "/opt/homebrew" (* Apple silicon *); "/usr/local" (* Intel *) ]

let is_dylib name = Filename.check_suffix name ".dylib"

let entries dir =
  if Sys.file_exists dir && Sys.is_directory dir then
    Sys.readdir dir |> Array.to_list |> List.filter is_dylib
    |> List.map (Filename.concat dir)
  else []

let delete path =
  match Sys.remove path with
  | () -> prerr_endline ("static_linking_flags: deleted " ^ path)
  | exception Sys_error msg ->
      prerr_endline
        ("static_linking_flags: could not delete " ^ path ^ ": " ^ msg)

let delete_homebrew_dylibs () =
  List.iter
    (fun prefix ->
      (* The libraries themselves, under <prefix>/opt/<formula>/lib. *)
      List.iter
        (fun formula ->
          entries (Filename.concat prefix ("opt/" ^ formula ^ "/lib"))
          |> List.iter delete)
        homebrew_formulae;
      (* <prefix>/lib is a symlink farm pointing into the Cellar. The links we
         have just broken have to go too: ld stops on a dangling symlink rather
         than falling through to the .a. A name that readdir lists but
         Sys.file_exists denies is exactly a broken symlink. *)
      entries (Filename.concat prefix "lib")
      |> List.filter (fun path -> not (Sys.file_exists path))
      |> List.iter delete)
    homebrew_prefixes

let () =
  (* [Sys.argv.(1)] is dune's %{ocaml-config:system}: macosx, linux, mingw64… *)
  let system = Sys.argv.(1) in
  if system = "macosx" && env_flag "SLIPSHOW_DELETE_HOMEBREW_DYLIBS" then
    delete_homebrew_dylibs ();
  print_endline
    (if env_flag "SLIPSHOW_STATIC" then "(-cclib -static -cclib -no-pie)"
     else "()")
