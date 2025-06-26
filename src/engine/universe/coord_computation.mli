open Coordinates

val elem : Brr.El.t -> element

module Window : sig
  val focus : current:window -> element list -> window
  val enter : element -> window
  val up : ?margin:float -> current:window -> element -> window
  val center : current:window -> element -> window
  val down : ?margin:float -> current:window -> element -> window
end
