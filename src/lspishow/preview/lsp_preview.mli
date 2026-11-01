(** The native preview server, started by the LSP server. *)

val server_promise : unit -> unit Lwt.t option
val server_port : unit -> int option

val initialize :
  send_info:(string -> unit) ->
  to_lsp_server:(Proto.Client_to_server.t -> Server_types.root -> unit) ->
  Server_types.roots ->
  unit
(** [initialize ~send_info ~to_lsp_server roots] starts the preview server (if
    not already started), serving [roots]. [send_info] is used to report
    information (such as the port) to the user. *)
