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
let cond_step = Lwt_condition.create ()
let _cond_polls = Lwt_condition.create ()

open Lwt.Syntax

module State = struct
  let current_step = ref 0
  let poll_results : Present_comm.poll ref = ref Present_comm.StringMap.empty
end

let dream content =
  Dream.serve ~port:8081 ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router
       [
         Dream.post "/event" (fun req ->
             let* body = Dream.body req in
             let event = Present_comm.from_string body in
             let event =
               match event with
               | None ->
                   Dream.log "FAILED";
                   None
               | Some (Send_step _) -> None
               | Some (Vote { id; vote }) ->
                   Dream.log "Voting";
                   let new_poll =
                     Present_comm.StringMap.update id
                       (function
                         | Some results ->
                             let r =
                               Present_comm.IntMap.update vote
                                 (function
                                   | Some x -> Some (x + 1) | None -> Some 1)
                                 results
                             in
                             Some r
                         | None -> Some (Present_comm.IntMap.singleton vote 1))
                       !State.poll_results
                   in
                   State.poll_results := new_poll;
                   Some (Present_comm.Poll_truth !State.poll_results)
               | Some (Poll_truth _) -> None
             in
             Dream.log "Current step is now %d" !State.current_step;
             Dream.log "Total votes is now %d"
               (Present_comm.total_votes !State.poll_results);
             let () =
               Option.iter
                 (fun event ->
                   Dream.log "We are broadcasting";
                   Lwt_condition.broadcast cond_step event)
                 event
             in
             Dream.log "%s" body;
             Dream.html content);
         Dream.get "/" (fun req ->
             Dream.log "A browser reloaded";
             Dream.log "client: %s" (Dream.client req);
             Dream.log "tls: %b" (Dream.tls req);
             Dream.log "target: %s" (Dream.target req);
             Dream.html (audience_source content));
         Dream.get "/onchange" (fun req ->
             let their_step = Dream.query req "current_step" in
             let their_votes = Dream.query req "current_votes" in
             match (their_step, their_votes) with
             | None, _ | _, None -> failwith "HORREUR"
             | Some their_step, Some their_votes ->
                 let their_step = int_of_string their_step in
                 let their_votes = int_of_string their_votes in
                 let send_event event =
                   let event = Present_comm.to_string event in
                   Dream.respond
                     ~headers:[ ("Content-Type", "text/plain") ]
                     event
                 in
                 let send_current_step () =
                   let event =
                     Present_comm.Send_step (!State.current_step, `Fast)
                   in
                   send_event event
                 in
                 let send_current_votes () =
                   Dream.log "!!!!! Sending current votes";
                   let event = Present_comm.Poll_truth !State.poll_results in
                   send_event event
                 in
                 Dream.log
                   "Remember: their_step: %d, our_step: %d, their_votes: %d, \
                    our_votes: %d"
                   their_step !State.current_step their_votes
                   (Present_comm.total_votes !State.poll_results);
                 if
                   their_step = !State.current_step
                   && their_votes = Present_comm.total_votes !State.poll_results
                 then (
                   let* event = Lwt_condition.wait cond_step in
                   Dream.log "received the broadcast";
                   send_event event)
                 else if their_step = !State.current_step then
                   send_current_votes ()
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
               | Some (Send_step (i, _)) -> State.current_step := i
               | Some (Vote _) -> ()
               | Some (Poll_truth _) -> ()
             in
             Dream.log "Current step is now %d" !State.current_step;
             let () = Option.iter (Lwt_condition.broadcast cond_step) event in
             Dream.log "%s" body;
             Dream.html content);
         Dream.get "/" (fun req ->
             Dream.log "A browser reloaded";
             Dream.log "client: %s" (Dream.client req);
             Dream.log "tls: %b" (Dream.tls req);
             Dream.log "target: %s" (Dream.target req);
             Dream.html (speaker_source content));
         Dream.get "/onchange" (fun req ->
             let their_votes = Dream.query req "current_votes" in
             match their_votes with
             | None -> failwith "HORREUR"
             | Some their_votes ->
                 let their_votes = int_of_string their_votes in
                 let send_event event =
                   let event = Present_comm.to_string event in
                   Dream.respond
                     ~headers:[ ("Content-Type", "text/plain") ]
                     event
                 in
                 let send_current_votes () =
                   Dream.log "!!!!! Sending current votes";
                   let event = Present_comm.Poll_truth !State.poll_results in
                   send_event event
                 in
                 Dream.log "Remember: their_votes: %d, our_votes: %d"
                   their_votes
                   (Present_comm.total_votes !State.poll_results);
                 if their_votes = Present_comm.total_votes !State.poll_results
                 then (
                   let* event = Lwt_condition.wait cond_step in
                   Dream.log "received the broadcast";
                   send_event event)
                 else send_current_votes ());
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
