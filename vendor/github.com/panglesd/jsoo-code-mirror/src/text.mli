type t

include Jv.CONV with type t := t

module Line : sig
  type t
  (** A text line *)

  val from : t -> int
  (** Position of the start of the line *)

  val to_ : t -> int
  (** Position at the end of the line before the line break *)

  val number : t -> int
  (** Line's number (1-based) *)

  val text : t -> Jstr.t
  (** Line's text *)

  val length : t -> int
  (** The length of the line *)
end

val length : t -> int
(** Length of the text *)

val line : int -> t -> Line.t
val to_jstr_array : t -> Jstr.t array
