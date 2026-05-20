(* open Lwt.Syntax *)

(* We need:
   - A server that runs at the start,
   - It serves 
 *)

(* A single function should be run in several cases. We don't want the function
   to be run twice at the same time. So we make it wait on a condition and each
   callback just signal that condition. *)

let html_source filename =
  let segments =
    filename |> Fpath.segs |> fun x ->
    Marshal.to_string x [] |> Base64.encode_string
  in
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
           <script>route_segment = "%s" </script>
           <script>%s</script>
</body>
</html>
  |html}
    Server_assets.Style.v Ansi.css segments
    [%blob "../server/client/client.bc.js"]

let pong () =
  let c = Proto.Server_to_client.Pong in
  let c = Proto.Server_to_client.to_string c in
  Dream.respond ~headers:[ ("Content-Type", "text/plain") ] c

let send_update content =
  let c = Proto.Server_to_client.Update content in
  let c = Proto.Server_to_client.to_string c in
  Dream.respond ~headers:[ ("Content-Type", "text/plain") ] c

let do_serve ~port (roots : Rev_deps.roots) =
  let () = if Sys.unix then Sys.(set_signal sigpipe Signal_ignore) in
  (* We need this, otherwise the program is killed when sending a long string to
     a closed connection... See https://github.com/aantron/dream/issues/378 *)

  (* let cond = Lwt_condition.create () in *)

  Logs.app (fun m ->
      m
        "Visit http://127.0.0.1:%d to view your presentation, with \
         auto-reloading on file changes."
        port);
  let open Lwt.Syntax in
  (* let k s = *)
  (*   let new_content = Slipshow.delayed_to_string s in *)
  (*   Lwt_condition.broadcast cond new_content *)
  (* in *)
  (* let wac = watch_and_compile compile k in *)
  let dream =
    (* We serve on [127.0.0.1] since in musl libc library, localhost would
             trigger a DNS request (which might not resolve) *)
    Dream.serve ~port ~interface:"127.0.0.1"
    @@ Dream.logger
    @@ Dream.router
         [
           Dream.get "/" (fun _ ->
               Dream.log "A browser reloaded";
               Dream.html (html_source (Fpath.v "rien")));
           Dream.get "/preview/**" (fun req ->
               let file = Dream.target req in
               let file =
                 let n = String.length "/preview/" in
                 String.sub file n (String.length file - n)
               in
               Format.eprintf "TARGET is %s\n%!" file;
               let file = Fpath.v file in
               Dream.log "A browser reloaded";
               Dream.html (html_source file));
           Dream.post "/polling/**" (fun req ->
               let file = Dream.target req in
               let file =
                 let n = String.length "/polling/" in
                 String.sub file n (String.length file - n)
               in
               Format.eprintf "TARGET is %s\n%!" file;
               let file = Fpath.v file in
               let root = Hashtbl.find_opt roots file in
               match root with
               | None -> Dream.respond ~status:`Bad_Request "TODO1"
               | Some root -> (
                   let* body = Dream.body req in
                   let msg = Proto.Client_to_server.of_string body in
                   match msg with
                   | None -> Dream.respond ~status:`Bad_Request "TODO2"
                   | Some Ping -> pong ()
                   | Some (UpdateFrom version) -> (
                       if not @@ String.equal version root.version then
                         let content =
                           Slipshow.delayed_from_units ~has_speaker_view:false
                             root.units
                         in
                         let warnings =
                           Slipshow.to_grace root.units root.diagnostics
                         in
                         let warnings =
                           List.map
                             (Format.asprintf "%a@.@."
                                (Grace_ansi_renderer.pp_diagnostic ?config:None
                                   ~code_to_string:Diagnosis.to_code))
                             warnings
                         in
                         let warnings =
                           List.map (Ansi.process (Ansi.create ())) warnings
                         in
                         let warnings = warnings |> String.concat "" in
                         let content =
                           {
                             Proto.content = (content, warnings);
                             version = root.version;
                           }
                         in
                         send_update content
                       else
                         let gate =
                           let+ () = Lwt_condition.wait root.condition in
                           `Pong
                         in
                         let timeout =
                           let+ () = Lwt_unix.sleep 7. in
                           `Pong
                         in
                         let* event = Lwt.pick [ gate; timeout ] in
                         match event with
                         | `Pong -> pong ()
                         | `Update -> (
                             let root = Hashtbl.find_opt roots file in
                             match root with
                             | None ->
                                 Dream.respond ~status:`Bad_Request "TODO3"
                             | Some root ->
                                 let content =
                                   Slipshow.delayed_from_units
                                     ~has_speaker_view:false root.units
                                 in
                                 let content =
                                   {
                                     Proto.content = (content, "");
                                     version = root.version;
                                   }
                                 in
                                 send_update content))));
         ]
  in
  (* Lwt.both  *) dream
(* wac *)
(* |> snd *)
