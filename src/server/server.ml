type to_server =
  | Update
  | Control of Proto.Server_to_client.control
  | ActivateGUI of Common_types.gui_id
  | DeActivateGUI

type root = {
  units : Slipshow.Ast.units;
  diagnostics : Diagnosis.t list;
  condition : to_server Lwt_condition.t;
  version : string;
}

type roots = (Fpath.t -> root option) * (unit -> Fpath.t list)

let html_source filename can_gui =
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
           <script>can_gui = %b </script>
           <script>%s</script>
</body>
</html>
  |html}
    Server_assets.Style.v Ansi.css segments can_gui
    [%blob "./client/client.bc.js"]

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

let send_event c =
  let c = Proto.Server_to_client.to_string c in
  Dream.respond ~headers:[ ("Content-Type", "text/plain") ] c

let pong () = send_event Pong
let saved s = send_event (Saved (Fpath.to_string s))
let notify s = send_event (Notify s)
let send_update content = send_event (Update content)
let send_control c = send_event (Control c)
let send_activate_gui id = send_event (Replace (Some id))
let send_deactivate_gui () = send_event (Replace None)

let home_page can_gui (_, get_roots) _req =
  Dream.log "A browser reloaded";
  let rs = get_roots () in
  match rs with
  | [] -> Dream.html (html_source (Fpath.v "/") can_gui)
  | [ unique_root ] -> Dream.html (html_source unique_root can_gui)
  | rs -> Dream.html (choose_roots rs)

let preview can_gui (roots, get_roots) req =
  let file = Dream.target req in
  let file =
    let n = String.length "/preview/" in
    String.sub file n (String.length file - n)
  in
  let file = Fpath.v file in
  let root = roots file in
  match root with
  | None -> home_page can_gui (roots, get_roots) req
  | Some _root ->
      Dream.log "A browser reloaded";
      Dream.html (html_source file can_gui)

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
  | `Master (ActivateGUI id) -> send_activate_gui id
  | `Master DeActivateGUI -> send_deactivate_gui ()

let polling (roots, _get_roots) ~to_lsp_server req =
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
      | Some msg -> (
          let () =
            match to_lsp_server with
            | None -> ()
            | Some to_lsp_server -> to_lsp_server msg root
          in
          match msg with
          | Ping -> pong ()
          | UpdateFrom version ->
              if not @@ String.equal version root.version then send root
              else wait_for_event root roots file
          | Save_drawing (path, drawing) ->
              let from = root.units.directory in
              let path = Fpath.v path in
              if
                Fpath.has_ext ".draw" path
                && Fpath.Map.mem path root.units.files
              then (
                let path = Fpath.( // ) from path in
                Dream.log "Saving drawing in %a with from %a" Fpath.pp path
                  Fpath.pp from;
                let res = Bos.OS.File.write path drawing in
                match res with
                | Ok () -> saved path
                | Error (`Msg err) ->
                    let msg =
                      Format.asprintf "Could not write %a: %s" Fpath.pp path err
                    in
                    notify msg)
              else
                let msg =
                  Format.asprintf "Path %a is not part of the current unit"
                    Fpath.pp path
                in
                notify msg
          | GotoLoc _ | Save_gui_position _ -> pong ()))

let do_serve ~port ~to_lsp_server (roots : roots) =
  let can_gui = Option.is_some to_lsp_server in
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
             Dream.get "/" (home_page can_gui roots);
             Dream.get "/preview/**" (preview can_gui roots);
             Dream.post "/polling/**" (polling roots ~to_lsp_server);
           ]
    in
    Ok ()
  in
  Lwt.catch dream (fun exn ->
      match exn with
      | Unix.Unix_error (Unix.EADDRINUSE, _, _) ->
          Lwt.return (Error `Addr_in_use)
      | exn -> Lwt.reraise exn)
