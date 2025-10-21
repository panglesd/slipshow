(** Be very careful when using this that the width and height need to have been
    initialized. Otherwise, they have their default value, which is likely
    wrong.

    If you use them in a function, that's probably right: setting them is one of
    the first thing slipshow does. What can go wrong is if we access them as a
    toplevel. See [universe/state.ml] for an example.

    Imperative programming is confusing! *)

val set_width : float -> unit
val set_height : float -> unit
val width : unit -> float
val height : unit -> float
