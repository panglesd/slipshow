open Types

let svg_path options scale path =
  let path =
    List.rev_map
      (fun ((x, y), _) -> Perfect_freehand.Point.v (x *. scale) (y *. scale))
      path
  in
  let stroke = Perfect_freehand.get_stroke ~options path in
  let svg_path = Perfect_freehand.get_svg_path_from_stroke stroke in
  Jstr.to_string svg_path

let create_elem_of_stroke
    { Stroke.options; scale; color; opacity; id; path; end_at = _ } =
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
