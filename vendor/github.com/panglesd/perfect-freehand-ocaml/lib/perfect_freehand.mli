(** TODO *)

module Point : sig
  type t

  val v : float -> float -> t
  (* TODO: pressure *)

  val get_x : t -> float
  val get_y : t -> float

  (**/**)

  include Jv.CONV with type t := t

  (**/**)
end

module Options : sig
  type t

  val v :
    ?size:float ->
    ?thinning:float ->
    ?smoothing:float ->
    ?streamline:float ->
    ?last:bool ->
    unit ->
    t

  val size : t -> float option
  val thinning : t -> float option
  val smoothing : t -> float option
  val streamline : t -> float option
  val last : t -> bool option

  (**/**)

  include Jv.CONV with type t := t

  (**/**)
end

val get_stroke : ?options:Options.t -> Point.t list -> Point.t list
(* TODO: options *)

val get_svg_path_from_stroke : Point.t list -> Jstr.t
