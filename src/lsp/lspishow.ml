type state_after_processing = string

let process_some_input_file (file_contents : string) : state_after_processing =
  file_contents

let linoloc_of_textloc (loc : Cmarkit.Textloc.t) =
  let start =
    let line, byte_pos = Cmarkit.Textloc.first_line loc in
    let character = Cmarkit.Textloc.first_byte loc - byte_pos in
    Linol_lwt.Position.create ~character ~line
  in
  let end_ =
    let line, byte_pos = Cmarkit.Textloc.last_line loc in
    let character = Cmarkit.Textloc.last_byte loc - byte_pos in
    Linol_lwt.Position.create ~character ~line
  in
  Linol_lwt.Range.create ~end_ ~start

let diagnostics cond (uri : Linol.Lsp.Types.DocumentUri.t)
    (s : state_after_processing) : Linol.Lsp.Types.Diagnostic.t list =
  let md, errors =
    let open Slipshow in
    let frontmatter = Frontmatter.empty in
    let read_file = fun _ -> Ok None in
    let Frontmatter.Resolved frontmatter, s =
      let ( let* ) x f =
        match x with
        | Ok x -> f x
        | Error (`Msg err) ->
            Logs.err (fun m -> m "Failed to parse the frontmatter: %s" err);
            (frontmatter, s)
      in
      match Frontmatter.extract s with
      | None -> (frontmatter, s)
      | Some (yaml, s) ->
          let* txt_frontmatter = Frontmatter.of_string yaml in
          let to_asset = Asset.of_string ~read_file in
          let txt_frontmatter = Frontmatter.resolve txt_frontmatter ~to_asset in
          let frontmatter = Frontmatter.combine txt_frontmatter frontmatter in
          (frontmatter, s)
    in
    let toplevel_attributes =
      frontmatter.toplevel_attributes
      |> Option.value ~default:Frontmatter.Default.toplevel_attributes
    in
    let file = Linol.Lsp.Types.DocumentUri.to_string uri in
    let md, errors =
      Compile.compile ~file ~attrs:toplevel_attributes ~read_file s
    in
    let content = Slipshow.Renderers.to_html_string md in
    let has = Slipshow.Has.find_out md in
    let dimension =
      frontmatter.dimension
      |> Option.value ~default:Frontmatter.Default.dimension
    in
    let css_links = frontmatter.css_links in
    let js_links = frontmatter.js_links in
    let theme =
      match frontmatter.theme with
      | None -> Frontmatter.Default.theme
      | Some (`Builtin _ as x) -> x
      | Some (`External x) ->
          let asset = Asset.of_string ~read_file x in
          `External asset
    in
    let math_link = frontmatter.math_link in
    ( Slipshow.embed_in_page ~slipshow_js:None ~dimension ~has ~math_link ~theme
        ~css_links ~js_links content,
      errors )
  in
  Lwt_condition.broadcast cond (Proto.Update (Slipshow.delayed_to_string md));
  let diagnostic_of_error (e : Slipshow.Errors.t) =
    let range = linoloc_of_textloc e.loc in
    let message = Format.asprintf "%a" Slipshow.Errors.Error.pp e.error in
    Linol.Lsp.Types.Diagnostic.create ~message:(`String message) ~range ()
  in

  List.map diagnostic_of_error errors

class lsp_server cond =
  object (self)
    inherit Linol_lwt.Jsonrpc2.server

    (* one env per document *)
    val buffers
        : (Linol.Lsp.Types.DocumentUri.t, state_after_processing) Hashtbl.t =
      Hashtbl.create 32

    method! config_completion =
      Some
        {
          allCommitCharacters = None;
          completionItem = None;
          resolveProvider = Some true;
          triggerCharacters = Some [ "."; "#" ];
          workDoneProgress = None;
        }

    method! on_req_completion ~notify_back:_ ~id:_ ~uri:_ ~pos:_ ~ctx:_
        ~workDoneToken:_ ~partialResultToken:_ (_ : Linol.Server.doc_state) =
      let comp = Linol_lwt.CompletionItem.create ~label:"Impossible-days" () in
      Linol_lwt.return (Some (`List [ comp ]))

    method spawn_query_handler f = Linol_lwt.spawn f

    (* We define here a helper method that will:
       - process a document
       - store the state resulting from the processing
       - return the diagnostics from the new state
    *)
    method private _on_doc ~(notify_back : Linol_lwt.Jsonrpc2.notify_back)
        (uri : Linol.Lsp.Types.DocumentUri.t) (contents : string) =
      let new_state = process_some_input_file contents in
      Hashtbl.replace buffers uri new_state;
      let diags = diagnostics cond uri new_state in
      notify_back#send_diagnostic diags

    (* We now override the [on_notify_doc_did_open] method that will be called
       by the server each time a new document is opened. *)
    method on_notif_doc_did_open ~notify_back d ~content : unit Linol_lwt.t =
      Format.fprintf Format.err_formatter "Hello";
      self#_on_doc ~notify_back d.uri content

    (* Similarly, we also override the [on_notify_doc_did_change] method that will be called
       by the server each time a new document is opened. *)
    method on_notif_doc_did_change ~notify_back d _c ~old_content:_old
        ~new_content =
      Format.fprintf Format.err_formatter "Hello2";

      (* send notify_back _old *)
      self#_on_doc ~notify_back d.uri new_content

    (* On document closes, we remove the state associated to the file from the global
       hashtable state, to avoid leaking memory. *)
    method on_notif_doc_did_close ~notify_back:_ d : unit Linol_lwt.t =
      Hashtbl.remove buffers d.uri;
      Linol_lwt.return ()

    method! on_req_execute_command ~notify_back:_ ~id:_ ~workDoneToken:_
        (c : string) (_args : Yojson.Safe.t list option) :
        Yojson.Safe.t Linol_lwt.t =
      (match c with
      | "slipshow.forward" -> Lwt_condition.broadcast cond Proto.GoForward
      | "slipshow.backward" -> Lwt_condition.broadcast cond Proto.GoBackward
      | _ -> ());

      (* let () = *)
      (*   Lwt_condition.broadcast cond Proto.GoForward; *)
      (*   (\* Write message to file *\) *)
      (*   let oc = open_out "/tmp/msg" in *)
      (*   (\* create or truncate file, return channel *\) *)
      (*   Printf.fprintf oc "%s: %s\n" "executeCommandCalled" c; *)
      (*   (\* write something *\) *)
      (*   close_out oc *)
      (* in *)
      Linol_lwt.return `Null
    (** Execute a command with given arguments.
        @since 0.3 *)
  end

(* Main code
   This is the code that creates an instance of the lsp server class
   and runs it as a task. *)
let run () =
  let cond = Lwt_condition.create () in
  let server_promise = Lspserve.do_serve ~port:8080 cond in
  let s = new lsp_server cond in
  let server = Linol_lwt.Jsonrpc2.create_stdio ~env:() s in
  let task =
    let shutdown () = s#get_status = `ReceivedExit in
    Linol_lwt.Jsonrpc2.run ~shutdown server
  in
  let main = Lwt.pick [ task; server_promise ] in
  match Linol_lwt.run main with
  | () -> ()
  | exception e ->
      let e = Printexc.to_string e in
      Printf.eprintf "error: %s\n%!" e;
      exit 1

(* Finally, we actually run the server *)
let () = run ()
