type to_server = Update | Control of Proto.Server_to_client.control

type root = {
  units : Slipshow.Ast.units;
  diagnostics : Diagnosis.t list;
  condition : to_server Lwt_condition.t;
  version : string;
}

type roots = (Fpath.t -> root option) * (unit -> Fpath.t list)

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
    Server_assets.Style.v Ansi.css segments [%blob "./client/client.bc.js"]

let choose_roots rs =
  Format.sprintf
    {html|<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Slipshow preview</title>
</head>
<body>
  <h1>Slipshow's preview server</h1>
  This server is serving multiple presentation previews:
  <ul>
    %s
  </ul>
</body>
</html>
|html}
    (rs
    |> List.map (fun p ->
        Format.asprintf "<li><a href='/preview/%s'>%s</a></li>"
          (p |> Fpath.segs
          |> List.map Dream.to_percent_encoded
          |> String.concat "/")
          (p |> Fpath.to_string |> Dream.html_escape))
    |> String.concat "")

let pong () =
  let c = Proto.Server_to_client.Pong in
  let c = Proto.Server_to_client.to_string c in
  Dream.respond ~headers:[ ("Content-Type", "text/plain") ] c

let saved s =
  let c = Proto.Server_to_client.Saved (Fpath.to_string s) in
  let c = Proto.Server_to_client.to_string c in
  Dream.respond ~headers:[ ("Content-Type", "text/plain") ] c

let send_update content =
  let c = Proto.Server_to_client.Update content in
  let c = Proto.Server_to_client.to_string c in
  Dream.respond ~headers:[ ("Content-Type", "text/plain") ] c

let send_control c =
  let c = Proto.Server_to_client.Control c in
  let c = Proto.Server_to_client.to_string c in
  Dream.respond ~headers:[ ("Content-Type", "text/plain") ] c

let home_page (_, get_roots) _req =
  Dream.log "A browser reloaded";
  let rs = get_roots () in
  match rs with
  | [] -> Dream.html (html_source (Fpath.v "/"))
  | [ unique_root ] -> Dream.html (html_source unique_root)
  | rs -> Dream.html (choose_roots rs)

let preview (roots, get_roots) req =
  let file = Dream.target req in
  let file =
    let n = String.length "/preview/" in
    String.sub file n (String.length file - n)
  in
  let file = Fpath.v file in
  let root = roots file in
  match root with
  | None -> home_page (roots, get_roots) req
  | Some _root ->
      Dream.log "A browser reloaded";
      Dream.html (html_source file)

let send root =
  let content =
    Slipshow.delayed_from_units ~has_speaker_view:false root.units
  in
  let warnings = Slipshow.to_grace root.units root.diagnostics in
  let warnings =
    List.map
      (Format.asprintf "%a@.@."
         (Grace_ansi_renderer.pp_diagnostic ?config:None
            ~code_to_string:Diagnosis.to_code))
      warnings
  in
  let warnings = List.map (Ansi.process (Ansi.create ())) warnings in
  let warnings = warnings |> String.concat "" in
  let content =
    { Proto.content = (content, warnings); version = root.version }
  in
  send_update content

let wait_for_event root roots file =
  let open Lwt.Infix in
  let open Lwt.Syntax in
  let gate = Lwt_condition.wait root.condition >|= fun x -> `Master x in
  let timeout = Lwt_unix.sleep 7. >|= fun () -> `Pong in
  let* event = Lwt.pick [ gate; timeout ] in
  match event with
  | `Pong -> pong ()
  | `Master (Control c) -> send_control c
  | `Master Update -> (
      (* We reload root to get the updated value *)
      let root = roots file in
      match root with
      | None ->
          Dream.respond ~status:`Bad_Request
            (Format.asprintf "File %a is not part of the possible preview"
               Fpath.pp file)
      | Some root -> send root)

let polling (roots, _get_roots) req =
  let open Lwt.Syntax in
  let file = Dream.target req in
  let file =
    let n = String.length "/polling/" in
    String.sub file n (String.length file - n)
  in
  let file = Fpath.v file in
  let root = roots file in
  match root with
  | None ->
      Dream.respond ~status:`Bad_Request
        (Format.asprintf "File %a is not part of the possible preview" Fpath.pp
           file)
  | Some root -> (
      let* body = Dream.body req in
      let msg = Proto.Client_to_server.of_string body in
      match msg with
      | None ->
          Dream.respond ~status:`Bad_Request "Error while decoding the payload"
      | Some Ping -> pong ()
      | Some (UpdateFrom version) ->
          if not @@ String.equal version root.version then send root
          else wait_for_event root roots file
      | Some (Save_drawing (path, drawing)) -> (
          let from = root.units.directory in
          let path = Fpath.v path in
          let path = Fpath.( // ) from path in
          Dream.log "Saving drawing in %a with from %a" Fpath.pp path Fpath.pp
            from;
          let res = Bos.OS.File.write path drawing in
          match res with
          | Ok () -> saved path
          | Error (`Msg err) ->
              Dream.log "Could not write %a: %s" Fpath.pp path err;
              saved path))

let do_serve ~port (roots : roots) =
  let () = if Sys.unix then Sys.(set_signal sigpipe Signal_ignore) in
  (* We need this, otherwise the program is killed when sending a long string to
     a closed connection... See https://github.com/aantron/dream/issues/378 *)

  Logs.app (fun m ->
      m
        "Visit http://127.0.0.1:%d to view your presentation, with \
         auto-reloading on file changes."
        port);
  (* We serve on [127.0.0.1] since in musl libc library, localhost would trigger
     a DNS request (which might not resolve) *)
  let dream () =
    let open Lwt.Syntax in
    let+ () =
      Dream.serve ~port ~interface:"127.0.0.1"
      (* @@ Dream.logger *)
      @@ Dream.router
           [
             Dream.get "/" (home_page roots);
             Dream.get "/preview/**" (preview roots);
             Dream.post "/polling/**" (polling roots);
           ]
    in
    Ok ()
  in
  Lwt.catch dream (fun exn ->
      match exn with
      | Unix.Unix_error (Unix.EADDRINUSE, _, _) ->
          Lwt.return (Error `Addr_in_use)
      | exn -> Lwt.reraise exn)
