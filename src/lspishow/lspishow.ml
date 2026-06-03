module Io = struct
  let read input =
    try
      match input with
      | `Stdin -> Ok In_channel.(input_all stdin)
      | `File f -> Bos.OS.File.read f
    with exn -> Error (`Msg (Printexc.to_string exn))
end

open Lwt.Syntax

let lwt_list_iter f l =
  List.fold_left
    (fun acc x ->
      let* () = acc in
      f x)
    Lwt.return_unit l

let generate_version () =
  String.init 10 (fun _ -> Char.chr (97 + Random.int 26))

module State = struct
  type buffer = { source : string; unit : Slipshow.Ast.unit' }
  type buffers = (Fpath.t, buffer) Hashtbl.t

  let buffers : buffers = Hashtbl.create 10
  let mutex = Lwt_mutex.create ()
  let roots_state : Rev_deps.roots = Hashtbl.create 10

  module Read_file = struct
    let v parent s =
      let ( // ) = Fpath.( // ) in
      let ( let+ ) a b = Result.map b a in
      let fp = Fpath.normalize @@ (parent // s) in
      Format.eprintf "fp is %a\n%!" Fpath.pp fp;
      match Hashtbl.find_opt buffers fp with
      | None ->
          let+ res = Io.read (`File fp) in
          Some res
      | Some buf -> Ok (Some buf.source)

    let with_ file source read_file s =
      if Fpath.equal file s then Ok (Some source) else read_file s

    let without parent s =
      let ( // ) = Fpath.( // ) in
      let ( let+ ) a b = Result.map b a in
      let fp = Fpath.normalize @@ (parent // s) in
      let+ res = Io.read (`File fp) in
      Some res
  end

  (* [update_from_fs] is update done when we read a file from the filesystem
     (and not given by the lsp client). It is the one called at initialization
     step, mostly for computing deps. *)
  let rev_deps_from_fs (file : Fpath.t) =
    Lwt_mutex.with_lock mutex @@ fun () ->
    Format.eprintf "update_from_fs with file = %a\n%!" Fpath.pp file;
    let parent = Fpath.parent file in
    let read_file = Read_file.v parent in
    let () =
      let new_unit = Slipshow.Compile.unit ~read_file file in
      Rev_deps.update_state ~old_unit:None ~new_unit file
    in
    Lwt.return_unit

  let update_state ~old ~new_ file =
    Format.eprintf "Opening/updating buffer: %a\n%!" Fpath.pp file;
    Hashtbl.replace buffers file new_;
    let old_unit = Option.map (fun old -> old.unit) old in
    Rev_deps.update_state ~old_unit ~new_unit:new_.unit file

  let update file source =
    match Hashtbl.find_opt buffers file with
    | Some { source = old_source; _ } when String.equal source old_source ->
        Lwt.return `No_changes
    | old ->
        let parent = Fpath.parent file in
        let read_file = Read_file.v parent |> Read_file.with_ file source in
        let unit = Slipshow.Compile.unit ~read_file file in
        let new_ = { source; unit } in
        update_state ~old ~new_ file;
        Lwt.return `Update

  let units_of_buffer () =
    Hashtbl.fold
      (fun path u -> Fpath.Map.add path u.unit)
      buffers Fpath.Map.empty

  let update_root root =
    let parent = Fpath.parent root in
    let read_file = Read_file.v parent in
    let units = units_of_buffer () in
    let units, diagnostics =
      Slipshow.Compile.compile_all ~read_file units root
    in
    let condition =
      match Hashtbl.find_opt roots_state root with
      | None -> Lwt_condition.create ()
      | Some { condition; _ } ->
          Lwt_condition.broadcast condition Update;
          condition
    in
    let version = generate_version () in
    Hashtbl.replace roots_state root { units; diagnostics; condition; version }

  let update_from_buffer (file : Fpath.t) s =
    Lwt_mutex.with_lock mutex @@ fun () ->
    let+ res = update file s in
    match res with
    | `No_changes ->
        let roots = Rev_deps.get_roots file in
        let compile_missing_roots root =
          match Hashtbl.find_opt roots_state root with
          | None -> update_root root
          | Some _ -> ()
        in
        Fpath.Set.iter compile_missing_roots roots
    | `Update ->
        let roots = Rev_deps.get_roots file in
        roots |> Fpath.Set.iter update_root
end

let send_info ~(notify_back : Linol_lwt.Jsonrpc2.notify_back) msg =
  let type_ = Linol_lwt.MessageType.Info in
  let k message =
    let msg = Linol_lwt.ShowMessageParams.create ~message ~type_ in
    let notif = Linol_lsp.Server_notification.ShowMessage msg in
    notify_back#send_notification notif
  in
  Format.kasprintf k msg

module Server = struct
  let server_promise = ref None

  let initialize ~notify_back () =
    let roots_state = Hashtbl.find_opt State.roots_state in
    let roots_list () = Hashtbl.to_seq_keys State.roots_state |> List.of_seq in
    let port0 = 8080 in
    let rec loop port =
      let* () =
        send_info ~notify_back "Starting preview server on port %d" port
      in
      let* try_port =
        Slipshow_server.Server.do_serve ~port (roots_state, roots_list)
      in
      match try_port with
      | Ok () -> Lwt.return_unit
      | Error `Addr_in_use ->
          let* () =
            send_info ~notify_back "Port %d appears already used" port
          in
          let port = port + 1 in
          if port - port0 > 100 then
            let* () =
              send_info ~notify_back
                "Tried 100 ports, starting from %d, none of them appeared \
                 usable"
                port0
            in
            Lwt.return_unit
          else loop port
    in
    loop port0

  let initialize ~notify_back () =
    match !server_promise with
    | None ->
        let lwt = initialize ~notify_back () in
        server_promise := Some lwt
    | Some _ -> ()
end

let diagnostics file : Linol.Lsp.Types.Diagnostic.t list option =
  let roots = Rev_deps.get_roots file in
  let root = Fpath.Set.choose_opt roots in
  match root with
  | None -> None
  | Some root -> (
      match Hashtbl.find_opt State.roots_state root with
      | None -> None
      | Some { diagnostics = errors; _ } ->
          Some (List.concat_map (Diagnostic.of_error ~root ~file) errors))

(* Find all markdown files in the given directory (recursing over subdirectories) *)
let find_markdown_files path =
  Bos.OS.Dir.fold_contents ~traverse:`Any
    ~elements:(`Sat (fun p -> Ok (Fpath.has_ext "md" p)))
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
      let () = Server.initialize ~notify_back () in
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
        let* { units = ast; _ } = Hashtbl.find_opt State.roots_state root in
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
        let* { units = ast; _ } = Hashtbl.find_opt State.roots_state root in
        let* id = Current_ast.get_target ~path pos ast.action_plan in
        let+ x = Slipshow.Id_map.SMap.find_opt id ast.id_map in
        let meta = snd (Slipshow.Id_map.Unionable_set.get x.definition).id in
        let loc = Cmarkit.Meta.textloc meta in
        let file = Fpath.v (Cmarkit.Textloc.file loc) in
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
        let* buffer = Hashtbl.find_opt State.buffers path in
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
      let* () = State.update_from_buffer file contents in
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
        let* { units = ast; _ } = Hashtbl.find_opt State.roots_state root in
        let* buffer = Hashtbl.find_opt State.buffers path in
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
              let path1 = Fpath.v (Cmarkit.Textloc.file loc) in
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

    method on_notif_doc_did_open ~notify_back d ~content : unit Linol_lwt.t =
      self#on_doc ~notify_back d.uri content

    method on_notif_doc_did_change ~notify_back d _c ~old_content:_old
        ~new_content =
      self#on_doc ~notify_back d.uri new_content

    method! on_notif_doc_did_save ~notify_back:_ params =
      Format.eprintf "SAVING!\n%!";
      let uri = params.textDocument.uri in
      let file = uri |> Linol_lwt.DocumentUri.to_path |> Fpath.v in
      let ( let+ ) x f = Fpath.Set.iter f x in
      let () =
        let+ file = Rev_deps.get_roots file in
        let html, _warnings =
          let read_file = State.Read_file.v (Fpath.parent file) in
          Slipshow.convert ~has_speaker_view:true ~read_file file
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
        match Hashtbl.find_opt State.roots_state root with
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
