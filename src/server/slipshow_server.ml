let do_watch compile =
  let callback () =
    let res = compile () in
    Logs.app (fun m -> m "Recompiled!");
    res
  in
  Lwt_main.run @@ Watcher.watch_and_compile ~callback

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

let generate_version () =
  String.init 10 (fun _ -> Char.chr (97 + Random.int 26))

let do_serve ~port compile =
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
   let content = ref { Proto.content = ""; version = generate_version () } in
   let callback () =
     let ( let* ) = Result.bind in
     let* s, deps = compile () in
     let new_content = Slipshow.delayed_to_string s in
     content := { content = new_content; version = generate_version () };
     Lwt_condition.broadcast cond `Update;
     Ok deps
   in
   let wac = Watcher.watch_and_compile ~callback in
   let dream =
     (* We serve on [127.0.0.1] since in musl libc library, localhost would
             trigger a DNS request (which might not resolve) *)
     Dream.serve ~port ~interface:"127.0.0.1"
     @@ Dream.router
          [
            Dream.get "/" (fun _ ->
                Dream.log "A browser reloaded";
                Dream.html html_source);
            Dream.post "/now" (fun _ ->
                Dream.respond
                  ~headers:[ ("Content-Type", "text/plain") ]
                  (Proto.to_string (Update !content)));
            Dream.post "/onchange" (fun req ->
                let* body = Dream.body req in
                if not @@ String.equal body !content.version then
                  let c = Proto.Update !content in
                  let c = Proto.to_string c in
                  Dream.respond ~headers:[ ("Content-Type", "text/plain") ] c
                else
                  let gate = Lwt_condition.wait cond in
                  let timeout =
                    let+ () = Lwt_unix.sleep 7. in
                    `Pong
                  in
                  let* event = Lwt.pick [ gate; timeout ] in
                  let c =
                    match event with
                    | `Pong -> Proto.Pong
                    | `Update -> Update !content
                  in
                  let c = Proto.to_string c in
                  Dream.respond ~headers:[ ("Content-Type", "text/plain") ] c);
          ]
   in
   Lwt.both dream wac)
