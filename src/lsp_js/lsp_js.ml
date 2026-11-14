open Lsp_client
open Brr
open Brr_webworkers

type request_handler = {
  request : 'a. 'a Linol_lsp.Server_request.t -> 'a Fut.t option;
}

let custom_handler ~request msg =
  let { request } = request in
  let ( let* ) x f = match x with Ok x -> f x | _ -> None in
  let yojson = Yojson.Safe.from_string (Jstr.to_string msg) in
  let lsp = Linol_jsonrpc.Jsonrpc.Packet.t_of_yojson yojson in
  match lsp with
  | Request ({ id; _ } as req) -> (
      let* (E req) = Linol_lsp.Server_request.of_jsonrpc req in
      match request req with
      | None -> None
      | Some res ->
          let fut =
            let open Fut.Syntax in
            let+ res = res in
            let yojson = Linol_lsp.Server_request.yojson_of_result req res in
            let response = Linol_jsonrpc.Jsonrpc.Response.ok id yojson in
            let yojson = Linol_jsonrpc.Jsonrpc.Response.yojson_of_t response in
            Yojson.Safe.to_string yojson
          in
          Some fut)
  | Response _ | Notification _ | Batch_response _ | Batch_call _ -> None

let editor client ~uri =
  let workspace = LSPClient.workspace client in
  let uri = Linol_lsp.Lsp.Uri.to_string uri in
  let open Fut.Syntax in
  let+ res = Workspace.display_file workspace ~uri in
  res
  |> Result.map @@ fun view ->
     Option.bind view @@ fun view ->
     LSPPlugin.get view |> Option.map (fun plugin -> (view, plugin))

let offset plugin (pos : Linol_lsp.Types.Position.t) =
  let pos =
    Jv.obj
      [| ("character", Jv.of_int pos.character); ("line", Jv.of_int pos.line) |]
  in
  LSPPlugin.from_position plugin ~pos ()

let show_doc_handler client = function
  | Linol_lsp.Server_request.ShowDocumentRequest
      { external_ = None | Some false; selection; takeFocus; uri } ->
      let res =
        let open Fut.Syntax in
        let+ res = editor client ~uri in
        match res with
        | Ok (Some (view, plugin)) ->
            let () =
              match selection with
              | None -> ()
              | Some { end_; start } ->
                  let transaction =
                    let open Code_mirror.State.TransactionSpec in
                    let offset = offset plugin in
                    let selection =
                      Short { anchor = offset start; head = Some (offset end_) }
                    in
                    create ~selection ~scroll_into_view:true ()
                  in
                  Code_mirror.View.EditorView.dispatch view transaction
            in
            let () =
              match takeFocus with
              | Some false -> ()
              | _ -> Code_mirror.View.EditorView.focus view
            in
            Linol_lsp.Types.ShowDocumentResult.create ~success:true
        | Ok None | Error _ ->
            Linol_lsp.Types.ShowDocumentResult.create ~success:false
      in
      Some res
  | ShowDocumentRequest { external_ = Some true; _ } ->
      Some
        (Fut.return @@ Linol_lsp.Types.ShowDocumentResult.create ~success:true)

let text_edit_handler client = function
  | Linol_lsp.Server_request.WorkspaceApplyEdit
      {
        edit =
          { changeAnnotations = _; changes = Some changes; documentChanges = _ };
        label = _;
      } ->
      let open Fut.Syntax in
      let edits =
        List.map
          (fun (uri, (changes : Linol_lsp.Lsp.Types.TextEdit.t list)) ->
            let+ res = editor client ~uri in
            match res with
            | Ok (Some (view, plugin)) ->
                let change ({ newText; range } : Linol_lsp.Types.TextEdit.t) =
                  Code_mirror.State.ChangeSpec.create
                    ~from:(offset plugin range.start)
                    ~to_:(offset plugin range.end_) ~insert:newText ()
                in
                let changes =
                  List.map change changes
                  |> Code_mirror.State.ChangeSpec.of_list
                in
                let transaction =
                  Code_mirror.State.TransactionSpec.create ~changes ()
                in
                Code_mirror.View.EditorView.dispatch view transaction;
                true
            | _ -> false)
          changes
      in
      let applied =
        let+ applied = Fut.of_list edits in
        let applied = List.for_all Fun.id applied in
        Linol_lsp.Types.ApplyWorkspaceEditResult.create ~applied ()
      in
      Some applied
  | Linol_lsp.Server_request.WorkspaceApplyEdit
      {
        edit = { changeAnnotations = _; changes = None; documentChanges = _ };
        label = _;
      } ->
      None

let show_document : type a.
    LSPClient.t -> a Linol_lsp.Server_request.t -> a Fut.t option =
 fun client x ->
  match x with
  | ShowDocumentRequest _ as x -> show_doc_handler client x
  | WorkspaceApplyEdit _ as x -> text_edit_handler client x
  | _ -> None

let show_document client = { request = (fun x -> show_document client x) }

(* Taken from
   https://github.com/voodoos/merlin-js/blob/a7367198d332f153ed27de2136d3c6a4af8e206f/example/merlin-lsp-js/main.ml *)
let worker_transport ~custom_handler (worker : Worker.t) : Transport.t =
  let handlers : (Jstr.t -> unit) list ref = ref [] in
  let listener ev =
    let data = Jv.get (Ev.to_jv ev) "data" in
    let msg = Jv.to_jstr data in
    match custom_handler msg with
    | None -> List.iter (fun h -> h msg) !handlers
    | Some answer -> Fut.await answer (Worker.post worker)
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
  let extensions =
    Document_highlight.extension :: Extensions.language_server_extensions ()
  in
  let client =
    let config = LSPClientConfig.create ~root_uri ~extensions () in
    LSPClient.create ~config ()
  in
  let custom_handler = custom_handler ~request:(show_document client) in
  let transport = worker_transport ~custom_handler worker in
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
