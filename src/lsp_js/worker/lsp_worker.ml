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
      (* let root = *)
      (*   match snd roots () with *)
      (*   | path :: _ -> fst roots path |> Option.get *)
      (*   | _ -> failwith "TODO" *)
      (* in *)
      (* let state = *)
      (*   Previewer.create_previewer ~include_speaker_view:false ~errors_el *)
      (*     ~steal_focus:false ~can_save:false ~can_gui:false *)
      (*     ~save_coordinate:(fun ~id:_ ~coord:_ -> ()) *)
      (*     ~goto_loc:(fun loc -> to_lsp_server (GotoLoc loc) root) *)
      (*     preview_element *)
      (* in *)
      (* let rec loop () = *)
      (*   let open Lwt.Syntax in *)
      (*   let* ev = Lwt_condition.wait root.condition in *)
      (*   (match ev with *)
      (*   | Update -> *)
      (*       let root = *)
      (*         match snd roots () with *)
      (*         | path :: _ -> fst roots path |> Option.get *)
      (*         | _ -> failwith "TODO" *)
      (*       in *)
      (*       let content = *)
      (*         Slipshow.delayed_from_units ~has_speaker_view:false root.units *)
      (*       in *)
      (*       Previewer.preview_compiled state (content, "") *)
      (*   | Control _ | ActivateGUI _ | DeActivateGUI | Notify _ -> ()); *)
      (*   loop () *)
      (* in *)
      (* let _ = loop () in *)
      (* () *)
    end)

class lsp_server =
  object
    inherit L.lsp_server as super

    method! on_notif_doc_did_open ~notify_back doc ~content : unit Lwt.t =
      let open Lwt.Syntax in
      let uri = doc.uri in
      let file = uri |> Linol_lsp.Lsp.Uri.to_path |> Fpath.v in
      let+ () = super#on_notif_doc_did_open ~notify_back doc ~content in
      match Hashtbl.find_opt Preview.ports file with
      | None -> ()
      | Some (_, cond) -> Lwt_condition.broadcast cond ()
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
            (data |> Jv.to_string |> Lsp.Uri.of_string |> Lsp.Uri.to_path
           |> Fpath.v)
            port
        in
        Brr_io.Message.Port.start port
    | [] -> Worker_io.push_message ic (Jv.to_string data)
  in
  let _unlistener = Ev.listen Brr_io.Message.Ev.message on_message G.target in
  let lsp_server = new lsp_server in
  Lwt.async (fun () -> L.run lsp_server ic () ())
