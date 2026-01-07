let set_coord (global : Global_state.t) v = global.coordinates <- v

(* We do this trick instead of starting with coordinates being directly the
   "starting" value since [width] and [height] may not have been set correctly
   at the time the ref is initialized.

   Imperative programming is confusing! *)
let get_coord (global : Global_state.t) = global.coordinates
