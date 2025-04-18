open Lwt.Syntax

(* A promise that never returns and consumes a file
   unwatcher *)
let wait_forever (_unwatch : unit -> unit Lwt.t) =
  let forever, _ = Lwt.wait () in
  forever

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

let do_watch input f =
  let input = Fpath.normalize input in
  let depending_on_files = Fpath.Set.singleton input in
  let parent = Fpath.parent input in
  let cond = Lwt_condition.create () in
  let state_depending_on_files = ref depending_on_files in
  let callback prefix filename =
    let full_name = Fpath.normalize @@ Fpath.( / ) prefix filename in
    Logs.app (fun m -> m "Testing if %a is watched" Fpath.pp full_name);
    if Fpath.Set.mem full_name !state_depending_on_files then (
      Logs.app (fun m -> m "Recompiling");
      Lwt_condition.signal cond ());
    Lwt.return_unit
  in
  let watch dir =
    Logs.app (fun m -> m "Watch directory %a" Fpath.pp dir);
    let poll_watch =
      if false then
        Irmin_watcher__.Core.hook (Lazy.force Irmin_watcher__Polling.v)
      else Irmin_watcher.hook
    in
    let+ unwatch =
      poll_watch 0 (Fpath.to_string dir) (callback (Fpath.v "./"))
    in
    fun () ->
      Logs.app (fun m -> m "Unwatching %a" Fpath.pp dir);
      unwatch ()
  in
  let listened_directories = Fpath.Map.singleton parent (watch parent) in
  let rec main listened_directories depending_on_files =
    let update return listened_directories _depending_on_files =
      let depending_on_files = Fpath.Set.of_list return in
      Logs.app (fun m ->
          m "Now depending on files: %a" (Fmt.list Fpath.pp) return);
      let new_listened_directories =
        Fpath.Set.fold
          (fun file map ->
            let parent = Fpath.parent file in
            match Fpath.Map.find_opt parent listened_directories with
            | None ->
                let u = watch parent in
                Fpath.Map.add parent u map
            | Some u -> Fpath.Map.add parent u map)
          depending_on_files Fpath.Map.empty
      in
      let () =
        Fpath.Map.iter
          (fun dir unwatch ->
            let _ =
              if not (Fpath.Map.mem dir new_listened_directories) then
                let* unwatch = unwatch in
                unwatch ()
              else Lwt.return ()
            in
            ())
          listened_directories
      in
      (new_listened_directories, depending_on_files)
    in
    let listened_directories, depending_on_files =
      match f () with
      | Ok return -> update return listened_directories depending_on_files
      | Error (`Msg s) ->
          Logs.warn (fun m -> m "%s" s);
          (listened_directories, depending_on_files)
    in
    state_depending_on_files := depending_on_files;
    let* () = Lwt_condition.wait cond in
    main listened_directories depending_on_files
  in
  Lwt_main.run (main listened_directories depending_on_files)

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

let do_serve input f =
  let () = if Sys.unix then Sys.(set_signal sigpipe Signal_ignore) in
  (* We need this, otherwise the program is killed when sending a long string to
     a closed connection... See https://github.com/aantron/dream/issues/378 *)

  let cond = Lwt_condition.create () in
  let do_serve input f =
    match input with
    | `Stdin ->
        Lwt.return @@ Error (`Msg "--serve is incompatible with stdin input")
    | `File input ->
        let open Lwt.Syntax in
        let parent = Fpath.parent input in
        let parent = Fpath.to_string parent in
        let input_filename = Fpath.filename input in
        let content = ref "" in
        let new_content =
          match f () with
          | Ok s -> Slipshow.delayed_to_string s
          | Error (`Msg s) ->
              Logs.warn (fun m -> m "%s" s);
              s
        in
        content := new_content;
        let _ =
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
        let callback filename =
          if String.equal filename input_filename then (
            Logs.app (fun m -> m "Recompiling");
            let new_content =
              match f () with
              | Ok s -> Slipshow.delayed_to_string s
              | Error (`Msg s) ->
                  Logs.warn (fun m -> m "%s" s);
                  s
            in
            content := new_content;
            Lwt_condition.broadcast cond ());
          Lwt.return_unit
        in
        let* unwatch = Irmin_watcher.hook 0 parent callback in
        wait_forever unwatch
  in
  Logs.app (fun m ->
      m
        "Visit http://127.0.0.1:8080 to view your presentation, with \
         auto-reloading on file changes.");
  Lwt_main.run @@ do_serve input f
