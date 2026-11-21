type 'a conv = { to_jv : 'a -> Jv.t; of_jv : Jv.t -> 'a }
(** A value representing a conversion to and from a Javascript value *)

type 'a t
(** A typed {! Jv} value.

    Some values in the codemirror API have an underlying value associated with
    them. *)

val conv : ('a -> Jv.t) -> (Jv.t -> 'a) -> 'a conv
(** Make a new conversion value *)

val map_jv : 'a t -> (Jv.t -> Jv.t) -> 'a t

module type CONV = sig
  type 'a t

  val to_jv : 'a t -> Jv.t
  val of_jv : 'a conv -> Jv.t -> 'a t
  val conv : 'a t -> 'a conv
  val any : 'a t -> Jv.t t
end

module Id : sig
  val of_jv : 'a conv -> Jv.t -> 'a t
  val to_jv : 'a t -> Jv.t
  val conv : 'a t -> 'a conv
  val any : 'a t -> Jv.t t
end
