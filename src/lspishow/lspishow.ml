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

module State = struct
  [@@@ocaml.warning "-32-26"]

  type buffer = { source : string; compiled : Slipshow.Compile.t }
  type buffers = (Fpath.t, buffer) Hashtbl.t

  let buffers : buffers = Hashtbl.create 10
  let mutex = Lwt_mutex.create ()

  let read_file parent s =
    let ( // ) = Fpath.( // ) in
    let ( let+ ) a b = Result.map b a in
    let fp = Fpath.normalize @@ (parent // s) in
    Format.eprintf "fp is %a\n%!" Fpath.pp fp;
    match Hashtbl.find_opt buffers fp with
    | None ->
        let+ res = Io.read (`File fp) in
        Some (res, fp)
    | Some buf -> Ok (Some (buf.source, fp))

  let hashtbl_update h key f =
    match f (Hashtbl.find_opt h key) with
    | None -> ()
    | Some v -> Hashtbl.replace h key v

  module Rev_deps = struct
    type t = (Fpath.t, Fpath.Set.t) Hashtbl.t

    let current : t = Hashtbl.create 10

    let remove dependant depends =
      hashtbl_update current dependant @@ Option.map (Fpath.Set.remove depends)

    let add dependant depends =
      hashtbl_update current dependant @@ function
      | None -> Some (Fpath.Set.singleton depends)
      | Some set -> Some (Fpath.Set.add depends set)

    let get dependant =
      Hashtbl.find_opt current dependant
      |> Option.value ~default:Fpath.Set.empty

    let rec get_root f =
      match Fpath.Set.choose_opt @@ get f with
      | None -> f
      | Some f -> get_root f
  end

  let update_state ~only_deps ~old ~new_ file =
    if not only_deps then (
      Format.eprintf "Opening/updating buffer: %a\n%!" Fpath.pp file;
      Hashtbl.replace buffers file new_);
    let () =
      match old with
      | None -> ()
      | Some { compiled = { included_files; _ }; _ } ->
          Fpath.Map.iter
            (fun dependant _source -> Rev_deps.remove dependant file)
            included_files
    in
    let files = new_.compiled.included_files in
    Fpath.Map.iter
      (fun dependant _source ->
        Format.eprintf "Adding that %a depends on %a\n%!" Fpath.pp dependant
          Fpath.pp file;
        Rev_deps.add dependant file)
      files

  let update ~only_deps file source =
    Lwt_mutex.with_lock mutex @@ fun () ->
    match Hashtbl.find_opt buffers file with
    | Some { source = old_source; _ } when String.equal source old_source ->
        Lwt.return `No_changes
    | old -> (
        let parent, filename = Fpath.split_base file in
        let read_file = read_file parent in
        Format.eprintf "new read_file with parent = %a\n%!" Fpath.pp parent;
        match read_file filename with
        | Ok (Some (source, _)) ->
            let ((compiled, _errors) as return) =
              Slipshow.Compile.compile ~file ~read_file source
            in
            let new_ = { source; compiled } in
            update_state ~only_deps ~old ~new_ file;
            Lwt.return (`Update return)
        | _ -> Lwt.return `No_changes
        (* TODO: Show error *))

  let update_from_fs (file : Fpath.t) =
    Format.eprintf "update_from_fs with file = %a\n%!" Fpath.pp file;
    let parent, filename = Fpath.split_base file in
    let read_file = read_file parent in
    match read_file filename with
    | Ok (Some (md, _)) ->
        let+ _ = update ~only_deps:true file md in
        ()
    | _ -> Lwt.return_unit

  let update_from_buffer (file : Fpath.t) s = update ~only_deps:true file s
end

(* let split_by_inclusion (ast : Slipshow.Ast.t) = *)
(*   let folder = *)
(*     Slipshow.Ast.Folder.make *)
(*       ~block:(fun f acc -> function *)
(*         | Slipshow.Ast.S_block (Included (((fpath, b), _attrs), _meta)) -> *)
(*             let acc = Fpath.Map.add fpath b acc in *)
(*             Cmarkit.Folder.ret @@ Slipshow.Ast.Folder.continue_block f b acc *)
(*         | _ -> Cmarkit.Folder.default) *)
(*       ~inline:(fun _ acc _ -> Cmarkit.Folder.ret acc) *)
(*       () *)
(*   in *)
(*   let map = Cmarkit.Folder.fold_doc folder Fpath.Map.empty ast.doc in *)
(*   let () = *)
(*     Fpath.Map.iter *)
(*       (fun fpath _ -> Format.eprintf "Fpath = %a\n%!" Fpath.pp fpath) *)
(*       map *)
(*   in *)
(*   map *)

let diagnostics (uri : Linol.Lsp.Types.DocumentUri.t) (s : string) :
    Linol.Lsp.Types.Diagnostic.t list option Lwt.t =
  let file = Linol.Lsp.Types.DocumentUri.to_path uri in
  let file = Fpath.v file in
  Format.eprintf "Looking for diagnostics of %a\n%!" Fpath.pp file;
  let+ res = State.update_from_buffer file s in
  match res with
  | `No_changes -> None
  | `Update _ -> (
      let root = State.Rev_deps.get_root file in
      Format.eprintf "Root of %a is %a\n%!" Fpath.pp file Fpath.pp root;
      let open Slipshow in
      let parent, filename = Fpath.split_base root in
      let read_file = State.read_file parent in
      match read_file filename with
      | Error _ | Ok None -> None
      | Ok (Some (s, _)) ->
          let ({ Compile.ast = _; _ } as _v), errors =
            Compile.compile ~file:root ~read_file s
          in

          (* let _map = split_by_inclusion ast in *)
          (* Format.eprintf "Diagnostic of file: %a\n\n%!" Fpath.pp file; *)
          (* Format.eprintf "%a\n\n\n%!" Ast.Ast_printer.pp_bol *)
          (*   (`Block (Cmarkit.Doc.block ast.doc)); *)
          Some
            (List.concat_map
               (Diagnostic.of_error ~file:(Fpath.to_string file))
               errors))

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
      (* let () = *)
      (*   match wsf with *)
      (*   | Some (Some l) -> *)
      (*       List.iter *)
      (*         (fun ws -> *)
      (*           let open Linol_lwt.WorkspaceFolder in *)
      (*           Format.eprintf "name: %s uri: %s\n%!" ws.name *)
      (*             (Linol_lwt.DocumentUri.to_string ws.uri)) *)
      (*         l *)
      (*   | Some None -> Format.eprintf "Some but No workspace\n%!" *)
      (*   | None -> Format.eprintf "No workspace\n%!" *)
      (* in *)
      (* let () = *)
      (*   match uri with *)
      (*   | Some uri -> *)
      (*       Format.eprintf "Uri: %s\n%!" (Linol_lsp.Uri0.to_string uri) *)
      (*   | None -> Format.eprintf "No uri\n%!" *)
      (* in *)
      (* let () = *)
      (*   match pth with *)
      (*   | Some (Some path) -> Format.eprintf "Path: %s\n%!" path *)
      (*   | Some None -> Format.eprintf "Some but No path\n%!" *)
      (*   | None -> Format.eprintf "No path\n%!" *)
      (* in *)
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
                lwt_list_iter State.update_from_fs files)
          roots
      in
      let () =
        Format.eprintf "Here are the root of each markdown file\n%!";
        Hashtbl.iter
          (fun path paths ->
            Format.eprintf "%a -> [%s]\n%!" Fpath.pp path
              (String.concat " "
              @@ (Fpath.Set.to_list paths |> List.map Fpath.to_string)))
          State.Rev_deps.current
      in
      super#on_req_initialize ~notify_back params

    method! config_completion =
      Some (Linol_lwt.CompletionOptions.create ~triggerCharacters:[ "#" ] ())

    method! on_req_completion ~notify_back:_ ~id:_ ~uri:_ ~pos ~ctx:_
        ~workDoneToken:_ ~partialResultToken:_ _doc_state =
      (* let ( let* ) = Option.bind in *)
      (* let ( let+ ) x f = Option.map f x in *)
      let _ = pos in
      let res =
        (* let* ast = !current_ast in *)
        (* let+ () = *)
        (*   Current_ast.get_target pos ast.action_plan |> Option.map ignore *)
        (*   (\* Just as a way to test we are in the context of a target *\) *)
        (* in *)
        (* let all_ids = *)
        (*   Slipshow.Id_map.SMap.bindings ast.id_map |> List.map fst *)
        (* in *)
        (* let completions = *)
        (*   List.map *)
        (*     (fun id -> Linol_lwt.CompletionItem.create ~label:id ()) *)
        (*     all_ids *)
        (* in *)
        (* `List completions *)
        Some (`List [])
      in
      Lwt.return res

    method! on_req_definition ~notify_back:_ ~id:_ ~uri ~pos ~workDoneToken:_
        ~partialResultToken:_ _doc_state =
      (* let ( let* ) = Option.bind in *)
      (* let ( let+ ) x f = Option.map f x in *)
      (* let res = *)
      (*   let* ast = !current_ast in *)
      (*   let* id = Current_ast.get_target pos ast.action_plan in *)
      (*   let+ x = Slipshow.Id_map.SMap.find_opt id ast.id_map in *)
      (*   let meta = snd x.id in *)
      (*   let range = Diagnostic.linoloc_of_textloc (Cmarkit.Meta.textloc meta) in *)
      (*   let loc = Linol_lwt.Location.create ~range ~uri in *)
      (*   `Location [ loc ] *)
      (* in *)
      (* Lwt.return res *)
      let _ = (uri, pos) in
      Lwt.return None

    method! on_req_hover ~notify_back:_ ~id:_ ~uri:_ ~pos ~workDoneToken:_ _ :
        Linol_lwt.Hover.t option Lwt.t =
      (* let ( let* ) = Option.bind in *)
      (* let ( let+ ) x f = Option.map f x in *)
      (* let r = *)
      (*   let* ast = !current_ast in *)
      (*   let* tail_attrs = *)
      (*     let trail = Current_ast.get_leave pos ast.ast.doc in *)
      (*     trail.attribute *)
      (*   in *)
      (*   match tail_attrs with *)
      (*   | Key ((key, meta), _) | Value ((key, meta), _) -> *)
      (*       let+ (module X) = *)
      (*         List.find_opt *)
      (*           (fun (module X : Actions_arguments.S) -> key = X.on) *)
      (*           Actions_arguments.all_actions *)
      (*       in *)
      (*       let contents = *)
      (*         Linol_lwt.MarkupContent.create ~kind:Markdown ~value:X.doc *)
      (*       in *)
      (*       let contents = `MarkupContent contents in *)
      (*       let loc = Cmarkit.Meta.textloc meta in *)
      (*       let range = Diagnostic.linoloc_of_textloc loc in *)
      (*       Linol_lwt.Hover.create ~contents ~range () *)
      (*   | _ -> None *)
      (* in *)
      (* Lwt.return r *)
      let _ = pos in
      Lwt.return None

    method! config_modify_capabilities capabilities =
      let capabilities = super#config_modify_capabilities capabilities in
      {
        capabilities with
        documentHighlightProvider = Some (`Bool true);
        referencesProvider = Some (`Bool true);
        definitionProvider = Some (`Bool true);
        documentSymbolProvider = Some (`Bool true);
      }

    method private _on_doc ~(notify_back : Linol_lwt.Jsonrpc2.notify_back)
        (uri : Linol.Lsp.Types.DocumentUri.t) (contents : string) =
      (* let file = Linol.Lsp.Types.DocumentUri.to_path uri in *)
      (* State.update_from_buffer  *)
      (* match Hashtbl.find_opt opened_buffers file with *)
      (* | Some c when String.equal c contents -> Lwt.return_unit *)
      (* | _ -> *)
      (*     Hashtbl.replace opened_buffers file contents; *)
      let* diags = diagnostics uri contents in
      match diags with
      | None -> Lwt.return ()
      | Some diags -> notify_back#send_diagnostic diags

    method private on_req_document_highlight ~notify_back:_ ~id:_
        (params : Linol_lwt.DocumentHighlightParams.t) :
        Linol_lwt.DocumentHighlight.t list option Lwt.t =
      (* let res = *)
      (*   let ( let* ) = Option.bind in *)
      (*   let ( let+ ) x f = Option.map f x in *)
      (*   let* ast = !current_ast in *)
      (*   let* id = *)
      (*     let res1 = Current_ast.get_target params.position ast.action_plan in *)
      (*     match res1 with *)
      (*     | Some _ -> res1 *)
      (*     | None -> ( *)
      (*         let* tail_attrs = *)
      (*           let trail = Current_ast.get_leave params.position ast.ast.doc in *)
      (*           trail.attribute *)
      (*         in *)
      (*         match tail_attrs with Id (id, _) -> Some id | _ -> None) *)
      (*   in *)
      (*   let+ x = Slipshow.Id_map.SMap.find_opt id ast.id_map in *)
      (*   let loc_def = Cmarkit.Meta.textloc @@ snd x.id in *)
      (*   let loc_occ = x.rev in *)
      (*   let locs = loc_def :: loc_occ in *)
      (*   List.map *)
      (*     (fun loc -> *)
      (*       let range = Diagnostic.linoloc_of_textloc loc in *)
      (*       Linol_lwt.DocumentHighlight.create ~range ()) *)
      (*     locs *)
      (* in *)
      (* Lwt.return res *)
      let _ = params in
      Lwt.return None

    method! on_request_unhandled (type r) ~notify_back ~id
        (r : r Linol_lsp.Client_request.t) : r Lwt.t =
      match r with
      | Linol.Lsp.Client_request.TextDocumentHighlight params ->
          self#on_req_document_highlight ~notify_back ~id params
      | r -> super#on_request_unhandled ~notify_back ~id r

    method on_notif_doc_did_open ~notify_back d ~content : unit Linol_lwt.t =
      self#_on_doc ~notify_back d.uri content

    method on_notif_doc_did_change ~notify_back d _c ~old_content:_old
        ~new_content =
      self#_on_doc ~notify_back d.uri new_content

    method on_notif_doc_did_close ~notify_back:_ _d : unit Linol_lwt.t =
      Linol_lwt.return ()
  end

let run () =
  let s = new lsp_server in
  let server = Linol_lwt.Jsonrpc2.create_stdio ~env:() s in
  let task =
    let shutdown () = s#get_status = `ReceivedExit in
    Linol_lwt.Jsonrpc2.run ~shutdown server
  in
  match Linol_lwt.run task with
  | () -> ()
  | exception e ->
      let e = Printexc.to_string e in
      Printf.eprintf "error: %s\n%!" e;
      exit 1

let () = run ()
