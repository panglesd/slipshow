type window = { x : float; y : float; scale : float }
(** Represent the position of the window. Since scaling happens with origin the
    center of the screen, x and y have to to the coordinate of the center as
    well.

    This does not use {!elem_coordinate} since the window has a fixed ratio,
    defined elsewhere, and we do not want to be able to represent invalid state.
*)

type element = { x : float; y : float; width : float; height : float }
(** Represent the position of an element in the universe. To ease interaction
    with the window coordinates, x and y are the center of the element. *)

val log_window : window -> unit
val log_element : element -> unit
val get : Brr.El.t -> element

module Window_of_elem : sig
  val focus : current:window -> element list -> window
  val enter : element -> window
  val up : ?margin:float -> current:window -> element -> window
  val center : current:window -> element -> window
  val down : ?margin:float -> current:window -> element -> window
end
