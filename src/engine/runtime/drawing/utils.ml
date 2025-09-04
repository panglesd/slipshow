let intersect (p1, p2) (q1, q2) =
  (* https://www.geeksforgeeks.org/check-if-two-given-line-segments-intersect/ *)
  let orientation (x1, y1) (x2, y2) (x3, y3) =
    let value = ((y2 -. y1) *. (x3 -. x2)) -. ((x2 -. x1) *. (y3 -. y2)) in
    if value > 0. then `Counter_clockwise
    else if value < 0. then `Clockwise
    else `Collinear
  in
  let on_segment (x1, y1) (x2, y2) (x3, y3) =
    x2 >= Float.min x1 x3
    && x2 <= Float.max x1 x3
    && y2 >= Float.min y1 y3
    && y2 <= Float.max y1 y3
  in
  let o1 = orientation p1 p2 q1 in
  let o2 = orientation p1 p2 q2 in
  let o3 = orientation q1 q2 p1 in
  let o4 = orientation q1 q2 p2 in
  if o1 <> o2 && o3 <> o4 then true
    (* Special case: collinear points lying on each other's segments *)
  else if o1 = `Colinear && on_segment p1 q1 p2 then true
  else if o2 = `Colinear && on_segment p1 q2 p2 then true
  else if o3 = `Colinear && on_segment q1 p1 q2 then true
  else if o4 = `Colinear && on_segment q1 p2 q2 then true
  else false

let intersect_poly p segment =
  match p with
  | [] -> false
  | (first, _) :: rest -> (
      try
        let _last_point =
          List.fold_left
            (fun p1 (p2, _) ->
              if intersect (p1, p2) segment then raise Not_found else p2)
            first rest
        in
        false
      with Not_found -> true)

let close_enough_poly p coord =
  let close_enough (x1, y1) (x2, y2) =
    abs_float (x1 -. x2) < 10. && abs_float (y1 -. y2) < 10.
  in
  List.exists (fun (p1, _) -> close_enough p1 coord) p
