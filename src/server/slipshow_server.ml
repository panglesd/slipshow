open Lwt.Syntax

(* We need:
   - A list of directories we are watching
   - A list of files we depend on

   We need to keep those lists in sync:
   - If we do not depend on any files in a directory, we should stop watching it
   - When we start depending on a file, we should listen its parent directory if not already the case

   When we compile the presentation, we should record a list of the files we depend on.
   We should then update the list of directories we watch,
   start listening new directories
   stop listening some of them
   ...
 *)

(* A single function should be run in several cases. We don't want the function
   to be run twice at the same time. So we make it wait on a condition and each
   callback just signal that condition. *)

let watch_and_compile compile k =
  let depending_on_files = ref Fpath.Set.empty in
  let listened_directories = ref Fpath.Map.empty in
  let cond = Lwt_condition.create () in
  let rec compile_and_call_k () =
    match compile () with
    | Ok (result, new_dependencies) ->
        let+ () = update new_dependencies listened_directories in
        Lwt_condition.signal cond result
    | Error (`Msg s) ->
        Logs.warn (fun m -> m "%s" s);
        Lwt.return_unit
  and watch =
    let callback prefix filename =
      let full_name = Fpath.normalize @@ Fpath.( / ) prefix filename in
      if Fpath.Set.mem full_name !depending_on_files then compile_and_call_k ()
      else Lwt.return_unit
    in
    fun dir ->
      Logs.info (fun m -> m "Watching %a" Fpath.pp dir);
      Irmin_watcher.hook 0 (Fpath.to_string dir) (callback dir)
  and update new_dependencies listened_directories =
    let* new_listened_directories =
      (* Some new dependencies may require new directories to be watched *)
      Fpath.Set.fold
        (fun dir map ->
          match Fpath.Map.find_opt dir !listened_directories with
          | Some u ->
              let+ map = map in
              Fpath.Map.add dir u map
          | None ->
              let+ u = watch dir and+ map = map in
              Fpath.Map.add dir u map)
        (Fpath.Set.map
           (* Fold on the parent's set to avoid duplication on file's parent dir *)
           (fun file -> file |> Fpath.parent |> Fpath.normalize)
           new_dependencies)
        (Lwt.return Fpath.Map.empty)
    in
    Logs.info (fun m ->
        m "updating file dependencies to %a"
          (Fmt.list ~sep:Fmt.sp Fpath.pp)
          (Fpath.Set.fold (fun a x -> a :: x) new_dependencies []));
    let+ () =
      (* The new set of file dependencies may NOT need some directories to be
         watched anymore *)
      Fpath.Map.fold
        (fun dir unwatch acc ->
          let* () = acc in
          if not (Fpath.Map.mem dir new_listened_directories) then unwatch ()
          else Lwt.return ())
        !listened_directories Lwt.return_unit
    in
    depending_on_files := new_dependencies;
    listened_directories := new_listened_directories
  in
  let rec main () =
    let* res = Lwt_condition.wait cond in
    let _ = k res in
    main ()
  in
  let p_main = main () in
  let* () = compile_and_call_k () in
  p_main

let do_watch compile =
  let compile () = compile () |> Result.map (fun res -> ((), res)) in
  Lwt_main.run
  @@ watch_and_compile compile (fun () ->
         Logs.app (fun m -> m "Recompiled!");
         Lwt.return ())

let html_source =
  Format.sprintf
    {html|<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
           <title>Slipshow preview</title>
           <style>
           #right-panel1.active_panel, #right-panel2.active_panel {
             z-index: 1;
           }
           #right-panel1, #right-panel2 {
             z-index: 0;
           }
</style>
</head>
           <body>
           <div id="iframes">
	     <iframe name="frame" id="right-panel1" style="width:100%%; position:absolute; top:0;bottom:0;left:0;right:0;border:0; height: 100vh"></iframe>
	     <iframe name="frame" id="right-panel2" style="width:100%%; position:absolute; top:0;bottom:0;left:0;right:0;border:0; height: 100vh"></iframe>
           </div>
           <script>%s</script>
</body>
</html>
  |html}
    [%blob "client/client.bc.js"]

let do_serve compile =
  let () = if Sys.unix then Sys.(set_signal sigpipe Signal_ignore) in
  (* We need this, otherwise the program is killed when sending a long string to
     a closed connection... See https://github.com/aantron/dream/issues/378 *)

  let cond = Lwt_condition.create () in
  Lwt_main.run
    (Logs.app (fun m ->
         m
           "Visit http://127.0.0.1:8080 to view your presentation, with \
            auto-reloading on file changes.");
     let open Lwt.Syntax in
     let content = ref "" in
     let k s =
       let new_content = Slipshow.delayed_to_string s in
       content := new_content;
       Lwt_condition.broadcast cond ()
     in
     let wac = watch_and_compile compile k in
     let dream =
       (* We serve on [127.0.0.1] since in musl libc library, localhost would
             trigger a DNS request (which might not resolve) *)
       Dream.serve ~interface:"127.0.0.1"
       @@ Dream.logger
       @@ Dream.router
            [
              Dream.get "/" (fun _ ->
                  Dream.log "A browser reloaded";
                  Dream.html html_source);
              Dream.get "/now" (fun _ ->
                  Dream.respond
                    ~headers:[ ("Content-Type", "text/plain") ]
                    !content);
              Dream.get "/onchange" (fun _ ->
                  let* () = Lwt_condition.wait cond in
                  Dream.respond
                    ~headers:[ ("Content-Type", "text/plain") ]
                    !content);
            ]
     in
     Lwt.both dream wac)
  |> snd
