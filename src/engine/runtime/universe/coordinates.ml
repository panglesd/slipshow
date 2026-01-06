type window = Global_state.Predef.window_coordinates = {
  x : float;
  y : float;
  scale : float;
}

let log_window { x; y; scale } =
  let s =
    Jv.obj
      [|
        ("x", Jv.of_float x); ("y", Jv.of_float y); ("scale", Jv.of_float scale);
      |]
  in
  Brr.Console.(log [ s ])

type element = { x : float; y : float; width : float; height : float }

let log_element { x; y; width; height } =
  let s =
    Jv.obj
      [|
        ("x", Jv.of_float x);
        ("y", Jv.of_float y);
        ("width", Jv.of_float width);
        ("height", Jv.of_float height);
      |]
  in
  Brr.Console.(log [ s ])
