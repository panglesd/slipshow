open Brr

let uri typ =
  let uri = Window.location G.window in
  let uri = Uri.with_fragment_params uri (Uri.Params.of_jstr (Jstr.v "")) in
  let route_segment =
    let segment = match typ with `OnChange -> "onchange" | `Now -> "now" in
    [ Jstr.v segment ]
  in
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

let rec do_and_retry f arg =
  let open Fut.Syntax in
  let* x = f arg in
  match x with
  | Ok x -> Fut.return x
  | Error e ->
      set_disconnected ();
      Console.error [ e ];
      let* () = Fut.tick ~ms:3000 in
      do_and_retry f arg

let version = ref ""

let recv () =
  let ( $ ) f arg = do_and_retry f arg in
  let request_and_update typ =
    let open Fut.Result_syntax in
    let+ raw_data =
      let open Brr_io.Fetch in
      let abort = Abort.controller () in
      let timeout =
        G.set_timeout ~ms:10000 @@ fun () ->
        set_disconnected ();
        Abort.abort abort
      in
      let signal = Abort.signal abort in
      let body = Body.of_jstr !!(!version) in
      let init = Request.init ~method':!!"post" ~signal ~body () in
      let r = Request.v ~init (uri typ) in
      let open Fut.Syntax in
      let* x = request r in
      G.stop_timer timeout;
      match x with
      | Error _ as e -> Fut.return e
      | Ok x ->
          let x = Response.as_body x in
          Body.text x
    in
    let data = Proto.of_string (Jstr.to_string raw_data) in
    match data with
    | None -> set_disconnected ()
    | Some Pong ->
        Console.log [ "pong" ];
        set_connected ()
    | Some (Update data) -> (
        set_connected ();
        version := data.version;
        let data = Slipshow.string_to_delayed data.content in
        match data with
        | None ->
            Console.error [ "Error when deserializing payload" ];
            ()
        | Some data -> Previewer.preview_compiled previewer data)
  in
  let rec recv_updates () =
    let open Fut.Syntax in
    let* () = request_and_update $ `OnChange in
    recv_updates ()
  in
  let open Fut.Syntax in
  let* () = request_and_update $ `Now in
  recv_updates ()

let _ : unit Fut.t = recv ()
