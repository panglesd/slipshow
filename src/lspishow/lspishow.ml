(** For the state, we need quite a few things:

    - A table for the current buffer state: the source (used to check if it has
      actually changed: some LSP clients do not hesitate to send DocDidChange
      events). This is [State.buffers]

    - A table for the reverse dependencies: Given a file, in which file it is
      included. This allows to get to the root of files. This is
      [Rev_deps.current] and mostly used with [Rev_deps.get_roots] or
      [Rev_deps.update_state].

    - A table for roots. This is used by the LSP server for diagnostics, jump to
      etc. It is kept up to date at each key-stroke.

    - (TODO) A table for roots, but kept up to date at each save. This is for
      the preview server, if the user prefers a "refresh on save". *)

open Lwt.Syntax

let lwt_list_iter f l =
  List.fold_left
    (fun acc x ->
      let* () = acc in
      f x)
    Lwt.return_unit l

module State = struct
  let mutex = Lwt_mutex.create ()

  (* [update_from_fs] is update done when we read a file from the filesystem
     (and not given by the lsp client). It is the one called at initialization
     step, mostly for computing deps. *)
  let rev_deps_from_fs (file : Fpath.t) =
    Lwt_mutex.with_lock mutex @@ fun () ->
    Format.eprintf "update_from_fs with file = %a\n%!" Fpath.pp file;
    let parent = Fpath.parent file in
    let read_file = Read_file.fs parent in
    let () =
      let new_unit = Slipshow.Compile.unit ~read_file file in
      Rev_deps.update_state ~old_unit:None ~new_unit file
    in
    Lwt.return_unit

  let update_from_buffer (file : Fpath.t) s =
    Lwt_mutex.with_lock mutex @@ fun () -> Lwt.return @@ Buffers.update file s
end

module Server = struct end

let diagnostics file : Linol.Lsp.Types.Diagnostic.t list option =
  let roots = Rev_deps.get_roots file in
  let root = Fpath.Set.choose_opt roots in
  match root with
  | None -> None
  | Some root -> (
      match Hashtbl.find_opt Roots.buffers root with
      | None -> None
      | Some { diagnostics = errors; _ } ->
          Some (List.concat_map (Diagnostic.of_error ~root ~file) errors))

(* Find all markdown files in the given directory (recursing over subdirectories) *)
let find_markdown_files path =
  Bos.OS.Dir.fold_contents ~traverse:`Any
    ~elements:
      (`Sat (fun p -> Ok (Fpath.has_ext "md" p || Fpath.has_ext "slp" p)))
    (fun p acc -> p :: acc)
    [] path

class lsp_server =
  object (self)
    inherit Linol_lwt.Jsonrpc2.server as super
    method spawn_query_handler f = Linol_lwt.spawn f
    method! config_hover = Some (`Bool true)
    method! config_definition = Some (`Bool true)

    method! on_req_initialize ~notify_back
        (params : Linol_lwt.InitializeParams.t) =
      let _wsf = params.workspaceFolders in
      let _uri = params.rootUri in
      let _pth = params.rootPath in
      let root =
        match params.workspaceFolders with
        | Some ws ->
            Option.map
              (List.map (fun (x : Linol_lwt.WorkspaceFolder.t) -> x.uri))
              ws
        | None -> (
            match params.rootUri with
            | Some root -> Some [ root ]
            | None -> None)
      in
      let roots = Option.value root ~default:[] in
      let () = Lsp_preview.initialize ~notify_back () in
      let* () =
        Format.eprintf
          "We find all markdown files in the root and compute their dependencies\n\
           %!";
        lwt_list_iter
          (fun root ->
            let path = root |> Linol_lwt.DocumentUri.to_path |> Fpath.v in
            Format.eprintf "Root: %a\n%!" Fpath.pp path;
            match find_markdown_files path with
            | Error (`Msg s) ->
                Format.eprintf "  error: %s\n%!" s;
                Lwt.return_unit
            | Ok files ->
                List.iter (Format.eprintf "  md: %a\n%!" Fpath.pp) files;
                lwt_list_iter State.rev_deps_from_fs files)
          roots
      in
      let () =
        Format.eprintf "Here are the root of each markdown file\n%!";
        Hashtbl.iter
          (fun path paths ->
            Format.eprintf "%a -> [%s]\n%!" Fpath.pp path
              (String.concat " "
              @@ (paths |> Fpath.Set.to_seq |> List.of_seq
                |> List.map Fpath.to_string)))
          Rev_deps.current
      in
      super#on_req_initialize ~notify_back params

    method! config_completion =
      Some (Linol_lwt.CompletionOptions.create ~triggerCharacters:[ "#" ] ())

    method! on_req_completion ~notify_back:_ ~id:_ ~uri ~pos ~ctx:_
        ~workDoneToken:_ ~partialResultToken:_ _doc_state =
      let ( let* ) = Option.bind in
      let ( let+ ) x f = Option.map f x in
      let path = uri |> Linol_lwt.DocumentUri.to_path |> Fpath.v in
      let res =
        let* root = Rev_deps.get_roots path |> Fpath.Set.choose_opt in
        let* { units = ast; _ } = Hashtbl.find_opt Roots.buffers root in
        let+ () =
          Current_ast.get_target ~path pos ast.action_plan |> Option.map ignore
          (* Just as a way to test we are in the context of a target. Later, it
             would be even better to filter the IDs using what the action
             expects (eg, only show ids for slip-script in an exec action) *)
        in
        let all_ids =
          Slipshow.Id_map.SMap.bindings ast.id_map |> List.map fst
        in
        let completions =
          List.map
            (fun id -> Linol_lwt.CompletionItem.create ~label:id ())
            all_ids
        in
        `List completions
      in
      Lwt.return res

    method! on_req_definition ~notify_back:_ ~id:_ ~uri ~pos ~workDoneToken:_
        ~partialResultToken:_ _doc_state =
      let ( let* ) = Option.bind in
      let ( let+ ) x f = Option.map f x in
      let path = uri |> Linol_lwt.DocumentUri.to_path |> Fpath.v in
      let res =
        let* root = Rev_deps.get_roots path |> Fpath.Set.choose_opt in
        let* { units = ast; _ } = Hashtbl.find_opt Roots.buffers root in
        let* id = Current_ast.get_target ~path pos ast.action_plan in
        let+ x = Slipshow.Id_map.SMap.find_opt id ast.id_map in
        let meta = snd (Slipshow.Id_map.Unionable_set.get x.definition).id in
        let loc = Cmarkit.Meta.textloc meta in
        let file = Cmarkit.Textloc.file loc |> Fpath.v |> Fpath.normalize in
        Format.eprintf "Going to location %a%!\n" Fpath.pp file;
        let uri = file |> Fpath.to_string |> Linol_lsp.Uri0.of_string in
        let range = Diagnostic.linoloc_of_textloc loc in
        let loc = Linol_lwt.Location.create ~range ~uri in
        `Location [ loc ]
      in
      Lwt.return res

    method! on_req_hover ~notify_back:_ ~id:_ ~uri ~pos ~workDoneToken:_ _ :
        Linol_lwt.Hover.t option Lwt.t =
      let ( let* ) = Option.bind in
      let ( let+ ) x f = Option.map f x in
      let r =
        let path = uri |> Linol_lwt.DocumentUri.to_path |> Fpath.v in
        let* buffer = Hashtbl.find_opt Buffers.buffers path in
        let* tail_attrs =
          let trail = Current_ast.get_leave ~path pos buffer.unit.ast in
          trail.attribute
        in
        match tail_attrs with
        | Key ((key, meta), _) | Value ((key, meta), _) ->
            let+ (module X) =
              List.find_opt
                (fun (module X : Actions_arguments.S) -> key = X.on)
                Actions_arguments.all_actions
            in
            let contents =
              Linol_lwt.MarkupContent.create ~kind:Markdown ~value:X.doc
            in
            let contents = `MarkupContent contents in
            let loc = Cmarkit.Meta.textloc meta in
            let range = Diagnostic.linoloc_of_textloc loc in
            Linol_lwt.Hover.create ~contents ~range ()
        | _ -> None
      in
      Lwt.return r

    method! config_modify_capabilities capabilities =
      let capabilities = super#config_modify_capabilities capabilities in
      {
        capabilities with
        documentHighlightProvider = Some (`Bool true);
        referencesProvider = Some (`Bool true);
        definitionProvider = Some (`Bool true);
        documentSymbolProvider = Some (`Bool true);
      }

    method private on_doc ~(notify_back : Linol_lwt.Jsonrpc2.notify_back)
        (uri : Linol.Lsp.Types.DocumentUri.t) (contents : string) =
      let file = uri |> Linol.Lsp.Types.DocumentUri.to_path |> Fpath.v in
      let* () =
        match Config.Refresh.when_ () with
        | Config.Edit -> State.update_from_buffer file contents
        | Config.Save | Config.Never -> Lwt.return ()
      in
      let diags = diagnostics file in
      match diags with
      | None -> Lwt.return ()
      | Some diags -> notify_back#send_diagnostic diags

    method private on_req_document_highlight ~notify_back:_ ~uri ~id:_
        (params : Linol_lwt.DocumentHighlightParams.t) :
        Linol_lwt.DocumentHighlight.t list option Lwt.t =
      let res =
        let ( let* ) = Option.bind in
        let ( let+ ) x f = Option.map f x in
        let path = uri |> Linol_lwt.DocumentUri.to_path |> Fpath.v in
        let* root = Rev_deps.get_roots path |> Fpath.Set.choose_opt in
        let* { units = ast; _ } = Hashtbl.find_opt Roots.buffers root in
        let* buffer = Hashtbl.find_opt Buffers.buffers path in
        let* id =
          let res1 =
            Current_ast.get_target ~path params.position ast.action_plan
          in
          match res1 with
          | Some _ -> res1
          | None -> (
              let* tail_attrs =
                let trail =
                  Current_ast.get_leave ~path params.position buffer.unit.ast
                in
                trail.attribute
              in
              match tail_attrs with Id (id, _) -> Some id | _ -> None)
        in
        let+ x = Slipshow.Id_map.SMap.find_opt id ast.id_map in
        let id = (Slipshow.Id_map.Unionable_set.get x.definition).id in
        let loc_def = Cmarkit.Meta.textloc @@ snd id in
        let loc_occ = x.usage in
        let locs = loc_def :: loc_occ in
        List.filter_map
          (fun loc ->
            let loc_in_file loc =
              let path1 =
                Cmarkit.Textloc.file loc |> Fpath.v |> Fpath.normalize
              in
              let path2 = Fpath.normalize path in
              Fpath.equal path1 path2
            in
            if loc_in_file loc then
              let range = Diagnostic.linoloc_of_textloc loc in
              Some (Linol_lwt.DocumentHighlight.create ~range ())
            else None)
          locs
      in
      Lwt.return res

    method! on_request_unhandled (type r) ~notify_back ~id
        (r : r Linol_lsp.Client_request.t) : r Lwt.t =
      match r with
      | Linol.Lsp.Client_request.TextDocumentHighlight params ->
          self#on_req_document_highlight ~notify_back ~id
            ~uri:params.textDocument.uri params
      | r -> super#on_request_unhandled ~notify_back ~id r

    method private receive_config =
      function
      | [ `Assoc x ] -> (
          match List.assoc_opt "refreshOn" x with
          | Some (`String "Key stroke") -> Config.Refresh.set Edit
          | Some (`String "Save") -> Config.Refresh.set Save
          | _ -> ())
      | _ -> ()

    method private on_initialized
        ~(notify_back : Linol_lwt.Jsonrpc2.notify_back) () =
      let ( let> ) cont f = cont f in
      let _ =
        (* {:https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspace_configuration}

            This pull model replaces the old push model were the client
            signaled configuration change via an event. If the server still
            needs to react to configuration changes (since the server caches
            the result of workspace/configuration requests) the server should
            register for an empty configuration change using the following
            registration pattern:

            {@javascript[
              connection.client.register(DidChangeConfigurationNotification.type, undefined);
            ]} *)
        let server_request =
          let registrations =
            [
              Linol_lwt.Registration.create ~id
                ~method_:"workspace/didChangeConfiguration" ();
            ]
          in
          let params = Linol_lwt.RegistrationParams.create ~registrations in
          Linol_lsp.Server_request.ClientRegisterCapability params
        in
        let> res = notify_back#send_request server_request in
        match res with Ok () -> Lwt.return () | Error _ -> _
      in
      let _ =
        let server_request =
          let item =
            Linol_lwt.ConfigurationItem.create ~section:"slipshow" ()
          in
          let params = Linol_lwt.ConfigurationParams.create ~items:[ item ] in
          Linol_lsp.Server_request.WorkspaceConfiguration params
        in
        let> res = notify_back#send_request server_request in
        match res with
        | Ok conf ->
            let () = self#receive_config conf in
            Lwt.return_unit
        | Error err ->
            let err = err |> Linol_jsonrpc.Jsonrpc.Response.Error.yojson_of_t in
            Format.eprintf "Response error for WorkspaceConfiguration: %a"
              Yojson.Safe.pp err;
            Lwt.return_unit
      in
      Lwt.return ()

    method private on_change_configuration ~notify_back:_ change_conf_params =
      let conf =
        change_conf_params.Linol_lwt.DidChangeConfigurationParams.settings
      in
      let () =
        match conf with
        | `List conf -> self#receive_config conf
        | _ -> self#receive_config [ conf ]
      in
      let () =
        Format.eprintf "Configuration: %a\n%!" Yojson.Safe.pp
          change_conf_params.Linol_lwt.DidChangeConfigurationParams.settings
      in
      Lwt.return ()

    method! on_notification_unhandled ~notify_back
        (r : Linol_lsp.Client_notification.t) : unit Lwt.t =
      match r with
      | Linol.Lsp.Client_notification.Initialized ->
          self#on_initialized ~notify_back ()
      | Linol.Lsp.Client_notification.ChangeConfiguration change_conf_params ->
          self#on_change_configuration ~notify_back change_conf_params
      | r -> super#on_notification_unhandled ~notify_back r

    method on_notif_doc_did_open ~notify_back d ~content : unit Linol_lwt.t =
      self#on_doc ~notify_back d.uri content

    method on_notif_doc_did_change ~notify_back d _c ~old_content:_old
        ~new_content =
      self#on_doc ~notify_back d.uri new_content

    method! on_notif_doc_did_save ~notify_back:_ params =
      let uri = params.textDocument.uri in
      let file = uri |> Linol_lwt.DocumentUri.to_path |> Fpath.v in
      let ( let+ ) x f = Fpath.Set.iter f x in
      let () =
        let+ file = Rev_deps.get_roots file in
        let parent = Fpath.parent file in
        let root =
          Roots.update_root (Read_file.fs parent) Roots.saved Fpath.Map.empty
            file
        in
        Lwt_condition.broadcast root.condition Update;
        let html =
          let delayed =
            Slipshow.delayed_from_units ~has_speaker_view:true root.units
          in
          Slipshow.add_starting_state delayed None
        in
        let output = Fpath.set_ext "html" file in
        let write filename content =
          try
            (* This test is just to give a better error message *)
            let directory = Fpath.parent filename |> Fpath.to_string in
            if not (Sys.is_directory directory) then
              Error (`Msg (directory ^ " is not a directory"))
            else
              Out_channel.with_open_text (Fpath.to_string filename) @@ fun oc ->
              Out_channel.output_string oc content;
              Ok ()
          with exn -> Error (`Msg (Printexc.to_string exn))
        in
        let () =
          match write output html with
          | Error (`Msg err) ->
              Format.eprintf "Error while writing on output file: %s\n%!" err
          | Ok () -> ()
        in
        ()
      in
      Linol_lwt.return ()

    method on_notif_doc_did_close ~notify_back:_ _d : unit Linol_lwt.t =
      Linol_lwt.return ()

    method private parse_file (args : Yojson.Safe.t list option) =
      match args with
      | Some (`String uri :: _) ->
          let uri =
            uri |> Linol_lwt.DocumentUri.of_string
            |> Linol_lwt.DocumentUri.to_path |> Fpath.v
          in
          Some uri
      | _ -> None

    method private send_control file c =
      let roots = Rev_deps.get_roots file in
      let make_root_go_next root =
        match Hashtbl.find_opt Roots.buffers root with
        | None -> ()
        | Some { condition; units; _ } ->
            Format.eprintf "Going next for root %a\n%!" Fpath.pp
              units.entry_point;
            Lwt_condition.broadcast condition (Control c)
      in
      Fpath.Set.iter make_root_go_next roots

    method! on_req_execute_command ~notify_back ~id ~workDoneToken (c : string)
        (args : Yojson.Safe.t list option) : Yojson.Safe.t Linol_lwt.t =
      let () =
        let ( let+ ) x f = Option.iter f x in
        match c with
        | "slipshow.go_next" ->
            let+ file = self#parse_file args in
            self#send_control file (Movement Forward)
        | "slipshow.go_previous" ->
            let+ file = self#parse_file args in
            self#send_control file (Movement Backward)
        | _ -> ()
      in
      super#on_req_execute_command ~notify_back ~id ~workDoneToken c args
  end

let run () =
  let s = new lsp_server in
  let server = Linol_lwt.Jsonrpc2.create_stdio ~env:() s in
  let task =
    let shutdown () = s#get_status = `ReceivedExit in
    Linol_lwt.Jsonrpc2.run ~shutdown server
  in
  match Linol_lwt.run task with
  | () -> Ok ()
  | exception e ->
      let e = Printexc.to_string e in
      Error ("error: " ^ e)
