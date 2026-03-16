type 'a versionned = { content : 'a; version : string }
type t = Pong | Update of string versionned

val to_string : t -> string
val of_string : string -> t option
