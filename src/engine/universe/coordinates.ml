type window = { x : float; y : float; scale : float }

let log_window { x; y; scale } =
  let s = Format.sprintf "{ x = %f; y = %f; scale = %f }" x y scale in
  Brr.Console.(log [ s ])

type element = { x : float; y : float; width : float; height : float }

let log_element { x; y; width; height } =
  let s =
    Format.sprintf "{ x = %f; y = %f; width = %f; height = %f }" x y width
      height
  in
  Brr.Console.(log [ s ])
