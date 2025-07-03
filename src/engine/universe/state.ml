open Constants

let coordinates =
  ref { Coordinates.x = width () /. 2.; y = height () /. 2.; scale = 1. }

let set_coord v = coordinates := v
let get_coord () = !coordinates
