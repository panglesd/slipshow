open Coordinates

val elem : Window.t -> Brr.El.t -> element

module Window : sig
  val focus : ?margin:float -> current:window -> element list -> window
  val enter : element -> window
  val h_enter : element -> window
  val up : ?margin:float -> current:window -> element -> window
  val center : current:window -> element -> window
  val down : ?margin:float -> current:window -> element -> window
  val right : ?margin:float -> current:window -> element -> window
  val left : ?margin:float -> current:window -> element -> window
end
