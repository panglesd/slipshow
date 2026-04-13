module Io = struct
  let read input =
    try
      match input with
      | `Stdin -> Ok In_channel.(input_all stdin)
      | `File f -> Bos.OS.File.read f
    with exn -> Error (`Msg (Printexc.to_string exn))
end

let read_file parent s =
  let ( // ) = Fpath.( // ) in
  let ( let+ ) a b = Result.map b a in
  let fp = Fpath.normalize @@ (parent // s) in
  let+ res = Io.read (`File fp) in
  Some res

let current_ast = ref None

let diagnostics (uri : Linol.Lsp.Types.DocumentUri.t) (s : string) :
    Linol.Lsp.Types.Diagnostic.t list =
  let errors =
    let file = Linol.Lsp.Types.DocumentUri.to_string uri in
    let file =
      let prefix = "file://" in
      if String.starts_with ~prefix file then
        String.sub file (String.length prefix)
          (String.length file - String.length prefix)
      else file
    in
    let open Slipshow in
    let frontmatter = Frontmatter.empty in
    let read_file = read_file Fpath.(parent @@ v file) in
    let (Frontmatter.Resolved frontmatter, rest, loc_offset), fm_errors =
      Diagnosis.with_ @@ fun () ->
      match Frontmatter.extract s with
      | None -> (frontmatter, s, (0, 0))
      | Some { frontmatter = f; rest; rest_offset; fm_offset } ->
          let txt_frontmatter = Frontmatter.of_string file fm_offset f in
          let to_asset = Asset.of_string ~read_file in
          let txt_frontmatter = Frontmatter.resolve txt_frontmatter ~to_asset in
          let frontmatter = Frontmatter.combine txt_frontmatter frontmatter in
          (frontmatter, rest, rest_offset)
    in
    let toplevel_attributes =
      frontmatter.toplevel_attributes
      |> Option.value ~default:Frontmatter.Toplevel_attributes.default
    in
    let ({ Compile.ast = md; _ } as v), errors =
      Compile.compile ~loc_offset ~file ~attrs:toplevel_attributes ~read_file
        ~fm:(Frontmatter.Resolved frontmatter) rest
    in
    Format.eprintf "%a" Ast.Ast_printer.pp_bol
      (`Block (Cmarkit.Doc.block md.doc));
    current_ast := Some v;
    fm_errors @ errors
  in
  List.concat_map Diagnostic.of_error errors

class lsp_server =
  object (self)
    inherit Linol_lwt.Jsonrpc2.server as super
    method spawn_query_handler f = Linol_lwt.spawn f
    method! config_hover = Some (`Bool true)
    method! config_definition = Some (`Bool true)

    method! config_completion =
      Some (Linol_lwt.CompletionOptions.create ~triggerCharacters:[ "#" ] ())

    method! on_req_completion ~notify_back:_ ~id:_ ~uri:_ ~pos ~ctx:_
        ~workDoneToken:_ ~partialResultToken:_ _doc_state =
      let ( let* ) = Option.bind in
      let ( let+ ) x f = Option.map f x in
      let res =
        let* ast = !current_ast in
        let+ () =
          match Current_ast.get_target pos ast.action_plan with
          | Some _ -> Some ()
          | None -> (
              let pos =
                { pos with character = Int.max 0 (pos.character - 1) }
              in
              match Current_ast.get_target pos ast.action_plan with
              | Some _ -> Some ()
              | None -> None)
        in
        (* Line above just as a way to test we are in the context of a target *)
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
      let res =
        let* ast = !current_ast in
        let* id = Current_ast.get_target pos ast.action_plan in
        let+ x = Slipshow.Id_map.SMap.find_opt id ast.id_map in
        let meta = snd x.id in
        let range = Diagnostic.linoloc_of_textloc (Cmarkit.Meta.textloc meta) in
        let loc = Linol_lwt.Location.create ~range ~uri in
        `Location [ loc ]
      in
      Lwt.return res

    method! on_req_hover ~notify_back:_ ~id:_ ~uri:_ ~pos ~workDoneToken:_ _ :
        Linol_lwt.Hover.t option Lwt.t =
      let ( let* ) = Option.bind in
      let ( let+ ) x f = Option.map f x in
      let r =
        let* ast = !current_ast in
        let* tail_attrs =
          let trail = Current_ast.get_leave pos ast.ast.doc in
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

    method private _on_doc ~(notify_back : Linol_lwt.Jsonrpc2.notify_back)
        (uri : Linol.Lsp.Types.DocumentUri.t) (contents : string) =
      Format.eprintf "error%!";
      let diags = diagnostics uri contents in
      notify_back#send_diagnostic diags

    method private on_req_document_highlight ~notify_back:_ ~id:_
        (params : Linol_lwt.DocumentHighlightParams.t) :
        Linol_lwt.DocumentHighlight.t list option Lwt.t =
      let res =
        let ( let* ) = Option.bind in
        let ( let+ ) x f = Option.map f x in
        let* ast = !current_ast in
        let* id =
          let res1 = Current_ast.get_target params.position ast.action_plan in
          match res1 with
          | Some _ -> res1
          | None -> (
              let* tail_attrs =
                let trail = Current_ast.get_leave params.position ast.ast.doc in
                trail.attribute
              in
              match tail_attrs with Id (id, _) -> Some id | _ -> None)
        in
        let+ x = Slipshow.Id_map.SMap.find_opt id ast.id_map in
        let loc_def = Cmarkit.Meta.textloc @@ snd x.id in
        let loc_occ = x.rev in
        let locs = loc_def :: loc_occ in
        List.map
          (fun loc ->
            let range = Diagnostic.linoloc_of_textloc loc in
            Linol_lwt.DocumentHighlight.create ~range ())
          locs
      in
      Lwt.return res

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
