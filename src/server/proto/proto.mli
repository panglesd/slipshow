type 'a versionned = { content : 'a; version : string }

module type Serializing := sig
  type t

  val to_string : t -> string
  val of_string : string -> t option
end

module Client_to_server : sig
  type t =
    | Ping
    | UpdateFrom of string
    | Save_drawing of string * string (* path * content *)

  include Serializing with type t := t
end

module Server_to_client : sig
  type movement = Forward | Backward
  type control = Movement of movement

  type t =
    | Pong
    | Update of (Slipshow.delayed * string) versionned
    | Control of control
    | Saved of string
    | Notify of string

  include Serializing with type t := t
end
