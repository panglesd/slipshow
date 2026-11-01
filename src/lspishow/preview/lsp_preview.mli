val server_promise : unit -> unit Lwt.t option
val server_port : unit -> int option

val initialize :
  send_info:(string -> unit) ->
  to_lsp_server:(Proto.Client_to_server.t -> Roots.root -> unit) ->
  unit ->
  unit
