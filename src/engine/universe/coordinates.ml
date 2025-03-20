open Brr
open Constants

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

let get elem =
  let get_coord_in_parent elem =
    let x = Brr.El.offset_left elem and y = Brr.El.offset_top elem in
    (float_of_int x, float_of_int y)
  in
  let compute_scale elem =
    let comp = El.computed_style (Jstr.v "transform") elem |> Jstr.to_string in
    let b = String.index_opt comp '(' in
    let e = String.index_opt comp ',' in
    match (b, e) with
    | Some b, Some e ->
        String.sub comp (b + 1) (e - b - 1)
        |> float_of_string_opt |> Option.value ~default:1.
    | _ -> 1.
  in
  let rec compute elem =
    match El.offset_parent elem with
    | None -> ((0., 0.), 1.)
    | Some parent when El.class' (Jstr.v "slipshow-universe") parent ->
        (get_coord_in_parent elem, 1.)
    | Some parent ->
        let (cx, cy), parent_scale = compute parent in
        let x, y = get_coord_in_parent elem in
        let scale = compute_scale parent *. parent_scale in
        let x = cx +. (x *. scale) in
        let y = cy +. (y *. scale) in
        ((x, y), scale)
  in
  let (x, y), scale = compute elem in
  let scale = compute_scale elem *. scale in
  let width = float_of_int (El.offset_w elem) *. scale in
  let height = float_of_int (El.offset_h elem) *. scale in
  let x = x +. (width /. 2.) in
  let y = y +. (height /. 2.) in
  { x; y; width; height }

module Window_of_elem = struct
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
