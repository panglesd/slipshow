type undo = unit -> unit Fut.t
type 'a t = ('a * undo) Fut.t

val bind : ('a -> 'b t) -> 'a t -> 'b t
val return : ?undo:undo -> 'a -> 'a t
val discard : 'a t -> 'a Fut.t

module Syntax : sig
  val ( let> ) : 'a t -> ('a -> 'b t) -> 'b t
end
