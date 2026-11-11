open Lsp_client
open Brr
open Brr_webworkers

(* Taken from
   https://github.com/voodoos/merlin-js/blob/a7367198d332f153ed27de2136d3c6a4af8e206f/example/merlin-lsp-js/main.ml *)
let worker_transport (worker : Worker.t) : Transport.t =
  let handlers : (Jstr.t -> unit) list ref = ref [] in
  let listener ev =
    let data = Jv.get (Ev.to_jv ev) "data" in
    let msg = Jv.to_jstr data in
    List.iter (fun h -> h msg) !handlers
  in
  let _listener =
    Ev.listen Brr_io.Message.Ev.message listener (Worker.as_target worker)
  in
  Transport.create ~send:(Worker.post worker)
    ~subscribe:(fun handler -> handlers := handler :: !handlers)
    ~unsubscribe:(fun handler ->
      handlers := List.filter (fun h -> h != handler) !handlers)

let send port msg =
  let msg = Proto.Client_to_server.to_string msg in
  Brr_io.Message.Port.post port msg

type server = Worker.t * LSPClient.t * Linol_lsp.Lsp.Uri.t

let create_server ?(root_uri = "file:///workspace") worker_url =
  let worker = Worker.create (Jstr.v worker_url) in
  let open Fut.Result_syntax in
  let transport = worker_transport worker in
  let extensions = Extensions.language_server_extensions () in
  let client =
    let config = LSPClientConfig.create ~root_uri ~extensions () in
    LSPClient.create ~config ()
  in
  let client = LSPClient.connect client transport in
  let+ () = LSPClient.initializing client in
  let root_uri = Linol_lsp.Lsp.Uri.of_string root_uri in
  (worker, client, root_uri)

let uri_append root_uri path =
  let root_uri = root_uri |> Linol_lsp.Lsp.Uri.to_path |> Fpath.v in
  let file_path = Fpath.( // ) root_uri path in
  file_path |> Fpath.normalize |> Fpath.to_string |> Linol_lsp.Lsp.Uri.of_path
  |> Linol_lsp.Lsp.Uri.to_string

let extension (_server, client, root_uri) ~path =
  let file_uri = uri_append root_uri path in
  LSPClient.plugin client ~file_uri ~language_id:"markdown" ()

let preview ~errors_el preview_element (server, _client, root_uri) ~path =
  let file_uri = uri_append root_uri path in
  let port1, port2 =
    let channel = Brr_io.Message.Channel.create () in
    (Brr_io.Message.Channel.port1 channel, Brr_io.Message.Channel.port2 channel)
  in
  let () =
    let transfer = [ Brr_io.Message.transfer port2 ] in
    let opts = Brr_io.Message.opts ~transfer () in
    Worker.post ~opts server file_uri
  in
  let goto_loc : Common_types.gui_id -> unit =
   fun loc -> send port1 (Proto.Client_to_server.GotoLoc loc)
  in
  let save_coordinate :
      id:Common_types.gui_id -> coord:Actions_arguments.Gui.t -> unit =
   fun ~id ~coord ->
    let coord = Actions_arguments.Gui.to_string coord in
    send port1 (Proto.Client_to_server.Save_gui_position { id; coord })
  in
  let previewer =
    Previewer.create_previewer ~save_coordinate ~goto_loc
      ~include_speaker_view:false ~steal_focus:false ~can_save:false
      ~can_gui:true ~errors_el preview_element
  in
  let _unlistener =
    Brr.Ev.listen Brr_io.Message.Ev.message
      (fun ev ->
        let ev = Brr.Ev.as_type ev in
        let data = Brr_io.Message.Ev.data ev in
        match Proto.Server_to_client.of_string data with
        | None -> ()
        | Some msg -> Preview_client.handle_message previewer msg)
      (Brr_io.Message.Port.as_target port1)
  in
  Brr_io.Message.Port.start port1
