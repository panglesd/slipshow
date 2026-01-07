open Coordinates

val elem : Global_state.t -> Window.t -> Brr.El.t -> element

module Window : sig
  val focus : Global_state.t -> current:window -> element list -> window
  val enter : Global_state.t -> element -> window

  val up :
    Global_state.t -> ?margin:float -> current:window -> element -> window

  val center : Global_state.t -> current:window -> element -> window

  val down :
    Global_state.t -> ?margin:float -> current:window -> element -> window
end
