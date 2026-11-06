(** The client side of the preview protocol, independent of the transport. *)

val handle_message : Previewer.previewer -> Proto.Server_to_client.t -> unit
(** [handle_message previewer msg] applies a message from the server to
    [previewer]. *)
