(** Bindings to [@codemirror/collab], for collaborative editing through a
    central authority. *)

type config

val config : ?start_version:int -> ?client_id:string -> unit -> config
(** Configuration of the {!collab} extension.

    - [start_version] is the starting document version. Defaults to [0].
    - [client_id] is this client's identifying ID (see {!get_client_id}). Will
      be a randomly generated string if not provided. *)

val collab : ?config:config -> unit -> Extension.t
(** Create an instance of the collaborative editing plugin. *)

(** An update is a set of changes. *)
module Update : sig
  type t

  include Jv.CONV with type t := t

  val changes : t -> State.ChangeSet.t
  (** The changes made by this update. *)

  val client_id : t -> string
  (** The ID of the client who created this update. *)

  val make : changes:State.ChangeSet.t -> client_id:string -> t
  (** [make ~changes ~client_id] is the update made of [changes] by the client
      [client_id]. *)
end

val receive_updates :
  State.EditorState.t -> Update.t list -> State.Transaction.t
(** Create a transaction that represents a set of new updates received from the
    authority. Applying this transaction moves the state forward to adjust to
    the authority's view of the document. *)

val sendable_updates :
  State.EditorState.t -> (Update.t * State.Transaction.t) list
(** Returns the set of locally made updates that still have to be sent to the
    authority. Each update is paired with the transaction that created it. This
    may be useful if you want to send along metadata like timestamps. (But note
    that the updates may have been mapped in the meantime, whereas the
    transaction is just the original transaction that created them.) *)

val get_synced_version : State.EditorState.t -> int
(** Get the version up to which the collab plugin has synced with the central
    authority. *)

val get_client_id : State.EditorState.t -> string
(** Get this editor's collaborative editing client ID. *)
