let do_watch entry_point compile =
  let callback () =
    let res = compile () in
    let () = Result.iter (fun _ -> Logs.app (fun m -> m "Recompiled!")) res in
    res
  in
  let initial = Fpath.Set.singleton entry_point in
  Lwt_main.run @@ Watcher.watch_and_compile initial ~callback

let html_source =
  Format.sprintf
    {html|<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
           <title>Slipshow preview</title>
</head>
           <body>
           <div id="iframes" style="position:absolute;inset:0;">
           </div>
           <pre id="warnings-slipshow" class="hide-warnings"></pre>
           <div id="warnings-slipshow-show">⚠️</div>
           <div id="connection-slipshow"></div>
           <style>
             %s
           </style>
           <style>%s</style>
           <script>%s</script>
</body>
</html>
  |html}
    Server_assets.Style.v Ansi.css [%blob "client/client.bc.js"]

let () = Random.self_init ()

let generate_version () =
  String.init 10 (fun _ -> Char.chr (97 + Random.int 26))

let pong () =
  let c = Proto.Server_to_client.Pong in
  let c = Proto.Server_to_client.to_string c in
  Dream.respond ~headers:[ ("Content-Type", "text/plain") ] c

let send_update content =
  let c = Proto.Server_to_client.Update content in
  let c = Proto.Server_to_client.to_string c in
  Dream.respond ~headers:[ ("Content-Type", "text/plain") ] c

let do_serve ~port entry_point compile =
  let () = if Sys.unix then Sys.(set_signal sigpipe Signal_ignore) in
  (* We need this, otherwise the program is killed when sending a long string to
     a closed connection... See https://github.com/aantron/dream/issues/378 *)

  let cond = Lwt_condition.create () in
  snd @@ Lwt_main.run
  @@
  (Logs.app (fun m ->
       m
         "Visit http://127.0.0.1:%d to view your presentation, with \
          auto-reloading on file changes."
         port);
   let open Lwt.Syntax in
   let initial_content, _ =
     Slipshow.delayed ~has_speaker_view:false "Could not compile"
   in
   let content =
     ref
       { Proto.content = (initial_content, ""); version = generate_version () }
   in
   let callback () =
     let res = compile () in
     match res with
     | Error (`Msg err) as e ->
         content := { !content with content = (initial_content, err) };
         Lwt_condition.broadcast cond `Update;
         e
     | Ok (c, deps) ->
         content := { content = c; version = generate_version () };
         Lwt_condition.broadcast cond `Update;
         Ok deps
   in
   let initial = Fpath.Set.singleton entry_point in
   let wac = Watcher.watch_and_compile initial ~callback in
   let dream =
     (* We serve on [127.0.0.1] since in musl libc library, localhost would
             trigger a DNS request (which might not resolve) *)
     Dream.serve ~port ~interface:"127.0.0.1"
     @@ Dream.router
          [
            Dream.get "/" (fun _ ->
                Dream.log "A browser reloaded";
                Dream.html html_source);
            Dream.post "/long-polling" (fun req ->
                let* body = Dream.body req in
                let msg = Proto.Client_to_server.of_string body in
                match msg with
                | None -> Dream.respond ~status:`Bad_Request ""
                | Some Ping -> pong ()
                | Some (UpdateFrom version) -> (
                    if not @@ String.equal version !content.version then
                      send_update !content
                    else
                      let gate = Lwt_condition.wait cond in
                      let timeout =
                        let+ () = Lwt_unix.sleep 7. in
                        `Pong
                      in
                      let* event = Lwt.pick [ gate; timeout ] in
                      match event with
                      | `Pong -> pong ()
                      | `Update -> send_update !content));
          ]
   in
   Lwt.both dream wac)
