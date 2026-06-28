module B64 = Base64
open Brr

let uri =
  let ( let* ) x f = Result.bind x f in
  let ( let+ ) x f = Result.map f x in
  let uri = Window.location G.window in
  let uri = Uri.with_fragment_params uri (Uri.Params.of_jstr (Jstr.v "")) in
  let route_segment = Jv.get (Brr.Window.to_jv Brr.G.window) "route_segment" in
  Console.(log [ route_segment ]);
  let* route_segment = route_segment |> Jv.to_string |> B64.decode in
  let* route_segment =
    try Ok (Marshal.from_string route_segment 0)
    with Invalid_argument s | Failure s ->
      Error (`Msg ("Error during unmarshalling: " ^ s))
  in
  let route_segment = Jstr.v "polling" :: List.map Jstr.v route_segment in
  Console.(log [ Jv.of_list Jv.of_jstr route_segment ]);
  let+ uri =
    Uri.with_path_segments uri route_segment |> Result.map_error (fun e -> `J e)
  in
  Uri.to_jstr uri

let uri =
  match uri with
  | Error (`Msg s) ->
      Console.(error [ s ]);
      failwith s
  | Error (`J s) ->
      Console.(error [ s ]);
      Jv.throw (Jv.Error.message s)
  | Ok uri -> uri

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

open Proto

let ( !! ) = Jstr.v
let version = ref ""

(* I'm not proud of that. This is set to [previewer'] defined below. I need (?)
   that to cancel a circular dependency: defining [previewer'] requires defining
   the [handle_answer] function which requires [previewer'] *)
let previewer = ref None

let handle_answer msg =
  match !previewer with
  | None -> Fut.return (Ok ())
  | Some previewer -> (
      match msg with
      | Server_to_client.Pong -> Fut.return (Ok ())
      | Update data ->
          version := data.version;
          Previewer.preview_compiled previewer data.content;
          Fut.return (Ok ())
      | Control (Movement Forward) ->
          Previewer.next previewer;
          Fut.return (Ok ())
      | Control (Movement Backward) ->
          Previewer.previous previewer;
          Fut.return (Ok ())
      | Saved _ ->
          (* TODO: Show a notification that the file has been saved *)
          Fut.return (Ok ()))

let proto_request_single ?signal uri msg =
  let open Brr_io.Fetch in
  let body = Body.of_jstr !!(Client_to_server.to_string msg) in
  let init = Request.init ~method':!!"post" ?signal ~body () in
  let req = Request.v ~init uri in
  Brr_io.Fetch.request req

let proto_request uri msg =
  let open Fut.Result_syntax in
  let* raw_data =
    let abort = Abort.controller () in
    let timeout = G.set_timeout ~ms:10000 @@ fun () -> Abort.abort abort in
    let signal = Abort.signal abort in
    let open Fut.Syntax in
    let* x = proto_request_single ~signal uri msg in
    G.stop_timer timeout;
    match x with
    | Error _ as e -> Fut.return e
    | Ok x ->
        let x = Brr_io.Fetch.Response.as_body x in
        Brr_io.Fetch.Body.text x
  in
  match Server_to_client.of_string (Jstr.to_string raw_data) with
  | Some msg -> handle_answer msg
  | None ->
      Fut.return
        (Error
           (Jv.Error.v !!"Could not deserialize message from server to client"))

let previewer' =
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
  let save_drawing ~path ~content =
    let _ = proto_request uri (Save_drawing (path, content)) in
    ()
  in
  Previewer.create_previewer ?initial_stage ~callback ~save_drawing
    ~include_speaker_view:true ~errors_el:warnings ~steal_focus:true elem

let () = previewer := Some previewer'

let set_connected () =
  El.set_class !!"connected" true connection_show;
  El.set_class !!"disconnected" false connection_show

let set_disconnected () =
  El.set_class !!"connected" false connection_show;
  El.set_class !!"disconnected" true connection_show

let rec do_and_retry uri msg =
  let open Fut.Syntax in
  let* res = proto_request uri msg in
  match res with
  | Ok () ->
      set_connected ();
      Fut.return ()
  | Error e ->
      set_disconnected ();
      Console.error [ e ];
      let rec wait_for_reconnect () =
        let* () = Fut.tick ~ms:3000 in
        let* result = proto_request uri Ping in
        match result with
        | Error e ->
            Console.error [ e ];
            wait_for_reconnect ()
        | Ok () -> Fut.return ()
      in
      let* () = wait_for_reconnect () in
      set_connected ();
      do_and_retry uri msg

let recv uri () =
  let rec recv_updates () =
    let open Fut.Syntax in
    let* () = do_and_retry uri (UpdateFrom !version) in
    recv_updates ()
  in
  recv_updates ()

let _ : unit Fut.t = recv uri ()
