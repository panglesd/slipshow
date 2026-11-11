open Lwt.Syntax

let ports : (Fpath.t, Brr_io.Message.Port.t * unit Lwt_condition.t) Hashtbl.t =
  Hashtbl.create 10

(* let server_promise = ref None *)
let roots = ref (fun _ -> None)
let to_lsp_server = ref None
let send_info = ref (fun _ -> ())

let listen_to ~port f =
  Brr.Ev.listen Brr_io.Message.Ev.message f (Brr_io.Message.Port.as_target port)

let send_event port c =
  let c = Proto.Server_to_client.to_string c in
  Brr_io.Message.Port.post port c

let pong port = send_event port Pong
let saved port s = send_event port (Saved (Fpath.to_string s))
let notify port s = send_event port (Notify s)
let update port u = send_event port (Update u)

let send_news (file : Fpath.t) (root : Server_types.root) port =
  let rec send () =
    let* event = Lwt_condition.wait root.condition in
    (* We reload root to get the updated value *)
    let root = !roots file in
    match root with
    | None ->
        Brr.Console.(error [ "Something unexpected happened" ]);
        send ()
    | Some root ->
        send_event port (Preview_protocol.of_event root event);
        send ()
  in
  send ()

let get_news fpath port =
  let get_request : Brr_io.Message.Ev.t Brr.Ev.t -> unit =
   fun ev ->
    match !roots fpath with
    | None -> ()
    | Some root -> (
        let ev = Brr.Ev.as_type ev in
        let data = Brr_io.Message.Ev.data ev in
        let msg = Proto.Client_to_server.of_string data in
        match msg with
        | None ->
            Brr.Console.(error [ "Something unexpected happened in get_news" ])
        | Some msg -> (
            let () =
              match !to_lsp_server with
              | None -> ()
              | Some to_lsp_server -> to_lsp_server msg root
            in
            match msg with
            | Ping -> pong port
            | UpdateFrom version ->
                if not @@ String.equal version root.version then
                  send_event port (Preview_protocol.update root)
                else ()
            | Save_drawing _ -> ()
            | GotoLoc _ | Save_gui_position _ -> pong port))
  in
  listen_to ~port get_request

let connect fpath port =
  let cond = Lwt_condition.create () in
  Hashtbl.add ports fpath (port, cond);
  let _unlisten : Brr.Ev.listener = get_news fpath port in
  let _ =
    let rec get_root () =
      match !roots fpath with
      | None ->
          let* () = Lwt_condition.wait cond in
          get_root ()
      | Some (root : Server_types.root) -> Lwt.return root
    in
    let+ root = get_root () in
    send_event port (Preview_protocol.update root);
    let _send : unit Lwt.t = send_news fpath root port in
    ()
  in
  ()

let start :
    send_info:(string -> unit) ->
    to_lsp_server:(Proto.Client_to_server.t -> Roots.root -> unit) ->
    Server_types.roots ->
    unit =
 fun ~send_info:si ~to_lsp_server:z rs ->
  to_lsp_server := Some z;
  send_info := si;
  roots := fst rs
