open Code_mirror
open Lsp_client
open Brr
open Brr_webworkers

let basic_setup = Jv.get Jv.global "__CM__basic_setup" |> Extension.of_jv

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

let extension ?slipshow_js ?options ~errors_el preview_element =
  let module Lsp =
    Lspishow.Make
      (Worker_io)
      (struct
        let sleep = Js_of_ocaml_lwt.Lwt_js.sleep

        let start_preview :
            send_info:(string -> unit) ->
            to_lsp_server:(Proto.Client_to_server.t -> Roots.root -> unit) ->
            Server_types.roots ->
            unit =
         fun ~send_info:_ ~to_lsp_server roots ->
          let root =
            match snd roots () with
            | path :: _ -> fst roots path |> Option.get
            | _ -> failwith "TODO"
          in
          let state =
            Previewer.create_previewer ~include_speaker_view:false ~errors_el
              ~steal_focus:false ~can_save:false ~can_gui:false
              ~save_coordinate:(fun ~id:_ ~coord:_ -> ())
              ~goto_loc:(fun loc -> to_lsp_server (GotoLoc loc) root)
              preview_element
          in
          let rec loop () =
            let open Lwt.Infix in
            let open Lwt.Syntax in
            let* ev = Lwt_condition.wait root.condition in
            (match ev with
            | Update ->
                let root =
                  match snd roots () with
                  | path :: _ -> fst roots path |> Option.get
                  | _ -> failwith "TODO"
                in
                let content =
                  Slipshow.delayed_from_units ~has_speaker_view:false root.units
                in
                Previewer.preview_compiled state (content, "")
            | Control _ | ActivateGUI _ | DeActivateGUI | Notify _ -> ());
            loop ()
          in
          let _ = loop () in
          ()
      end)
  in
  let open Fut.Result_syntax in
  let worker = Worker.create (Jstr.v "workers/lsp_worker.bc.js") in
  let transport = worker_transport worker in
  let extensions = Extensions.language_server_extensions () in
  let client =
    let config =
      LSPClientConfig.create ~root_uri:"file:///workspace" ~extensions ()
    in
    LSPClient.create ~config ()
  in
  let client = LSPClient.connect client transport in
  let+ () = LSPClient.initializing client in
  let file_uri = "file:///workspace/main.ml" in
  let () =
    let ic = Worker_io.create_in_channel () in
    Lwt.async (fun () -> Lsp.run ic () ())
  in
  LSPClient.plugin client ~file_uri ~language_id:"ocaml" ()
