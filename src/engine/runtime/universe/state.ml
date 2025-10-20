open Constants

let coordinates = ref None
let set_coord v = coordinates := Some v

let get_coord () =
  match !coordinates with
  | None -> { Coordinates.x = width () /. 2.; y = height () /. 2.; scale = 1. }
  | Some v -> v
