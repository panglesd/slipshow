type server

val create_server : string -> server
val extension : server -> uri:string -> Code_mirror.Extension.t Fut.or_error
val preview : errors_el:Brr.El.t -> Brr.El.t -> server -> uri:string -> unit

