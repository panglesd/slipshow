type undo = unit -> unit Fut.t
type 'a t = ('a * undo) Fut.t

val bind : ('a -> 'b t) -> 'a t -> 'b t
val return : ?undo:undo -> 'a -> 'a t
val discard : 'a t -> 'a Fut.t

module Syntax : sig
  val ( let> ) : 'a t -> ('a -> 'b t) -> 'b t
end

module Browser = Browser_

module List : sig
  val iter : ('a -> unit t) -> 'a list -> unit t
end

module Stack : sig
  val push : 'a -> 'a Stack.t -> unit t
  (** [push x s] adds the element [x] at the top of stack [s]. *)

  val pop_opt : 'a Stack.t -> 'a option t
  (** [pop s] removes and returns the topmost element in stack [s], or returns
      [None] if the stack is empty. *)

  val peek : 'a Stack.t -> 'a option
  (** [pop s] returns the topmost element in stack [s], or returns [None] if the
      stack is empty. *)
end
