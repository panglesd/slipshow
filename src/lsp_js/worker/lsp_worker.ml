open Brr

module L =
  Lspishow.Make
    (Worker_io)
    (struct
      let sleep = Js_of_ocaml_lwt.Lwt_js.sleep

      let start_preview :
          send_info:(string -> unit) ->
          to_lsp_server:(Proto.Client_to_server.t -> Roots.root -> unit) ->
          Server_types.roots ->
          unit =
        Preview.start
    end)

class lsp_server =
  object
    inherit L.lsp_server as super

    method! on_notif_doc_did_open ~notify_back doc ~content : unit Lwt.t =
      let open Lwt.Syntax in
      let uri = doc.uri in
      let file = uri |> Linol_lsp.Lsp.Uri.to_path |> Fpath.v in
      let+ () = super#on_notif_doc_did_open ~notify_back doc ~content in
      let conds = Hashtbl.find_all Preview.ports file in
      List.iter (fun (_, cond) -> Lwt_condition.broadcast cond ()) conds
  end

let () =
  let ic = Worker_io.create_in_channel () in
  let on_message ev =
    let ev = Ev.as_type ev in
    let data : Jv.t = Brr_io.Message.Ev.data ev in
    match Brr_io.Message.Ev.ports ev with
    | port :: _ ->
        let () =
          Preview.connect
            (data |> Jv.to_string |> Linol_lsp.Lsp.Uri.of_string
           |> Linol_lsp.Lsp.Uri.to_path |> Fpath.v)
            port
        in
        Brr_io.Message.Port.start port
    | [] -> Worker_io.push_message ic (Jv.to_string data)
  in
  let _unlistener = Ev.listen Brr_io.Message.Ev.message on_message G.target in
  let lsp_server = new lsp_server in
  Lwt.async (fun () -> L.run lsp_server ic () ())
