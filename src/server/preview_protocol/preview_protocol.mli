(** The server side of the preview protocol, independent of the transport (HTTP
    long-polling for the native server, [postMessage] for the web worker). *)

val update : Server_types.root -> Proto.Server_to_client.t
(** [update root] is the message updating the preview with the content of
    [root]. *)

val of_event :
  Server_types.root ->
  Server_types.to_server ->
  Proto.Server_to_client.t
(** [of_event ~current_root event] is the message to send to the preview when
    [event] is broadcast on a root's condition. For an [Update], the content is
    taken from [current_root ()], and [None] is returned if it does not
    exist. *)
