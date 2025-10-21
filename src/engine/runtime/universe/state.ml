open Constants

let coordinates = ref None
let set_coord v = coordinates := Some v

(* We do this trick instead of starting with coordinates being directly the
   "starting" value since [width] and [height] may not have been set correctly
   at the time the ref is initialized.

   Imperative programming is confusing! *)
let get_coord () =
  match !coordinates with
  | None -> { Coordinates.x = width () /. 2.; y = height () /. 2.; scale = 1. }
  | Some v -> v
