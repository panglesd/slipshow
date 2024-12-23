let coordinates =
  ref
    {
      Coordinates.x = Constants.width /. 2.;
      y = Constants.height /. 2.;
      scale = 1.;
    }

let set_coord v = coordinates := v
let get_coord () = !coordinates
