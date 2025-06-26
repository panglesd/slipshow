open Coordinates
open Constants

let elem window elem =
  let get_coord elem =
    let x = Brr.El.bound_x elem and y = Brr.El.bound_y elem in
    let x = x -. Window.bound_x window and y = y -. Window.bound_y window in
    let width, height = (Brr.El.bound_w elem, Brr.El.bound_h elem) in
    let x = x +. (width /. 2.) in
    let y = y +. (height /. 2.) in
    let x, y, width, height =
      let scaled = Normalization.scale in
      (scaled x, scaled y, scaled width, scaled height)
    in
    { x; y; width; height }
  in
  let final_coord = get_coord elem in
  (* We cannot rely on "state" since computation for the zoom factor in the
     computation, since when the computation happen during a transition, the end
     state is used (instead of the intermediatory one) *)
  let scale = Window.live_scale window in
  {
    x = final_coord.x /. scale;
    y = final_coord.y /. scale;
    height = final_coord.height /. scale;
    width = final_coord.width /. scale;
  }

module Window = struct
  let focus ~current elems =
    let box (b1 : element) (b2 : element) =
      let left_x =
        Float.min (b1.x -. (b1.width /. 2.)) (b2.x -. (b2.width /. 2.))
      in
      let right_x =
        Float.max (b1.x +. (b1.width /. 2.)) (b2.x +. (b2.width /. 2.))
      in
      let top_y =
        Float.min (b1.y -. (b1.height /. 2.)) (b2.y -. (b2.height /. 2.))
      in
      let bottom_y =
        Float.max (b1.y +. (b1.height /. 2.)) (b2.y +. (b2.height /. 2.))
      in
      {
        width = right_x -. left_x;
        height = bottom_y -. top_y;
        x = (right_x +. left_x) /. 2.;
        y = (bottom_y +. top_y) /. 2.;
      }
    in
    match elems with
    | [] -> current
    | elem :: elems ->
        let box = List.fold_left box elem elems in
        let scale1 = width /. box.width and scale2 = height /. box.height in
        let scale = Float.min scale1 scale2 in
        { scale; x = box.x; y = box.y }

  let enter elem =
    let scale = width /. elem.width in
    let y = elem.y -. (elem.height /. 2.) +. (height /. 2. /. scale) in
    { scale; x = elem.x; y }

  let up ?(margin = 13.5) ~current elem =
    let margin = margin /. current.scale in
    let y =
      elem.y -. (elem.height /. 2.) +. (height /. 2. /. current.scale) -. margin
    in
    { current with y }

  let down ?(margin = 13.5) ~current elem =
    let margin = margin /. current.scale in
    let y =
      elem.y +. (elem.height /. 2.) -. (height /. 2. /. current.scale) +. margin
    in
    { current with y }

  let center ~(current : window) (elem : element) = { current with y = elem.y }
end
