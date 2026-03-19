open Brr

let uri =
  let uri = Window.location G.window in
  let uri = Uri.with_fragment_params uri (Uri.Params.of_jstr (Jstr.v "")) in
  let route_segment = [ Jstr.v "long-polling" ] in
  let uri = Uri.with_path_segments uri route_segment in
  uri |> Result.get_ok |> Uri.to_jstr

let elem = El.find_first_by_selector (Jstr.v "#iframes") |> Option.get

let warnings =
  El.find_first_by_selector (Jstr.v "#warnings-slipshow") |> Option.get

let warnings_show =
  El.find_first_by_selector (Jstr.v "#warnings-slipshow-show") |> Option.get

let connection_show =
  El.find_first_by_selector (Jstr.v "#connection-slipshow") |> Option.get

let _unlistener =
  Ev.listen Ev.click
    (fun _ ->
      let show_class = Jstr.v "hide-warnings" in
      El.set_class show_class (not @@ El.class' show_class warnings) warnings)
    (El.as_target warnings_show)

let previewer =
  let initial_stage =
    G.window |> Window.location |> Uri.fragment |> Jstr.to_string
    |> int_of_string_opt
  in
  let callback i =
    let old_uri = Window.location G.window in
    match Uri.scheme old_uri |> Jstr.to_string with
    | "about" -> ()
    | _ ->
        let history = Window.history G.window in
        let uri =
          let fragment = Jstr.v (string_of_int i) in
          Uri.with_uri ~fragment old_uri |> Result.get_ok
        in
        Window.History.replace_state ~uri history
  in
  Previewer.create_previewer ?initial_stage ~callback ~include_speaker_view:true
    ~errors_el:warnings ~steal_focus:true elem

let ( !! ) = Jstr.v

let set_connected () =
  El.set_class !!"connected" true connection_show;
  El.set_class !!"disconnected" false connection_show

let set_disconnected () =
  El.set_class !!"connected" false connection_show;
  El.set_class !!"disconnected" true connection_show

open Proto

let version = ref ""

let handle_answer = function
  | Server_to_client.Pong -> Fut.return (Ok ())
  | Update data ->
      version := data.version;
      Previewer.preview_compiled previewer data.content;
      Fut.return (Ok ())

let proto_request_single ?signal msg =
  let open Brr_io.Fetch in
  let body = Body.of_jstr !!(Client_to_server.to_string msg) in
  let init = Request.init ~method':!!"post" ?signal ~body () in
  let req = Request.v ~init uri in
  Brr_io.Fetch.request req

let rec proto_request msg =
  let open Fut.Result_syntax in
  let* raw_data =
    let abort = Abort.controller () in
    let timeout = G.set_timeout ~ms:10000 @@ fun () -> Abort.abort abort in
    let signal = Abort.signal abort in
    let open Fut.Syntax in
    let* x = proto_request_single ~signal msg in
    G.stop_timer timeout;
    match x with
    | Error _ as e -> Fut.return e
    | Ok x ->
        let x = Brr_io.Fetch.Response.as_body x in
        Brr_io.Fetch.Body.text x
  in
  let data = Server_to_client.of_string (Jstr.to_string raw_data) in
  match data with
  | None ->
      Fut.return (Error (Jv.Error.v !!"Could not deserialize data from server"))
  | Some msg -> handle_answer msg

and do_and_retry msg =
  let open Fut.Syntax in
  let* res = proto_request msg in
  match res with
  | Ok () ->
      set_connected ();
      Fut.return ()
  | Error e ->
      set_disconnected ();
      Console.error [ e ];
      let rec wait_for_reconnect () =
        let* () = Fut.tick ~ms:3000 in
        let* result = proto_request Ping in
        match result with
        | Error e ->
            Console.error [ e ];
            wait_for_reconnect ()
        | Ok () -> Fut.return ()
      in
      let* () = wait_for_reconnect () in
      set_connected ();
      do_and_retry msg

let recv () =
  let rec recv_updates () =
    let open Fut.Syntax in
    let* () = do_and_retry (UpdateFrom !version) in
    recv_updates ()
  in
  recv_updates ()

let _ : unit Fut.t = recv ()
