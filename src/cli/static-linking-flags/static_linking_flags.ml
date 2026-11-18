let env_flag name =
  match Sys.getenv_opt name with
  | Some ("1" | "true" | "yes") -> true
  | Some _ | None -> false

(** Dune parses our output as a sexp, so an atom containing a space, a quote or
    a backslash has to be quoted and escaped. Only paths can, and only on
    Windows, but it costs one function. *)
let sexp_atom s =
  let special c =
    c = ' ' || c = '"' || c = '\\' || c = '(' || c = ')' || c = ';'
  in
  if not (String.exists special s) then s
  else begin
    let b = Buffer.create (String.length s + 8) in
    Buffer.add_char b '"';
    String.iter
      (fun c ->
        if c = '"' || c = '\\' then Buffer.add_char b '\\';
        Buffer.add_char b c)
      s;
    Buffer.add_char b '"';
    Buffer.contents b
  end

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

module Mingw = struct
  (** On Windows, [ocamlopt] does not invoke the C compiler directly: it goes
      through [flexlink], which resolves [-lfoo] {i itself}, trying
      [libfoo.dll.a] before [libfoo.a]. For a library shipping both (OpenSSL,
      zlib) it therefore picks the import library, and the executable ends up
      needing [libcrypto-3-x64.dll] & co. next to it — exactly what we are
      trying to avoid.

      We cannot change what autolink emits: [-lssl -lcrypto] is recorded inside
      [ssl.cmxa], and it lands on the command line before anything we add. But
      flexlink searches the directories given with [-L] before the toolchain's
      own, one whole directory at a time — so pointing it at a directory that
      holds the static archives and no import library redirects those flags
      without having to suppress autolink. CI stages the archives and passes the
      directory in [SLIPSHOW_STATIC_LIBS]; see [.github/workflows/build.yaml].

      [-Wl,-static] is a separate matter. flexlink rewrites [-Wl,-x] into
      [-link x] and hands it to {i gcc}, so this really means [gcc -static]: a
      driver flag, covering the libraries gcc appends on its own (libgcc, the
      unwinder, winpthread) which never pass through flexlink. A bare [-static]
      would not do — flexlink does not know that option and stops with a usage
      error.

      The last four are what [libcrypto.pc] declares in [Libs.private], i.e.
      what a {i static} libcrypto needs beyond what autolink provides. The Win32
      ones stay imports on purpose: that is how the system gets to patch them.
  *)

  (* The archives CI is expected to have staged, for the error message only. *)
  let staged_archives = [ "libssl.a"; "libcrypto.a"; "libz.a" ]

  let search_path () =
    match Sys.getenv_opt "SLIPSHOW_STATIC_LIBS" with
    | Some dir when dir <> "" -> [ "-cclib"; "-L" ^ dir ]
    | Some _ | None ->
        prerr_endline
          ("static_linking_flags: SLIPSHOW_STATIC_LIBS is not set. Expected a \
            directory containing "
          ^ String.concat ", " staged_archives
          ^ " and no import library. Without it flexlink will pick the .dll.a \
             files and the binary will need OpenSSL's DLLs at runtime.");
        []

  let flags () =
    search_path ()
    @ [
        "-cclib";
        "-Wl,-static";
        "-cclib";
        "-lz";
        "-cclib";
        "-lws2_32";
        "-cclib";
        "-lgdi32";
        "-cclib";
        "-lcrypt32";
      ]
end

let () =
  (* [Sys.argv.(1)] is dune's %{ocaml-config:system}: macosx, linux, mingw64… *)
  let system = Sys.argv.(1) in
  if system = "macosx" && env_flag "SLIPSHOW_DELETE_HOMEBREW_DYLIBS" then
    Homebrew.delete_dylibs ();
  let flags =
    if not (env_flag "SLIPSHOW_STATIC") then []
    else
      match system with
      | "mingw64" | "mingw" -> Mingw.flags ()
      | _ -> [ "-cclib"; "-static"; "-cclib"; "-no-pie" ]
  in
  print_endline ("(" ^ String.concat " " (List.map sexp_atom flags) ^ ")")
