val server_promise : unit -> unit Lwt.t option
val server_port : unit -> int option

val initialize :
  notify_back:Linol_lwt.Jsonrpc2.notify_back ->
  to_lsp_server:(Proto.Client_to_server.t -> Roots.root -> unit) ->
  unit ->
  unit
