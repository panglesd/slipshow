type window = { x : float; y : float; scale : float }
type element = { x : float; y : float; width : float; height : float }

open Brr

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
    | Some parent when El.class' (Jstr.v "universe") parent ->
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
  let focus elem =
    let scale1 = Constants.width /. elem.width
    and scale2 = Constants.height /. elem.height in
    let scale = Float.min scale1 scale2 in
    { scale; x = elem.x; y = elem.y }

  let enter elem =
    let scale = Constants.width /. elem.width in
    let y =
      elem.y -. (elem.height /. 2.) +. (Constants.height /. 2. /. scale)
    in
    { scale; x = elem.x; y }

  let up ~current elem =
    let y =
      elem.y -. (elem.height /. 2.) +. (Constants.height /. 2. /. current.scale)
    in
    { current with y }

  let down ~current elem =
    let y =
      elem.y +. (elem.height /. 2.) -. (Constants.height /. 2. /. current.scale)
    in
    { current with y }

  let center ~(current : window) (elem : element) = { current with y = elem.y }
end
