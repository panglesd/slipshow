open Lwt.Syntax

(* A promise that never returns and consumes a file
   unwatcher *)
let wait_forever (_unwatch : unit -> unit Lwt.t) =
  let forever, _ = Lwt.wait () in
  forever

let do_watch input f =
  match input with
  | `Stdin -> Error (`Msg "--watch is incompatible with stdin input")
  | `File input ->
      let parent = Fpath.parent input in
      let parent = Fpath.to_string parent in
      let input_filename = Fpath.filename input in
      let callback filename =
        if String.equal filename input_filename then (
          Logs.app (fun m -> m "Recompiling");
          match f () with
          | Ok _ -> Lwt.return_unit
          | Error (`Msg s) ->
              Logs.warn (fun m -> m "%s" s);
              Lwt.return_unit)
        else Lwt.return_unit
      in
      let main =
        let* unwatch = Irmin_watcher.hook 0 parent callback in
        wait_forever unwatch
      in
      Lwt_main.run main

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
