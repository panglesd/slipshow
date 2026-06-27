val server_promise : unit -> unit Lwt.t option
val server_port : unit -> int option
val initialize : notify_back:Linol_lwt.Jsonrpc2.notify_back -> unit -> unit
