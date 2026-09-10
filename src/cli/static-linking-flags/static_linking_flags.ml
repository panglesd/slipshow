let env_flag name =
  match Sys.getenv_opt name with
  | Some ("1" | "true" | "yes") -> true
  | Some _ | None -> false

module Homebrew = struct
  (** Macos does not have a cli way to include all libraries statically easily.
      So, what we do, following Semgrep (before they started doing something
      else), is simply to delete the dynamic libs (the .dylib files), forcing
      the linker to use the static ones (the .a)

      See https://github.com/semgrep/semgrep/pull/10122 with some explanations
      on that. (And if I ever want to follow the route of Semgrep and disable
      autolinking, it'll be useful too)

      Note that it is destructive and should only be run in CI ^^ *)

  (* Homebrew formulae whose libraries must be linked statically. *)
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

  (** The way Homebrew stores libraries is as follows:
      {ul
       {- Each "library x version" is stored in [Cellar/<name>/<version>/lib] (a
          "keg"), for instance:
          {[
            Cellar/gmp/0.0.1/lib/libgmp.dylib
            Cellar/gmp/0.0.1/lib/libgmp.a
          ]}
       }
       {- There is a {i directory} symlink at [opt/gmp] pointing at
          [Cellar/gmp/0.0.1] (the currently active version)
       }
       {- There are {i file} symlinks in the [lib] directory, pointing to the
          files:
          {[
            lib/libgmp.dylib -> Cellar/gmp/0.0.1/lib/libgmp.dylib
            lib/libgmp.a     -> Cellar/gmp/0.0.1/lib/libgmp.a
          ]}
          Some homebrew formulas don't have entries there ("keg only"), eg if
          they implement a library also present in the system, or implemented in
          several versions.
       }
      }

      We are going to delete [opt/gmp/lib/libgmp.dylib], which is the
      [Cellar/gmp/0.0.1/lib/libgmp.dylib] file (after resolving the directory
      symlink), and then the [lib/libgmp.dylib] dangling symlink. *)
  let delete_dylibs () =
    List.iter
      (fun prefix ->
        (* Remove the [dylib] libraries themselves, under
           <prefix>/opt/<formula>/lib. *)
        List.iter
          (fun formula ->
            List.iter delete
            @@ entries (Filename.concat prefix ("opt/" ^ formula ^ "/lib")))
          homebrew_formulae;
        (* Remove the dangling symlinks. *)
        entries (Filename.concat prefix "lib")
        |> List.filter (fun path -> not (Sys.file_exists path))
        |> List.iter delete)
      homebrew_prefixes
end

let () =
  (* [Sys.argv.(1)] is dune's %{ocaml-config:system}: macosx, linux, mingw64… *)
  let system = Sys.argv.(1) in
  if system = "macosx" && env_flag "SLIPSHOW_DELETE_HOMEBREW_DYLIBS" then
    Homebrew.delete_dylibs ();
  print_endline
    (if env_flag "SLIPSHOW_STATIC" then "(-cclib -static -cclib -no-pie)"
     else "()")
