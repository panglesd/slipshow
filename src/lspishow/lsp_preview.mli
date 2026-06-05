val server_promise : unit Lwt.t option ref
val server_port : int option ref
val initialize : notify_back:Linol_lwt.Jsonrpc2.notify_back -> unit -> unit
