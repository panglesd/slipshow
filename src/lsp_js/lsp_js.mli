type server

val create_server : ?root_uri:string -> string -> server Fut.or_error

val extension : server -> path:Fpath.t -> Code_mirror.Extension.t
(** The path needs to be relative. It will be relativize to the root uri *)

val preview : errors_el:Brr.El.t -> Brr.El.t -> server -> path:Fpath.t -> unit

