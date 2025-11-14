let map_time time1 time2 new_duration time =
  if time <= time1 then time
  else if time >= time2 then time -. time2 +. time1 +. new_duration
  else time1 +. ((time -. time1) *. new_duration /. (time2 -. time1))

let change_path path time1 time2 new_duration =
  let map_time = map_time time1 time2 new_duration in
  List.map (fun (pos, time) -> (pos, map_time time)) path

let translate path t0 = List.map (fun (pos, time) -> (pos, time +. t0)) path

let translate_space path dx dy =
  List.map (fun ((x, y), time) -> ((x +. dx, y +. dy), time)) path

let scale_space path minX minY scale =
  List.map
    (fun ((x, y), time) ->
      ((minX +. ((x -. minX) *. scale), minY +. ((y -. minY) *. scale)), time))
    path

let add_time path from amount =
  match List.rev path with
  | (_, time) :: _ when time > from ->
      List.map (fun (pos, time) -> (pos, time +. amount)) path
  | _ -> path

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
  | first :: rest -> (
      try
        let _last_point =
          List.fold_left
            (fun p1 p2 ->
              if intersect (p1, p2) segment then raise Not_found else p2)
            first rest
        in
        false
      with Not_found -> true)

let intersect_poly2 p segment =
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
  List.exists (fun p1 -> close_enough p1 coord) p

let close_enough_poly2 p coord =
  let close_enough (x1, y1) (x2, y2) =
    abs_float (x1 -. x2) < 10. && abs_float (y1 -. y2) < 10.
  in
  List.exists (fun (p1, _) -> close_enough p1 coord) p

open Types

let svg_path options scale path =
  let path =
    List.rev_map
      (fun (x, y) -> Perfect_freehand.Point.v (x *. scale) (y *. scale))
      path
  in
  let stroke = Perfect_freehand.get_stroke ~options path in
  let svg_path = Perfect_freehand.get_svg_path_from_stroke stroke in
  Jstr.to_string svg_path

let create_elem_of_stroke { Stroke.options; scale; color; opacity; id; path } =
  let p = Brr.El.v ~ns:`SVG (Jstr.v "path") [] in
  let set_at at v = Brr.El.set_at (Jstr.v at) (Some (Jstr.v v)) p in
  set_at "fill" (Color.to_string color);
  set_at "id" id;
  let () =
    let scale = 1. /. scale in
    let scale = string_of_float scale in
    Brr.El.set_inline_style (Jstr.v "transform")
      (Jstr.v @@ "scale3d(" ^ scale ^ "," ^ scale ^ "," ^ scale ^ ")")
      p
  in
  set_at "opacity" (string_of_float opacity);
  Brr.El.set_at (Jstr.v "d") (Some (Jstr.v (svg_path options scale path))) p;
  p

let options_of stroker width =
  let size =
    match (stroker, width) with
    | Tool.Pen, Width.Small -> 6.
    | Pen, Medium -> 10.
    | Pen, Large -> 14.
    | Highlighter, Small -> 28.
    | Highlighter, Medium -> 38.
    | Highlighter, Large -> 48.
  in
  Perfect_freehand.Options.v ~thinning:0.5 ~smoothing:0.5 ~size ~streamline:0.5
    ~last:false ()
