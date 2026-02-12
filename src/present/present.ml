let source html script =
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
           #presentation {
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
    html script

let speaker_source html = source html [%blob "htmls/speaker.bc.js"]
let audience_source html = source html [%blob "htmls/audience.bc.js"]
let cond = Lwt_condition.create ()

open Lwt.Syntax

let current_step = ref 0

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
             Dream.html (audience_source content));
         Dream.get "/onchange" (fun req ->
             let their_step = Dream.query req "current_step" in
             match their_step with
             | None -> failwith "HORREUR"
             | Some their_step ->
                 let their_step = int_of_string their_step in
                 let send_event event =
                   let event = Present_comm.to_string event in
                   Dream.respond
                     ~headers:[ ("Content-Type", "text/plain") ]
                     event
                 in
                 let send_current_step () =
                   let event = Present_comm.Send_step !current_step in
                   send_event event
                 in
                 if their_step = !current_step then
                   let* event = Lwt_condition.wait cond in
                   send_event event
                 else send_current_step ());
       ]

let dream_speaker content =
  Dream.serve ~port:8082 ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router
       [
         Dream.post "/event" (fun req ->
             let* body = Dream.body req in
             let event = Present_comm.from_string body in
             let () =
               match event with
               | None -> ()
               | Some (Send_step i) -> current_step := i
             in
             Dream.log "Current step is now %d" !current_step;
             let () = Option.iter (Lwt_condition.broadcast cond) event in
             Dream.log "%s" body;
             Dream.html content);
         Dream.get "/" (fun req ->
             Dream.log "A browser reloaded";
             Dream.log "client: %s" (Dream.client req);
             Dream.log "tls: %b" (Dream.tls req);
             Dream.log "target: %s" (Dream.target req);
             Dream.html (speaker_source content));
         Dream.get "/onchange" (fun _req ->
             let x, _ = Lwt.wait () in
             x);
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
