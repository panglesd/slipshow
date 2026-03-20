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
    let (_md, _htbl_include), errors =
      Compile.compile ~loc_offset ~file ~attrs:toplevel_attributes ~read_file
        ~fm:(Frontmatter.Resolved frontmatter) rest
    in
    fm_errors @ errors
  in
  List.concat_map Diagnostic.of_error errors

class lsp_server =
  object (self)
    inherit Linol_lwt.Jsonrpc2.server
    method spawn_query_handler f = Linol_lwt.spawn f

    method private _on_doc ~(notify_back : Linol_lwt.Jsonrpc2.notify_back)
        (uri : Linol.Lsp.Types.DocumentUri.t) (contents : string) =
      let diags = diagnostics uri contents in
      notify_back#send_diagnostic diags

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
