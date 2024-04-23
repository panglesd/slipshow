let uri =
  let uri = Brr.Window.location Brr.G.window in
  let uri =
    let scheme =
      match Brr.Uri.scheme uri |> Jstr.to_string with
      | "https" -> Jstr.v "wss"
      | _ -> Jstr.v "ws"
    in
    Brr.Uri.with_uri ~scheme uri |> Result.get_ok
  in
  let params = Brr.Uri.query uri in
  let fragment = Brr.Uri.fragment uri in
  (* let uri = Brr.Uri.with_fragment_params *)
  Brr.Console.(log [ "param is: "; params ]);
  Brr.Console.(log [ "fragment is: "; fragment ]);
  let uri =
    Brr.Uri.with_fragment_params uri (Brr.Uri.Params.of_jstr (Jstr.v ""))
  in
  let params = Brr.Uri.query uri in
  Brr.Console.(log [ "param after is: "; params ]);
  let route_segment =
    let route_segment = [ "getNewDoc" ] in
    List.map Jstr.v route_segment
  in
  let uri = Brr.Uri.with_path_segments uri route_segment in
  uri |> Result.get_ok |> Brr.Uri.to_jstr

open Brr_io.Websocket

let elem = Brr.El.find_first_by_selector (Jstr.v "#iframes") |> Option.get
let previewer = Previewer.create_previewer elem

let rec recv () =
  Brr.Console.(log [ "Opening a websocket"; (* Brr.Uri.to_jstr *) uri ]);
  let ws = Brr_io.Websocket.create (* Brr.Uri.to_jstr *) uri in
  Brr.Console.(log [ "Websocket created" ]);
  let on_message event =
    let raw_data : Jstr.t = Brr_io.Message.Ev.data (Brr.Ev.as_type event) in
    Brr.Console.(log [ ("Got the following raw data: ", raw_data) ]);
    let data = Slipshow.string_to_delayed (Jstr.to_string raw_data) in
    (* Format.printf "Here is what we received: '%s'%!\n" *)
    (*   (Jstr.to_string raw_data); *)
    Previewer.preview_compiled previewer data
  in
  let _message_listener =
    Brr.Ev.listen Brr_io.Message.Ev.message on_message (as_target ws)
  in
  let on_open event =
    Brr.Console.(log [ "Websocket was opened with event:"; event ])
  in
  let _open_listener = Brr.Ev.listen Brr.Ev.open' on_open (as_target ws) in
  let on_close event =
    Brr.Console.(log [ "Websocket was closed with event:"; event ]);
    recv ()
  in
  let _close_listener =
    Brr.Ev.listen Brr_io.Websocket.Ev.close on_close (as_target ws)
  in
  let on_error event =
    Brr.Console.(log [ "Websocket was errored with event:"; event ])
  in
  let _error_listener = Brr.Ev.listen Brr.Ev.error on_error (as_target ws) in
  ()

let () = recv ()
