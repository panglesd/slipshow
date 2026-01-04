type config

val config : ?start_version:int -> ?clientID:string -> unit -> config
val collab : ?config:config -> unit -> Extension.t

module Update : sig
  type t

  val changes : t -> Editor.ChangeSet.t
  val clientID : t -> string
  val make : Editor.ChangeSet.t -> string -> t
end

val receiveUpdates :
  Editor.State.t -> Update.t list -> Editor.State.Transaction.t

val sendableUpdates :
  Editor.State.t -> (Update.t * Editor.State.Transaction.t) list

val getSyncedVersion : Editor.State.t -> int
val getClientID : Editor.State.t -> string
