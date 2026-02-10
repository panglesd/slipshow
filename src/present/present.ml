let speaker_source html =
  let html =
    let buf = Buffer.create 10 in
    Cmarkit_html.buffer_add_html_escaped_string buf html;
    Buffer.contents buf
  in
  Format.sprintf
    {html|<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
           <title>Slipshow preview</title>
           <style>
           .presentation {
             z-index: 1;
             width:100%%;
             position:absolute;
             inset:0;
             border:0;
             height: 100vh;
           }
</style>
</head>
           <body>
           <iframe id="presentation" srcdoc="%s">
           </iframe>
           <script>%s</script>
</body>
</html>
  |html}
    html [%blob "htmls/speaker.bc.js"]

let dream content =
  Dream.serve ~port:8081 ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun req ->
             Dream.log "A browser reloaded";
             Dream.log "client: %s" (Dream.client req);
             Dream.log "tls: %b" (Dream.tls req);
             Dream.log "target: %s" (Dream.target req);
             Dream.html (speaker_source content));
       ]

let dream_speaker content =
  Dream.serve ~port:8082 ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun req ->
             Dream.log "A browser reloaded";
             Dream.log "client: %s" (Dream.client req);
             Dream.log "tls: %b" (Dream.tls req);
             Dream.log "target: %s" (Dream.target req);
             Dream.html content);
       ]

let bore () =
  let command = "bore local --to choum.net --port 61119 8081" in
  let _ = Sys.command command in
  Ok ()

let present content =
  let pid = Unix.fork () in
  if pid = 0 then bore ()
  else
    let lwt = Lwt.both (dream content) (dream_speaker content) in
    let (), () = Lwt_main.run lwt in
    Ok ()
