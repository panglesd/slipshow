open Lwt.Syntax

let server_promise = ref None
let server_port = ref None

let initialize ~send_info ~to_lsp_server () =
  let send_info fmt = Format.kasprintf send_info fmt in
  let root_htbl () =
    match Config.Refresh.when_ () with
    | Save -> Roots.saved
    | Edit -> Roots.buffers
    | Never -> Hashtbl.create 0
  in
  let roots_state x =
    let htbl = root_htbl () in
    Hashtbl.find_opt htbl x
  in
  let roots_list () =
    let htbl = root_htbl () in
    Hashtbl.to_seq_keys htbl |> List.of_seq
  in
  let port0 = 8080 in
  let rec loop port =
    server_port := Some port;
    let to_cancel =
      let+ () = Lwt_unix.sleep 1.0 in
      if !server_port = Some port then
        send_info "Starting preview server on port %d" port
      else send_info "Port %d appears already used" port
    in
    let* try_port =
      Slipshow_server.Server.do_serve ~port ~to_lsp_server:(Some to_lsp_server)
        (roots_state, roots_list)
    in
    match try_port with
    | Ok () -> Lwt.return_unit
    | Error `Addr_in_use ->
        let port = port + 1 in
        Lwt.cancel to_cancel;
        if port - port0 > 100 then (
          server_port := None;
          let () =
            send_info
              "Tried 100 ports, starting from %d, none of them appeared usable"
              port0
          in
          Lwt.return_unit)
        else loop port
  in
  loop port0

let initialize ~send_info ~to_lsp_server () =
  match !server_promise with
  | None ->
      let lwt = initialize ~send_info ~to_lsp_server () in
      server_promise := Some lwt
  | Some _ -> ()

let server_promise () = !server_promise
let server_port () = !server_port
