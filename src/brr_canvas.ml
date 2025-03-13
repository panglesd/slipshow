(*--------------------------'-------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr

module Matrix4 = struct
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)

  let is_2d m = Jv.Bool.get m "is2D"
  let is_identity m = Jv.Bool.get m "isIdentity"
  let inverse m = Jv.call m "inverse" [||]
  let multiply m m' = Jv.call m "multiply" [|m'|]

  let m11 m = Jv.Float.get m "m11"
  let m12 m = Jv.Float.get m "m12"
  let m13 m = Jv.Float.get m "m13"
  let m14 m = Jv.Float.get m "m14"
  let m21 m = Jv.Float.get m "m21"
  let m22 m = Jv.Float.get m "m22"
  let m23 m = Jv.Float.get m "m23"
  let m24 m = Jv.Float.get m "m24"
  let m31 m = Jv.Float.get m "m31"
  let m32 m = Jv.Float.get m "m32"
  let m33 m = Jv.Float.get m "m33"
  let m34 m = Jv.Float.get m "m34"
  let m41 m = Jv.Float.get m "m41"
  let m42 m = Jv.Float.get m "m42"
  let m43 m = Jv.Float.get m "m43"
  let m44 m = Jv.Float.get m "m44"
  let a m = Jv.Float.get m "a"
  let b m = Jv.Float.get m "b"
  let c m = Jv.Float.get m "c"
  let d m = Jv.Float.get m "d"
  let e m = Jv.Float.get m "e"
  let f m = Jv.Float.get m "f"

  let dommatrixro = Jv.get Jv.global "DOMMatrixReadOnly"

  let to_float32_array m = Tarray.of_jv @@ Jv.call m "toFloat32Array" [||]
  let of_float32_array a =
    Jv.call dommatrixro "fromFloat32Array" [| Tarray.to_jv a |]

  let to_float64_array m = Tarray.of_jv @@ Jv.call m "toFloat64Array" [||]
  let of_float64_array a =
    Jv.call dommatrixro "fromFloat64Array" [| Tarray.to_jv a |]
end

module Vec4 = struct
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
  let v4 = Jv.get Jv.global "DOMPointReadOnly"
  let v ~x ~y ~z ~w =
    Jv.new' v4 Jv.[|of_float x; of_float y; of_float z; of_float w;|]

  let tr m v = Jv.call v "matrixTransform" [| Matrix4.to_jv m |]
  let to_json v = Jv.call v "toJSON" [||]
  let x v = Jv.Float.get v "x"
  let y v = Jv.Float.get v "y"
  let z v = Jv.Float.get v "z"
  let w v = Jv.Float.get v "w"
end

module Canvas = struct
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)

  let create ?d ?at ?(w = 0) ?(h = 0) cs =
    let c = El.to_jv @@ El.canvas ?d ?at cs in
    Jv.Int.set c "width" w; Jv.Int.set c "height" h;
    c

  let of_el e =
    if El.has_tag_name El.Name.canvas e then (El.to_jv e) else
    let exp = Jstr.v "Expected canvas element but found: " in
    Jv.throw (Jstr.append exp (El.tag_name e))

  let to_el = El.of_jv

  (* Dimensions *)

  let w c = Jv.Int.get c "width"
  let h c = Jv.Int.get c "height"
  let set_w c w = Jv.Int.set c "width" w
  let set_h c h = Jv.Int.set c "height" h
  let set_size_to_layout_size ?(hidpi = true) c =
    let dpr = if hidpi then Window.device_pixel_ratio G.window else 1.0 in
    let cw = Float.to_int @@ Float.ceil (dpr *. El.inner_w (El.of_jv c)) in
    let ch = Float.to_int @@ Float.ceil (dpr *. El.inner_h (El.of_jv c)) in
    if w c <> cw || h c <> ch
    then (set_w c cw; set_h c ch)

  (* Converting *)

  type image_encode = Jv.t (* ImageEncodeOptions object. *)
  let image_encode ?(type' = Jstr.v "image/png") ?quality () =
    let o = Jv.obj [||] in
    Jv.Jstr.set o "type" type';
    Jv.Float.set_if_some o "quality" quality;
    o

  let enc ?encode c meth arg =
    let encode = match encode with None -> image_encode () | Some e -> e in
    let t = Jv.get encode "type" in
    let q = Jv.find encode "quality" in
    let args = match arg with
    | None -> (match q with None -> [|t|] | Some q -> [|t; q|])
    | Some a -> (match q with None -> [|a; t|] | Some q -> [| a; t; q|])
    in
    Jv.call c meth args

  let to_data_url ?encode c = ignore encode ; match enc c "toDataURL" None with
  | exception Jv.Error e -> Error e
  | v -> Ok (Jv.to_jstr v)

  let to_blob ?encode c =
    ignore encode;
    let fut, set = Fut.create () in
    let cb blob = set (Ok (Jv.to_option Blob.of_jv blob)) in
    match enc c "toBlob" (Some (Jv.callback ~arity:1 cb)) with
    | exception Jv.Error e -> set (Error e); fut
    | _ -> fut

  let capture_stream ~hz c =
    let args = match hz with None -> [||] | Some hz -> [|Jv.of_int hz|] in
    Brr_io.Media.Stream.of_jv @@ Jv.call c "captureStrseam" args
end

module C2d = struct

  (* Enumerations *)

  module Fill_rule = struct
    type t = Jstr.t
    let nonzero = Jstr.v "nonzero"
    let evenodd = Jstr.v "evenodd"
  end

  module Image_smoothing_quality = struct
    type t = Jstr.t
    let low = Jstr.v "low"
    let medium = Jstr.v "medium"
    let high = Jstr.v "high"
  end

  module Line_cap = struct
    type t = Jstr.t
    let butt = Jstr.v "butt"
    let round = Jstr.v "round"
    let square = Jstr.v "square"
  end

  module Line_join = struct
    type t = Jstr.t
    let round = Jstr.v "round"
    let bevel = Jstr.v "bevel"
    let miter = Jstr.v "miter"
  end

  module Text_align = struct
    type t = Jstr.t
    let start = Jstr.v "start"
    let end' = Jstr.v "end"
    let left = Jstr.v "left"
    let right = Jstr.v "right"
    let center = Jstr.v "center"
  end

  module Text_baseline = struct
    type t = Jstr.t
    let top = Jstr.v "top"
    let hanging = Jstr.v "hanging"
    let middle = Jstr.v "middle"
    let alphabetic = Jstr.v "alphabetic"
    let ideographic = Jstr.v "ideographic"
    let bottom = Jstr.v "bottom"
  end

  module Text_direction = struct
    type t = Jstr.t
    let ltr = Jstr.v "ltr"
    let rtl = Jstr.v "rtl"
    let inherit' = Jstr.v "inherit"
  end

  module Composite_op = struct
    type t = Jstr.t

    let normal = Jstr.v "normal"
    let multiply = Jstr.v "multiply"
    let screen = Jstr.v "screen"
    let overlay = Jstr.v "overlay"
    let darken = Jstr.v "darken"
    let lighten = Jstr.v "lighten"
    let color_dodge = Jstr.v "color-dodge"
    let color_burn = Jstr.v "color-burn"
    let hard_light = Jstr.v "hard-light"
    let soft_light = Jstr.v "soft-light"
    let difference = Jstr.v "difference"
    let exclusion = Jstr.v "exclusion"
    let hue = Jstr.v "hue"
    let saturation = Jstr.v "saturation"
    let color = Jstr.v "color"
    let luminosity = Jstr.v "luminosity"
    let clear = Jstr.v "clear"
    let copy = Jstr.v "copy"
    let source_over = Jstr.v "source-over"
    let destination_over = Jstr.v "destination-over"
    let source_in = Jstr.v "source-in"
    let destination_in = Jstr.v "destination-in"
    let source_out = Jstr.v "source-out"
    let destination_out = Jstr.v "destination-out"
    let source_atop = Jstr.v "source-atop"
    let destination_atop = Jstr.v "destination-atop"
    let xor = Jstr.v "xor"
    let lighter = Jstr.v "lighter"
    let plus_darker = Jstr.v "plus-darker"
    let plus_lighter = Jstr.v "plus-lighter"
  end

  module Repeat = struct
    type t = Jstr.t
    let xy = Jstr.v "repeat"
    let x = Jstr.v "repeat-x"
    let y = Jstr.v "repeat-y"
    let no = Jstr.v "no-repeat"
  end

  module Path = struct
    type t = Jv.t
    let path = Jv.get Jv.global "Path2D"
    let create () = Jv.new' path [||]
    let of_svg svg = Jv.new' path [| Jv.of_jstr svg |]
    let of_path p = Jv.new' path [| p |]
    let add ?tr p p' =
      ignore @@ Jv.call p "addPath"
        (match tr with None -> [|p'|] | Some t -> [|p'; Matrix4.to_jv t|])

    let close p =
      ignore @@ Jv.call p "closePath" [||]

    let move_to p ~x ~y =
      ignore @@ Jv.call p "moveTo" Jv.[| of_float x; of_float y |]

    let line_to p ~x ~y =
      ignore @@ Jv.call p "lineTo" Jv.[| of_float x; of_float y |]

    let qcurve_to p ~cx ~cy ~x ~y =
      ignore @@ Jv.call p "quadraticCurveTo"
        Jv.[| of_float cx; of_float cy; of_float x; of_float y |]

    let ccurve_to p ~cx ~cy ~cx' ~cy' ~x ~y =
      ignore @@ Jv.call p "bezierCurveTo"
        Jv.[| of_float cx; of_float cy; of_float cx'; of_float cy';
              of_float x; of_float y|]

    let arc_to p ~cx ~cy ~cx' ~cy' ~r =
      ignore @@ Jv.call p "arcTo"
        Jv.[| of_float cx; of_float cy; of_float cx'; of_float cy'; of_float r|]

    let arc ?(anticlockwise = false) p ~cx ~cy ~r ~start ~stop =
      ignore @@ Jv.call p "arc"
        Jv.[| of_float cx; of_float cy; of_float r; of_float start;
              of_float stop; of_bool anticlockwise |]

    let rect p ~x ~y ~w ~h =
      ignore @@  Jv.call p "rect"
        Jv.[| of_float x; of_float y; of_float w; of_float h |]

    let ellipse ?(anticlockwise = false) p ~cx ~cy ~rx ~ry ~rot ~start ~stop =
      ignore @@ Jv.call p "ellipse"
        Jv.[| of_float cx; of_float cy; of_float rx; of_float ry; of_float rot;
              of_float start; of_float stop; of_bool anticlockwise |]

    include (Jv.Id : Jv.CONV with type t := t)
  end

  (* Image sources *)

  type image_src = Jv.t
  let image_src_of_el = El.to_jv
  let image_src_of_jv = Fun.id

  (* Attributes *)

  type attrs = Jv.t

  (* let attrs ?alpha ?color_space ?desynchronized ?will_read_frequently () = *)
  (*   let o = Jv.obj [||] in *)
  (*   Jv.Bool.set_if_some o "alpha" alpha; *)
  (*   Jv.Jstr.set_if_some o "colorSpace" color_space; *)
  (*   Jv.Bool.set_if_some o "desynchronized" desynchronized; *)
  (*   Jv.Bool.set_if_some o "willReadFrequently" will_read_frequently; *)
  (*   o *)

  let attrs_alpha o = Jv.Bool.get o "alpha"
  let attrs_color_space o =
    (* This can be get once FF supports the property. *)
    Option.value ~default:Jstr.empty (Jv.Jstr.find o "colorSpace")

  let attrs_desynchronized o = Jv.Bool.get o "desynchronized"
  let attrs_will_read_frequently o = Jv.Bool.get o "willReadFrequently"

  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
  let get_context ?(attrs = Jv.undefined) cnv =
    Jv.call cnv "getContext" Jv.[| of_string "2d"; attrs |]

  let create = get_context

  let canvas c = Jv.find_map Canvas.of_jv c "canvas"
  let attrs c = Jv.call c "getContextAttributes" [||]
  let save c = ignore @@ Jv.call c "save" [||]
  let restore c = ignore @@ Jv.call c "restore" [||]

  (* Antialiasing *)

  let image_smoothing_enabled c = Jv.Bool.get c "imageSmoothingEnabled"
  let set_image_smoothing_enabled c b = Jv.Bool.set c "imageSmoothingEnabled" b
  let image_smoothing_quality c = Jv.Jstr.get c "imageSmoothingQuality"
  let set_image_smoothing_quality c v = Jv.Jstr.set c "imageSmoothingQuality" v

  (* Compositing *)

  let global_alpha c = Jv.Float.get c "globalAlpha"
  let set_global_alpha c a = Jv.Float.set c "globalAlpha" a
  let global_composite_op c = Jv.Jstr.get c "globalCompositeOperation"
  let set_global_composite_op c o = Jv.Jstr.set c "globalCompositeOperation" o
  let filter c = Jv.Jstr.get c "filter"
  let set_filter c f = Jv.Jstr.set c "filter" f

  (* Transforms *)

  let get_transform c = Matrix4.of_jv @@ Jv.call c "getTransform" [||]
  let set_transform c m =
    ignore @@ Jv.call c "setTransform" [| Matrix4.to_jv m |]

  let set_transform' ctx ~a ~b ~c ~d ~e ~f =
    ignore @@ Jv.call ctx "setTransform"
      Jv.[| of_float a; of_float b; of_float c; of_float d;
            of_float e; of_float f |]

  let reset_transform c = ignore @@ Jv.call c "resetTransform" [||]
  let transform c m =
    ignore @@ Jv.call c "transform"
      Jv.[| of_float (Matrix4.a m); of_float (Matrix4.b m);
            of_float (Matrix4.c m); of_float (Matrix4.d m);
            of_float (Matrix4.e m); of_float (Matrix4.f m) |]

  let transform' ctx ~a ~b ~c ~d ~e ~f =
    ignore @@ Jv.call ctx "transform"
      Jv.[| of_float a; of_float b; of_float c; of_float d;
            of_float e; of_float f |]

  let translate c ~x ~y =
    ignore @@ Jv.call c "translate" Jv.[| of_float x; of_float y |]

  let rotate c r = ignore @@ Jv.call c "rotate" Jv.[| of_float r |]
  let scale c ~sx ~sy =
    ignore @@ Jv.call c "scale" Jv.[| of_float sx; of_float sy |]

  (* Style fills and strokes *)

  type style = Jv.t
  let set_stroke_style c s = Jv.set c "strokeStyle" s
  let set_fill_style c s = Jv.set c "fillStyle" s
  let color = Jv.of_jstr

  type gradient = Jv.t
  let gradient_style = Fun.id

  let make_stops g stops =
    let add_stop g (off, c) =
      ignore @@ Jv.call g "addColorStop" Jv.[| of_float off; of_jstr c |]
    in
    List.iter (add_stop g) stops

  let linear_gradient c ~x0 ~y0 ~x1 ~y1 ~stops =
    let g =
      Jv.call c "createLinearGradient"
        Jv.[| of_float x0; of_float y0; of_float x1; of_float y1 |]
    in
    make_stops g stops; g

  let radial_gradient c ~x0 ~y0 ~r0 ~x1 ~y1 ~r1 ~stops =
    let g =
      Jv.call c "createRadialGradient"
        Jv.[| of_float x0; of_float y0; of_float r0;
              of_float x1; of_float y1; of_float r1; |]
    in
    make_stops g stops; g

  type pattern = Jv.t
  let pattern c img r ~tr =
    let p = Jv.call c "createPattern" [|img; Jv.of_jstr r|] in
    match tr with
    | None -> p
    | Some t -> ignore @@ Jv.call p "setTransform" [| Matrix4.to_jv t |]; p

  let pattern_style = Fun.id

  (* Style lines *)

  let line_width c = Jv.Float.get c "lineWidth"
  let set_line_width c w = Jv.Float.set c "lineWidth" w
  let line_cap c = Jv.Jstr.get c "lineCap"
  let set_line_cap c cap = Jv.Jstr.set c "lineCap" cap
  let line_join c = Jv.Jstr.get c "lineJoin"
  let set_line_join c join = Jv.Jstr.set c "lineJoin" join
  let miter_limit c = Jv.Float.get c "miterLimit"
  let set_miter_limit c l = Jv.Float.set c "miterLimit" l
  let line_dash c = Jv.to_list Jv.to_float @@ Jv.call c "getLineDash" [||]
  let set_line_dash c ds =
    ignore @@ Jv.call c "setLineDash" [|Jv.of_list Jv.of_float ds|]

  let line_dash_offset c = Jv.Float.get c "lineDashOffset"
  let set_line_dash_offset c o = Jv.Float.set c "lineDashOffset" o

  (* Style shadows *)

  let shadow_blur c = Jv.Float.get c "shadowBlur"
  let set_shadow_blur c b = Jv.Float.set c "shadowBlur" b
  let shadow_offset_x c = Jv.Float.get c "shadowOffsetX"
  let set_shadow_offset_x c o = Jv.Float.set c "shadowOffsetX" o
  let shadow_offset_y c = Jv.Float.get c "shadowOffsetY"
  let set_shadow_offset_y c o = Jv.Float.set c "shadowOffsetY" o
  let shadow_color c = Jv.Jstr.get c "shadowColor"
  let set_shadow_color c col = Jv.Jstr.set c "shadowColor" col

  (* Style text *)

  let font c = Jv.Jstr.get c "font"
  let set_font c f = Jv.Jstr.set c "font" f
  let text_align c = Jv.Jstr.get c "textAlign"
  let set_text_align c a = Jv.Jstr.set c "textAlign" a
  let text_baseline c = Jv.Jstr.get c "textBaseline"
  let set_text_baseline c b = Jv.Jstr.set c "textBaseline" b
  let text_direction c = Jv.Jstr.get c "direction"
  let set_text_direction c d = Jv.Jstr.set c "direction" d

  (* Draw rectangles *)

  let clear_rect c ~x ~y ~w ~h =
    ignore @@ Jv.call c "clearRect"
      Jv.[| of_float x; of_float y; of_float w; of_float h |]

  let fill_rect c ~x ~y ~w ~h =
    ignore @@ Jv.call c "fillRect"
      Jv.[| of_float x; of_float y; of_float w; of_float h |]

  let stroke_rect c ~x ~y ~w ~h =
    ignore @@ Jv.call c "strokeRect"
      Jv.[| of_float x; of_float y; of_float w; of_float h |]

  (* Draw paths *)

  let fill ?(fill_rule = Fill_rule.nonzero) c p =
    ignore @@ Jv.call c "fill" [| p; Jv.of_jstr fill_rule |]

  let stroke c p =
    ignore @@ Jv.call c "stroke" [| p |]

  let clip ?(fill_rule = Fill_rule.nonzero) c p =
    ignore @@ Jv.call c "clip" [| p; Jv.of_jstr fill_rule |]

  let draw_focus_if_needed c p e =
    ignore @@ Jv.call c "drawFocusIfNeeded" [| p; El.to_jv e |]

  let scroll_path_into_view c p =
    ignore @@ Jv.call c "scrollPathIntoView" [| p |]

  let is_point_in_fill ?(fill_rule = Fill_rule.nonzero) c p ~x ~y =
    Jv.to_bool @@ Jv.call c "isPointInPath"
      Jv.[| p; of_float x; of_float y; of_jstr fill_rule |]

  let is_point_in_stroke c p ~x ~y =
    Jv.to_bool @@ Jv.call c "isPointInStroke"
      Jv.[| p; of_float x; of_float y; |]

  (* Draw text *)

  let call_text c meth ?max_width txt ~x ~y =
    let args = match max_width with
    | None -> Jv.[|of_jstr txt; of_float x; of_float y |]
    | Some m -> Jv.[|of_jstr txt; of_float x; of_float y; of_float m |]
    in
    ignore @@ Jv.call c meth args

  let fill_text ?max_width c txt ~x ~y =
    call_text c "fillText" ?max_width txt ~x ~y

  let stroke_text ?max_width c txt ~x ~y =
    call_text c "strokeText" ?max_width txt ~x ~y

  module Text_metrics = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let width m = Jv.Float.get m "width"
    let actual_bounding_box_left m = Jv.Float.get m "actualBoundingBoxLeft"
    let actual_bounding_box_right m = Jv.Float.get m "actualBoundingBoxRight"
    let font_bounding_box_ascent m = Jv.Float.get m "fontBoundingBoxAscent"
    let font_bounding_box_descent m = Jv.Float.get m "fontBoundingBoxDescent"
    let actual_bounding_box_ascent m = Jv.Float.get m "actualBoundingBoxAscent"
    let actual_bounding_box_descent m =
      Jv.Float.get m "actualBoundingBoxDescent"
    let em_height_ascent m = Jv.Float.get m "emHeightAscent"
    let em_height_descent m = Jv.Float.get m "emHeightDescent"
    let hanging_baseline m = Jv.Float.get m "hangingBaseline"
    let alphabetic_baseline m = Jv.Float.get m "alphabeticBaseline"
    let ideographic_baseline m = Jv.Float.get m "ideographicBaseline"
  end

  let measure_text c txt =
    Text_metrics.of_jv @@ Jv.call c "measureText" [| Jv.of_jstr txt |]

  (* Draw images *)

  let draw_image c i ~x ~y =
    ignore @@ Jv.call c "drawImage" Jv.[| i; of_float x; of_float y |]

  let draw_image_in_rect c i ~x ~y ~w ~h =
    ignore @@ Jv.call c "drawImage"
      Jv.[| i; of_float x; of_float y; of_float w; of_float h |]

  let draw_sub_image_in_rect c i ~sx ~sy ~sw ~sh ~x ~y ~w ~h =
    ignore @@ Jv.call c "drawImage"
      Jv.[| i;
            of_float sx; of_float sy; of_float sw; of_float sh;
            of_float x; of_float y; of_float w; of_float h |]

  (* Pixel manipulations *)

  module Image_data = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let settings ?color_space () = match color_space with
    | None -> Jv.undefined
    | Some cs ->
        let o = Jv.obj [||] in
        Jv.Jstr.set o "colorSpace" cs; o

    let image_data = Jv.get Jv.global "ImageData"
    let create ?color_space ?data ~w ~h () =
      let settings = settings ?color_space () in
      let args = match data with
      | None -> Jv.[|of_int w; of_int h; settings|]
      | Some data -> Jv.[|Tarray.to_jv data; of_int w; of_int h; settings|]
      in
      Jv.new' image_data args

    let w d = Jv.Int.get d "width"
    let h d = Jv.Int.get d "height"
    let color_space d =
      (* Can become Jv.Jstr.get once firefox supports the property. *)
      Option.value ~default:Jstr.empty (Jv.Jstr.find d "colorSpace")

    let data d = Tarray.of_jv @@ Jv.get d "data"
  end

  let create_image_data ?color_space c ~w ~h =
    let settings = Image_data.settings ?color_space () in
    Image_data.of_jv @@ Jv.call c "createImageData"
      Jv.[| of_int w; of_int h; settings |]

  let get_image_data ?color_space c ~x ~y ~w ~h =
    let settings = Image_data.settings ?color_space () in
    Image_data.of_jv @@ Jv.call c "getImageData"
      Jv.[|of_int x; of_int y; of_int w; of_int h; settings|]

  let put_image_data c d ~x ~y =
    ignore @@ Jv.call c "putImageData"
      Jv.[| Image_data.to_jv d; of_int x; of_int y |]

  let put_sub_image_data c d ~sx ~sy ~sw ~sh ~x ~y =
    ignore @@ Jv.call c "putImageData"
      Jv.[| Image_data.to_jv d; of_int x; of_int y;
            of_int sx; of_int sy; of_int sw; of_int sh |]
end

module Gl = struct

  (* Context creation *)

  module Attrs = struct
    module Power_preference = struct
      type t = Jstr.t
      let default = Jstr.v "default"
      let high_performance = Jstr.v "high-performance"
      let low_power = Jstr.v "low-power"
    end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let v
        ?alpha ?depth ?stencil ?antialias ?premultiplied_alpha
        ?preserve_drawing_buffer ?power_preference
        ?fail_if_major_performance_caveat ?desynchronized () =
      let o = Jv.obj [||] in
      Jv.Bool.set_if_some o "alpha" alpha;
      Jv.Bool.set_if_some o "depth" depth;
      Jv.Bool.set_if_some o "stencil" stencil;
      Jv.Bool.set_if_some o "antialias" antialias;
      Jv.Bool.set_if_some o "premultipliedApha" premultiplied_alpha;
      Jv.Bool.set_if_some o "preserveDrawingBuffer" preserve_drawing_buffer;
      Jv.Jstr.set_if_some o "powerPreference" power_preference;
      Jv.Bool.set_if_some o "failIfMajorPerformanceCaveat"
        fail_if_major_performance_caveat;
      Jv.Bool.set_if_some o "desynchronized" desynchronized;
      o

    let alpha a = Jv.Bool.get a "alpha"
    let depth a = Jv.Bool.get a "depth"
    let stencil a = Jv.Bool.get a "stencil"
    let antialias a = Jv.Bool.get a "antialias"
    let premultiplied_alpha a = Jv.Bool.get a "premultipliedApha"
    let preserve_drawing_buffer a = Jv.Bool.get a "preserveDrawingBuffer"
    (* let fail_if_major_performance_caveat a = *)
    (*   Jv.Bool.get a "failIfMajorPerformanceCaveat" *)
    let power_preference a = Jv.Jstr.get a "powerPreference"
    let desynchronized a = Jv.Bool.get a "desynchronized"
  end

  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)

  let get_context ?(attrs = Jv.undefined) ?(v1 = false) cnv =
    let webgl = Jv.of_string (if v1 then "webgl" else "webgl2") in
    Jv.to_option Fun.id @@
    Jv.call (Canvas.to_jv cnv) "getContext" [| webgl; attrs |]

  let create = get_context

  let canvas c = Jv.find_map Canvas.of_jv c "canvas"
  let attrs c = Jv.call c "getContextAttributes" [||]

  let drawing_buffer_width c = Jv.Int.get c "drawingBufferWidth"
  let drawing_buffer_height c = Jv.Int.get c "drawingBufferHeight"
  let is_context_lost c = Jv.Bool.get c "isContextLost"

  let get_supported_extensions c =
    Jv.to_jstr_list @@ Jv.call c "getSupportedExtensions" [||]

  let get_extension c ext = Jv.call c "getExtension" Jv.[| of_jstr ext |]

  (* Types *)

  type enum = int
  type buffer = Jv.t
  type framebuffer = Jv.t
  type program = Jv.t
  type query = Jv.t
  type renderbuffer = Jv.t
  type sampler = Jv.t
  type shader = Jv.t
  type sync = Jv.t
  type texture = Jv.t
  type transform_feedback = Jv.t
  type uniform_location = Jv.t
  type vertex_array_object = Jv.t

  module Active_info = struct
    type t = Jv.t
    let size i = Jv.Int.get i "size"
    let type' i = Jv.Int.get i "type"
    let name i = Jv.Jstr.get i "name"
  end

  module Shader_precision_format = struct
    type t = Jv.t
    let range_min f = Jv.Int.get f "rangeMin"
    let range_max f = Jv.Int.get f "rangeMax"
    let precision f = Jv.Int.get f "precision"
  end

  module Tex_image_source = struct
    type t = Jv.t
    let of_image_data = C2d.Image_data.to_jv
    let of_img_el = Brr.El.to_jv
    let of_canvas_el = Canvas.to_jv
    let of_video_el = Brr_io.Media.El.to_jv
    let of_offscreen_canvas = Fun.id
  end

  (* Functions *)

  let active_texture c texture =
    ignore @@ Jv.call c "activeTexture" Jv.[|of_int texture|]

  let attach_shader c program shader =
    ignore @@ Jv.call c "attachShader" [|program; shader|]

  let begin_query c target query =
    ignore @@ Jv.call c "beginQuery" Jv.[|of_int target; query|]

  let begin_transform_feedback c primitiveMode =
    ignore @@ Jv.call c "beginTransformFeedback" Jv.[|of_int primitiveMode|]

  let bind_attrib_location c program index name =
    ignore @@ Jv.call c "bindAttribLocation" Jv.[|program; of_int index; of_jstr name|]

  let bind_buffer c target buffer =
    ignore @@ Jv.call c "bindBuffer" Jv.[|of_int target; of_option ~none:null Fun.id buffer|]

  let bind_buffer_base c target index buffer =
    ignore @@ Jv.call c "bindBufferBase" Jv.[|of_int target; of_int index; buffer|]

  let bind_buffer_range c target index buffer offset size =
    ignore @@ Jv.call c "bindBufferRange" Jv.[|of_int target; of_int index; buffer; of_int offset; of_int size|]

  let bind_framebuffer c target framebuffer =
    ignore @@ Jv.call c "bindFramebuffer" Jv.[|of_int target; of_option ~none:null Fun.id framebuffer|]

  let bind_renderbuffer c target renderbuffer =
    ignore @@ Jv.call c "bindRenderbuffer" Jv.[|of_int target; of_option ~none:null Fun.id renderbuffer|]

  let bind_sampler c unit sampler =
    ignore @@ Jv.call c "bindSampler" Jv.[|of_int unit; of_option ~none:null Fun.id sampler|]

  let bind_texture c target texture =
    ignore @@ Jv.call c "bindTexture" Jv.[|of_int target; of_option ~none:null Fun.id texture|]

  let bind_transform_feedback c target tf =
    ignore @@ Jv.call c "bindTransformFeedback" Jv.[|of_int target; of_option ~none:null Fun.id tf|]

  let bind_vertex_array c array =
    ignore @@ Jv.call c "bindVertexArray" Jv.[| of_option ~none:null Fun.id array|]

  let blend_color c red green blue alpha =
    ignore @@ Jv.call c "blendColor" Jv.[|of_float red; of_float green; of_float blue; of_float alpha|]

  let blend_equation c mode =
    ignore @@ Jv.call c "blendEquation" Jv.[|of_int mode|]

  let blend_equation_separate c modeRGB modeAlpha =
    ignore @@ Jv.call c "blendEquationSeparate" Jv.[|of_int modeRGB; of_int modeAlpha|]

  let blend_func c sfactor dfactor =
    ignore @@ Jv.call c "blendFunc" Jv.[|of_int sfactor; of_int dfactor|]

  let blend_func_separate c srcRGB dstRGB srcAlpha dstAlpha =
    ignore @@ Jv.call c "blendFuncSeparate" Jv.[|of_int srcRGB; of_int dstRGB; of_int srcAlpha; of_int dstAlpha|]

  let blit_framebuffer c srcX0 srcY0 srcX1 srcY1 dstX0 dstY0 dstX1 dstY1 mask filter =
    ignore @@ Jv.call c "blitFramebuffer" Jv.[|of_int srcX0; of_int srcY0; of_int srcX1; of_int srcY1; of_int dstX0; of_int dstY0; of_int dstX1; of_int dstY1; of_int mask; of_int filter|]

  let buffer_data c target srcData usage =
    ignore @@ Jv.call c "bufferData" Jv.[|of_int target; Tarray.to_jv srcData; of_int usage|]

  let buffer_data_size c target size usage =
    ignore @@ Jv.call c "bufferData" Jv.[|of_int target; of_int size; of_int usage|]

  let buffer_sub_data c target dstByteOffset srcData =
    ignore @@ Jv.call c "bufferSubData" Jv.[|of_int target; of_int dstByteOffset; Tarray.to_jv srcData |]

  let check_framebuffer_status c target =
    Jv.to_int @@ Jv.call c "checkFramebufferStatus" Jv.[|of_int target|]

  let clear c mask =
    ignore @@ Jv.call c "clear" Jv.[|of_int mask|]

  let clear_bufferfi c buffer drawbuffer depth stencil =
    ignore @@ Jv.call c "clearBufferfi" Jv.[|of_int buffer; of_int drawbuffer; of_float depth; of_int stencil|]

  let clear_bufferfv c buffer drawbuffer values =
    ignore @@ Jv.call c "clearBufferfv" Jv.[|of_int buffer; of_int drawbuffer; Tarray.to_jv values|]

  let clear_bufferiv c buffer drawbuffer values =
    ignore @@ Jv.call c "clearBufferiv" Jv.[|of_int buffer; of_int drawbuffer; Tarray.to_jv values|]

  let clear_bufferuiv c buffer drawbuffer values =
    ignore @@ Jv.call c "clearBufferuiv" Jv.[|of_int buffer; of_int drawbuffer; Tarray.to_jv values|]

  let clear_color c red green blue alpha =
    ignore @@ Jv.call c "clearColor" Jv.[|of_float red; of_float green; of_float blue; of_float alpha|]

  let clear_depth c depth =
    ignore @@ Jv.call c "clearDepth" Jv.[|of_float depth|]

  let clear_stencil c s =
    ignore @@ Jv.call c "clearStencil" Jv.[|of_int s|]

  let client_wait_sync c sync flags timeout =
    Jv.to_int @@ Jv.call c "clientWaitSync" Jv.[|sync; of_int flags; of_int timeout|]

  let color_mask c red green blue alpha =
    ignore @@ Jv.call c "colorMask" [|Jv.of_bool red; Jv.of_bool green; Jv.of_bool blue; Jv.of_bool alpha|]

  let compile_shader c shader =
    ignore @@ Jv.call c "compileShader" [|shader|]

  let compressed_tex_image2d c target level internalformat width height border srcData =
    ignore @@ Jv.call c "compressedTexImage2D" Jv.[|of_int target; of_int level; of_int internalformat; of_int width; of_int height; of_int border; Tarray.to_jv srcData|]

  let compressed_tex_image2d_size c target level internalformat width height border imageSize offset =
    ignore @@ Jv.call c "compressedTexImage2D" Jv.[|of_int target; of_int level; of_int internalformat; of_int width; of_int height; of_int border; of_int imageSize; of_int offset|]

  let compressed_tex_image3d c target level internalformat width height depth border srcData =
    ignore @@ Jv.call c "compressedTexImage3D" Jv.[|of_int target; of_int level; of_int internalformat; of_int width; of_int height; of_int depth; of_int border; Tarray.to_jv srcData|]

  let compressed_tex_image3d_size c target level internalformat width height depth border imageSize offset =
    ignore @@ Jv.call c "compressedTexImage3D" Jv.[|of_int target; of_int level; of_int internalformat; of_int width; of_int height; of_int depth; of_int border; of_int imageSize; of_int offset|]

  let compressed_tex_sub_image2d c target level xoffset yoffset width height format srcData =
    ignore @@ Jv.call c "compressedTexSubImage2D" Jv.[|of_int target; of_int level; of_int xoffset; of_int yoffset; of_int width; of_int height; of_int format; Tarray.to_jv srcData|]

  let compressed_tex_sub_image2d_size c target level xoffset yoffset width height format imageSize offset =
    ignore @@ Jv.call c "compressedTexSubImage2D" Jv.[|of_int target; of_int level; of_int xoffset; of_int yoffset; of_int width; of_int height; of_int format; of_int imageSize; of_int offset|]

  let compressed_tex_sub_image3d c target level xoffset yoffset zoffset width height depth format srcData =
    ignore @@ Jv.call c "compressedTexSubImage3D" Jv.[|of_int target; of_int level; of_int xoffset; of_int yoffset; of_int zoffset; of_int width; of_int height; of_int depth; of_int format; Tarray.to_jv srcData|]

  let compressed_tex_sub_image3d_size c target level xoffset yoffset zoffset width height depth format imageSize offset =
    ignore @@ Jv.call c "compressedTexSubImage3D" Jv.[|of_int target; of_int level; of_int xoffset; of_int yoffset; of_int zoffset; of_int width; of_int height; of_int depth; of_int format; of_int imageSize; of_int offset|]

  let copy_buffer_sub_data c readTarget writeTarget readOffset writeOffset size =
    ignore @@ Jv.call c "copyBufferSubData" Jv.[|of_int readTarget; of_int writeTarget; of_int readOffset; of_int writeOffset; of_int size|]

  let copy_tex_image2d c target level internalformat x y width height border =
    ignore @@ Jv.call c "copyTexImage2D" Jv.[|of_int target; of_int level; of_int internalformat; of_int x; of_int y; of_int width; of_int height; of_int border|]

  let copy_tex_sub_image2d c target level xoffset yoffset x y width height =
    ignore @@ Jv.call c "copyTexSubImage2D" Jv.[|of_int target; of_int level; of_int xoffset; of_int yoffset; of_int x; of_int y; of_int width; of_int height|]

  let copy_tex_sub_image3d c target level xoffset yoffset zoffset x y width height =
    ignore @@ Jv.call c "copyTexSubImage3D" Jv.[|of_int target; of_int level; of_int xoffset; of_int yoffset; of_int zoffset; of_int x; of_int y; of_int width; of_int height|]

  let create_buffer c  =
    Jv.call c "createBuffer" [||]

  let create_framebuffer c  =
    Jv.call c "createFramebuffer" [||]

  let create_program c  =
    Jv.call c "createProgram" [||]

  let create_query c  =
    Jv.call c "createQuery" [||]

  let create_renderbuffer c  =
    Jv.call c "createRenderbuffer" [||]

  let create_sampler c  =
    Jv.call c "createSampler" [||]

  let create_shader c type' =
    Jv.call c "createShader" Jv.[|of_int type'|]

  let create_texture c  =
    Jv.call c "createTexture" [||]

  let create_transform_feedback c  =
    Jv.call c "createTransformFeedback" [||]

  let create_vertex_array c  =
    Jv.call c "createVertexArray" [||]

  let cull_face c mode =
    ignore @@ Jv.call c "cullFace" Jv.[|of_int mode|]

  let delete_buffer c buffer =
    ignore @@ Jv.call c "deleteBuffer" [|buffer|]

  let delete_framebuffer c framebuffer =
    ignore @@ Jv.call c "deleteFramebuffer" [|framebuffer|]

  let delete_program c program =
    ignore @@ Jv.call c "deleteProgram" [|program|]

  let delete_query c query =
    ignore @@ Jv.call c "deleteQuery" [|query|]

  let delete_renderbuffer c renderbuffer =
    ignore @@ Jv.call c "deleteRenderbuffer" [|renderbuffer|]

  let delete_sampler c sampler =
    ignore @@ Jv.call c "deleteSampler" [|sampler|]

  let delete_shader c shader =
    ignore @@ Jv.call c "deleteShader" [|shader|]

  let delete_sync c sync =
    ignore @@ Jv.call c "deleteSync" [|sync|]

  let delete_texture c texture =
    ignore @@ Jv.call c "deleteTexture" [|texture|]

  let delete_transform_feedback c tf =
    ignore @@ Jv.call c "deleteTransformFeedback" [|tf|]

  let delete_vertex_array c vertexArray =
    ignore @@ Jv.call c "deleteVertexArray" [|vertexArray|]

  let depth_func c func =
    ignore @@ Jv.call c "depthFunc" Jv.[|of_int func|]

  let depth_mask c flag =
    ignore @@ Jv.call c "depthMask" [|Jv.of_bool flag|]

  (* let depth_range c zNear zFar = *)
  (*   ignore @@ Jv.call c "depthRange" Jv.[|of_float zNear; of_float zFar|] *)

  let detach_shader c program shader =
    ignore @@ Jv.call c "detachShader" [|program; shader|]

  let disable c cap =
    ignore @@ Jv.call c "disable" Jv.[|of_int cap|]

  let disable_vertex_attrib_array c index =
    ignore @@ Jv.call c "disableVertexAttribArray" Jv.[|of_int index|]

  let draw_arrays c mode first count =
    ignore @@ Jv.call c "drawArrays" Jv.[|of_int mode; of_int first; of_int count|]

  let draw_arrays_instanced c mode first count instanceCount =
    ignore @@ Jv.call c "drawArraysInstanced" Jv.[|of_int mode; of_int first; of_int count; of_int instanceCount|]

  let draw_buffers c buffers =
    ignore @@ Jv.call c "drawBuffers" Jv.[|of_list of_int buffers|]

  let draw_elements c mode count type' offset =
    ignore @@ Jv.call c "drawElements" Jv.[|of_int mode; of_int count; of_int type'; of_int offset|]

  let draw_elements_instanced c mode count type' offset instanceCount =
    ignore @@ Jv.call c "drawElementsInstanced" Jv.[|of_int mode; of_int count; of_int type'; of_int offset; of_int instanceCount|]

  let draw_range_elements c mode start end' count type' offset =
    ignore @@ Jv.call c "drawRangeElements" Jv.[|of_int mode; of_int start; of_int end'; of_int count; of_int type'; of_int offset|]

  let enable c cap =
    ignore @@ Jv.call c "enable" Jv.[|of_int cap|]

  let enable_vertex_attrib_array c index =
    ignore @@ Jv.call c "enableVertexAttribArray" Jv.[|of_int index|]

  let end_query c target =
    ignore @@ Jv.call c "endQuery" Jv.[|of_int target|]

  let end_transform_feedback c  =
    ignore @@ Jv.call c "endTransformFeedback" [||]

  let fence_sync c condition flags =
    Jv.call c "fenceSync" Jv.[|of_int condition; of_int flags|]

  let finish c  =
    ignore @@ Jv.call c "finish" [||]

  let flush c  =
    ignore @@ Jv.call c "flush" [||]

  let framebuffer_renderbuffer c target attachment renderbuffertarget renderbuffer =
    ignore @@ Jv.call c "framebufferRenderbuffer" Jv.[|of_int target; of_int attachment; of_int renderbuffertarget; renderbuffer|]

  let framebuffer_texture2d c target attachment textarget texture level =
    ignore @@ Jv.call c "framebufferTexture2D" Jv.[|of_int target; of_int attachment; of_int textarget; texture; of_int level|]

  let framebuffer_texture_layer c target attachment texture level layer =
    ignore @@ Jv.call c "framebufferTextureLayer" Jv.[|of_int target; of_int attachment; texture; of_int level; of_int layer|]

  let front_face c mode =
    ignore @@ Jv.call c "frontFace" Jv.[|of_int mode|]

  let generate_mipmap c target =
    ignore @@ Jv.call c "generateMipmap" Jv.[|of_int target|]

  let get_active_attrib c program index =
    Jv.call c "getActiveAttrib" Jv.[|program; of_int index|]

  let get_active_uniform c program index =
    Jv.call c "getActiveUniform" Jv.[|program; of_int index|]

  let get_active_uniform_block_name c program uniformBlockIndex =
    Jv.to_jstr @@ Jv.call c "getActiveUniformBlockName" Jv.[|program; of_int uniformBlockIndex|]

  let get_active_uniform_block_parameter c program uniformBlockIndex pname =
    Jv.call c "getActiveUniformBlockParameter" Jv.[|program; of_int uniformBlockIndex; of_int pname|]

  let get_active_uniforms c program uniformIndices pname =
    Jv.call c "getActiveUniforms" Jv.[|program; of_list of_int uniformIndices; of_int pname|]

  let get_attached_shaders c program =
    Jv.to_jv_list @@ Jv.call c "getAttachedShaders" [|program|]

  let get_attrib_location c program name =
    Jv.to_int @@ Jv.call c "getAttribLocation" Jv.[|program; of_jstr name|]

  let get_buffer_parameter c target pname =
    Jv.call c "getBufferParameter" Jv.[|of_int target; of_int pname|]

  let get_buffer_sub_data c target srcByteOffset dstBuffer =
    ignore @@ Jv.call c "getBufferSubData" Jv.[|of_int target; of_int srcByteOffset; Tarray.to_jv dstBuffer|]

  let get_error c  =
    Jv.to_int @@ Jv.call c "getError" [||]

  let get_frag_data_location c program name =
    Jv.to_int @@ Jv.call c "getFragDataLocation" Jv.[|program; of_jstr name|]

  let get_framebuffer_attachment_parameter c target attachment pname =
    Jv.call c "getFramebufferAttachmentParameter" Jv.[|of_int target; of_int attachment; of_int pname|]

  let get_indexed_parameter c target index =
    Jv.call c "getIndexedParameter" Jv.[|of_int target; of_int index|]

  let get_internalformat_parameter c target internalformat pname =
    Jv.call c "getInternalformatParameter" Jv.[|of_int target; of_int internalformat; of_int pname|]

  let get_parameter c pname =
    Jv.call c "getParameter" Jv.[|of_int pname|]

  let get_program_info_log c program =
    Jv.to_jstr @@ Jv.call c "getProgramInfoLog" [|program|]

  let get_program_parameter c program pname =
    Jv.call c "getProgramParameter" Jv.[|program; of_int pname|]

  let get_query c target pname =
    Jv.call c "getQuery" Jv.[|of_int target; of_int pname|]

  let get_query_parameter c query pname =
    Jv.call c "getQueryParameter" Jv.[|query; of_int pname|]

  let get_renderbuffer_parameter c target pname =
    Jv.call c "getRenderbufferParameter" Jv.[|of_int target; of_int pname|]

  let get_sampler_parameter c sampler pname =
    Jv.call c "getSamplerParameter" Jv.[|sampler; of_int pname|]

  let get_shader_info_log c shader =
    Jv.to_jstr @@ Jv.call c "getShaderInfoLog" [|shader|]

  let get_shader_parameter c shader pname =
    Jv.call c "getShaderParameter" Jv.[|shader; of_int pname|]

  let get_shader_precision_format c shadertype precisiontype =
    Jv.call c "getShaderPrecisionFormat" Jv.[|of_int shadertype; of_int precisiontype|]

  let get_shader_source c shader =
    Jv.to_jstr @@ Jv.call c "getShaderSource" [|shader|]

  let get_sync_parameter c sync pname =
    Jv.call c "getSyncParameter" Jv.[|sync; of_int pname|]

  let get_tex_parameter c target pname =
    Jv.call c "getTexParameter" Jv.[|of_int target; of_int pname|]

  let get_transform_feedback_varying c program index =
    Jv.call c "getTransformFeedbackVarying" Jv.[|program; of_int index|]

  let get_uniform c program location =
    Jv.call c "getUniform" [|program; location|]

  let get_uniform_block_index c program uniformBlockName =
    Jv.to_int @@ Jv.call c "getUniformBlockIndex" Jv.[|program; of_jstr uniformBlockName|]

  let get_uniform_indices c program uniformNames =
    Jv.to_list Jv.to_int @@ Jv.call c "getUniformIndices" Jv.[|program; of_jstr_list uniformNames|]

  let get_uniform_location c program name =
    Jv.call c "getUniformLocation" Jv.[|program; of_jstr name|]

  let get_vertex_attrib c index pname =
    Jv.call c "getVertexAttrib" Jv.[|of_int index; of_int pname|]

  let get_vertex_attrib_offset c index pname =
    Jv.to_int @@ Jv.call c "getVertexAttribOffset" Jv.[|of_int index; of_int pname|]

  let hint c target mode =
    ignore @@ Jv.call c "hint" Jv.[|of_int target; of_int mode|]

  let invalidate_framebuffer c target attachments =
    ignore @@ Jv.call c "invalidateFramebuffer" Jv.[|of_int target; of_list of_int attachments|]

  let invalidate_sub_framebuffer c target attachments x y width height =
    ignore @@ Jv.call c "invalidateSubFramebuffer" Jv.[|of_int target; of_list of_int attachments; of_int x; of_int y; of_int width; of_int height|]

  let is_buffer c buffer =
    Jv.to_bool @@ Jv.call c "isBuffer" [|buffer|]

  let is_enabled c cap =
    Jv.to_bool @@ Jv.call c "isEnabled" Jv.[|of_int cap|]

  let is_framebuffer c framebuffer =
    Jv.to_bool @@ Jv.call c "isFramebuffer" [|framebuffer|]

  let is_program c program =
    Jv.to_bool @@ Jv.call c "isProgram" [|program|]

  let is_query c query =
    Jv.to_bool @@ Jv.call c "isQuery" [|query|]

  let is_renderbuffer c renderbuffer =
    Jv.to_bool @@ Jv.call c "isRenderbuffer" [|renderbuffer|]

  let is_sampler c sampler =
    Jv.to_bool @@ Jv.call c "isSampler" [|sampler|]

  let is_shader c shader =
    Jv.to_bool @@ Jv.call c "isShader" [|shader|]

  let is_texture c texture =
    Jv.to_bool @@ Jv.call c "isTexture" [|texture|]

  let is_transform_feedback c tf =
    Jv.to_bool @@ Jv.call c "isTransformFeedback" [|tf|]

  let is_vertex_array c vertexArray =
    Jv.to_bool @@ Jv.call c "isVertexArray" [|vertexArray|]

  let line_width c width =
    ignore @@ Jv.call c "lineWidth" Jv.[|of_float width|]

  let link_program c program =
    ignore @@ Jv.call c "linkProgram" [|program|]

  let pause_transform_feedback c  =
    ignore @@ Jv.call c "pauseTransformFeedback" [||]

  let pixel_storei c pname param =
    ignore @@ Jv.call c "pixelStorei" Jv.[|of_int pname; of_int param|]

  let polygon_offset c factor units =
    ignore @@ Jv.call c "polygonOffset" Jv.[|of_float factor; of_float units|]

  let read_buffer c src =
    ignore @@ Jv.call c "readBuffer" Jv.[|of_int src|]

  let read_pixels_to_pixel_pack c x y width height format type' offset =
    ignore @@ Jv.call c "readPixels" Jv.[|of_int x; of_int y; of_int width; of_int height; of_int format; of_int type'; of_int offset|]

  let read_pixels c x y width height format type' dstData =
    ignore @@ Jv.call c "readPixels" Jv.[|of_int x; of_int y; of_int width; of_int height; of_int format; of_int type'; Tarray.to_jv dstData|]

  let renderbuffer_storage c target internalformat width height =
    ignore @@ Jv.call c "renderbufferStorage" Jv.[|of_int target; of_int internalformat; of_int width; of_int height|]

  let renderbuffer_storage_multisample c target samples internalformat width height =
    ignore @@ Jv.call c "renderbufferStorageMultisample" Jv.[|of_int target; of_int samples; of_int internalformat; of_int width; of_int height|]

  let resume_transform_feedback c  =
    ignore @@ Jv.call c "resumeTransformFeedback" [||]

  let sample_coverage c value invert =
    ignore @@ Jv.call c "sampleCoverage" Jv.[|of_float value; Jv.of_bool invert|]

  let sampler_parameterf c sampler pname param =
    ignore @@ Jv.call c "samplerParameterf" Jv.[|sampler; of_int pname; of_float param|]

  let sampler_parameteri c sampler pname param =
    ignore @@ Jv.call c "samplerParameteri" Jv.[|sampler; of_int pname; of_int param|]

  let scissor c x y width height =
    ignore @@ Jv.call c "scissor" Jv.[|of_int x; of_int y; of_int width; of_int height|]

  let shader_source c shader source =
    ignore @@ Jv.call c "shaderSource" Jv.[|shader; of_jstr source|]

  let stencil_func c func ref mask =
    ignore @@ Jv.call c "stencilFunc" Jv.[|of_int func; of_int ref; of_int mask|]

  let stencil_func_separate c face func ref mask =
    ignore @@ Jv.call c "stencilFuncSeparate" Jv.[|of_int face; of_int func; of_int ref; of_int mask|]

  let stencil_mask c mask =
    ignore @@ Jv.call c "stencilMask" Jv.[|of_int mask|]

  let stencil_mask_separate c face mask =
    ignore @@ Jv.call c "stencilMaskSeparate" Jv.[|of_int face; of_int mask|]

  let stencil_op c fail zfail zpass =
    ignore @@ Jv.call c "stencilOp" Jv.[|of_int fail; of_int zfail; of_int zpass|]

  let stencil_op_separate c face fail zfail zpass =
    ignore @@ Jv.call c "stencilOpSeparate" Jv.[|of_int face; of_int fail; of_int zfail; of_int zpass|]

  let tex_image2d c target level internalformat width height border format type' srcData srcOffset =
    ignore @@ Jv.call c "texImage2D" Jv.[|of_int target; of_int level; of_int internalformat; of_int width; of_int height; of_int border; of_int format; of_int type'; Tarray.to_jv srcData; of_int srcOffset|]

  let tex_image2d_of_source c target level internalformat width height border format type' source =
    ignore @@ Jv.call c "texImage2D" Jv.[|of_int target; of_int level; of_int internalformat; of_int width; of_int height; of_int border; of_int format; of_int type'; source|]

  let tex_image2d_of_pixel_unpack c target level internalformat width height border format type' pboOffset =
    ignore @@ Jv.call c "texImage2D" Jv.[|of_int target; of_int level; of_int internalformat; of_int width; of_int height; of_int border; of_int format; of_int type'; of_int pboOffset|]

  let tex_image3d c target level internalformat width height depth border format type' srcData srcOffset =
    ignore @@ Jv.call c "texImage3D" Jv.[|of_int target; of_int level; of_int internalformat; of_int width; of_int height; of_int depth; of_int border; of_int format; of_int type'; Tarray.to_jv srcData; of_int srcOffset|]

  let tex_image3d_of_source c target level internalformat width height depth border format type' source =
    ignore @@ Jv.call c "texImage3D" Jv.[|of_int target; of_int level; of_int internalformat; of_int width; of_int height; of_int depth; of_int border; of_int format; of_int type'; source|]

  let tex_image3d_of_pixel_unpack c target level internalformat width height depth border format type' pboOffset =
    ignore @@ Jv.call c "texImage3D" Jv.[|of_int target; of_int level; of_int internalformat; of_int width; of_int height; of_int depth; of_int border; of_int format; of_int type'; of_int pboOffset|]

  let tex_parameterf c target pname param =
    ignore @@ Jv.call c "texParameterf" Jv.[|of_int target; of_int pname; of_float param|]

  let tex_parameteri c target pname param =
    ignore @@ Jv.call c "texParameteri" Jv.[|of_int target; of_int pname; of_int param|]

  let tex_storage2d c target levels internalformat width height =
    ignore @@ Jv.call c "texStorage2D" Jv.[|of_int target; of_int levels; of_int internalformat; of_int width; of_int height|]

  let tex_storage3d c target levels internalformat width height depth =
    ignore @@ Jv.call c "texStorage3D" Jv.[|of_int target; of_int levels; of_int internalformat; of_int width; of_int height; of_int depth|]

  let tex_sub_image2d c target level xoffset yoffset width height format type' srcData srcOffset =
    ignore @@ Jv.call c "texSubImage2D" Jv.[|of_int target; of_int level; of_int xoffset; of_int yoffset; of_int width; of_int height; of_int format; of_int type'; Tarray.to_jv srcData; of_int srcOffset|]

  let tex_sub_image2d_of_source c target level xoffset yoffset width height format type' source =
    ignore @@ Jv.call c "texSubImage2D" Jv.[|of_int target; of_int level; of_int xoffset; of_int yoffset; of_int width; of_int height; of_int format; of_int type'; source|]

  let tex_sub_image2d_of_pixel_unpack c target level xoffset yoffset width height format type' pboOffset =
    ignore @@ Jv.call c "texSubImage2D" Jv.[|of_int target; of_int level; of_int xoffset; of_int yoffset; of_int width; of_int height; of_int format; of_int type'; of_int pboOffset|]

  let tex_sub_image3d c target level xoffset yoffset zoffset width height depth format type' srcData =
    ignore @@ Jv.call c "texSubImage3D" Jv.[|of_int target; of_int level; of_int xoffset; of_int yoffset; of_int zoffset; of_int width; of_int height; of_int depth; of_int format; of_int type'; Tarray.to_jv srcData|]

  let tex_sub_image3d_of_source c target level xoffset yoffset zoffset width height depth format type' source =
    ignore @@ Jv.call c "texSubImage3D" Jv.[|of_int target; of_int level; of_int xoffset; of_int yoffset; of_int zoffset; of_int width; of_int height; of_int depth; of_int format; of_int type'; source|]

  let tex_sub_image3d_of_pixel_unpack c target level xoffset yoffset zoffset width height depth format type' pboOffset =
    ignore @@ Jv.call c "texSubImage3D" Jv.[|of_int target; of_int level; of_int xoffset; of_int yoffset; of_int zoffset; of_int width; of_int height; of_int depth; of_int format; of_int type'; of_int pboOffset|]

  let transform_feedback_varyings c program varyings bufferMode =
    ignore @@ Jv.call c "transformFeedbackVaryings" Jv.[|program; of_jstr_list varyings; of_int bufferMode|]

  let uniform1f c location x =
    ignore @@ Jv.call c "uniform1f" Jv.[|location; of_float x|]

  let uniform1fv c location data =
    ignore @@ Jv.call c "uniform1fv" [|location; Tarray.to_jv data|]

  let uniform1i c location x =
    ignore @@ Jv.call c "uniform1i" Jv.[|location; of_int x|]

  let uniform1iv c location data =
    ignore @@ Jv.call c "uniform1iv" [|location; Tarray.to_jv data|]

  let uniform1ui c location v0 =
    ignore @@ Jv.call c "uniform1ui" Jv.[|location; of_int v0|]

  let uniform1uiv c location data =
    ignore @@ Jv.call c "uniform1uiv" [|location; Tarray.to_jv data|]

  let uniform2f c location x y =
    ignore @@ Jv.call c "uniform2f" Jv.[|location; of_float x; of_float y|]

  let uniform2fv c location data =
    ignore @@ Jv.call c "uniform2fv" [|location; Tarray.to_jv data|]

  let uniform2i c location x y =
    ignore @@ Jv.call c "uniform2i" Jv.[|location; of_int x; of_int y|]

  let uniform2iv c location data =
    ignore @@ Jv.call c "uniform2iv" [|location; Tarray.to_jv data|]

  let uniform2ui c location v0 v1 =
    ignore @@ Jv.call c "uniform2ui" Jv.[|location; of_int v0; of_int v1|]

  let uniform2uiv c location data =
    ignore @@ Jv.call c "uniform2uiv" [|location; Tarray.to_jv data|]

  let uniform3f c location x y z =
    ignore @@ Jv.call c "uniform3f" Jv.[|location; of_float x; of_float y; of_float z|]

  let uniform3fv c location data =
    ignore @@ Jv.call c "uniform3fv" [|location; Tarray.to_jv data|]

  let uniform3i c location x y z =
    ignore @@ Jv.call c "uniform3i" Jv.[|location; of_int x; of_int y; of_int z|]

  let uniform3iv c location data =
    ignore @@ Jv.call c "uniform3iv" [|location; Tarray.to_jv data|]

  let uniform3ui c location v0 v1 v2 =
    ignore @@ Jv.call c "uniform3ui" Jv.[|location; of_int v0; of_int v1; of_int v2|]

  let uniform3uiv c location data =
    ignore @@ Jv.call c "uniform3uiv" [|location; Tarray.to_jv data|]

  let uniform4f c location x y z w =
    ignore @@ Jv.call c "uniform4f" Jv.[|location; of_float x; of_float y; of_float z; of_float w|]

  let uniform4fv c location data =
    ignore @@ Jv.call c "uniform4fv" [|location; Tarray.to_jv data|]

  let uniform4i c location x y z w =
    ignore @@ Jv.call c "uniform4i" Jv.[|location; of_int x; of_int y; of_int z; of_int w|]

  let uniform4iv c location data =
    ignore @@ Jv.call c "uniform4iv" [|location; Tarray.to_jv data|]

  let uniform4ui c location v0 v1 v2 v3 =
    ignore @@ Jv.call c "uniform4ui" Jv.[|location; of_int v0; of_int v1; of_int v2; of_int v3|]

  let uniform4uiv c location data =
    ignore @@ Jv.call c "uniform4uiv" [|location; Tarray.to_jv data|]

  let uniform_block_binding c program uniformBlockIndex uniformBlockBinding =
    ignore @@ Jv.call c "uniformBlockBinding" Jv.[|program; of_int uniformBlockIndex; of_int uniformBlockBinding|]

  let uniform_matrix2fv c location transpose data =
    ignore @@ Jv.call c "uniformMatrix2fv" [|location; Jv.of_bool transpose; Tarray.to_jv data|]

  let uniform_matrix2x3fv c location transpose data =
    ignore @@ Jv.call c "uniformMatrix2x3fv" [|location; Jv.of_bool transpose; Tarray.to_jv data|]

  let uniform_matrix2x4fv c location transpose data =
    ignore @@ Jv.call c "uniformMatrix2x4fv" [|location; Jv.of_bool transpose; Tarray.to_jv data|]

  let uniform_matrix3fv c location transpose data =
    ignore @@ Jv.call c "uniformMatrix3fv" [|location; Jv.of_bool transpose; Tarray.to_jv data|]

  let uniform_matrix3x2fv c location transpose data =
    ignore @@ Jv.call c "uniformMatrix3x2fv" [|location; Jv.of_bool transpose; Tarray.to_jv data|]

  let uniform_matrix3x4fv c location transpose data =
    ignore @@ Jv.call c "uniformMatrix3x4fv" [|location; Jv.of_bool transpose; Tarray.to_jv data|]

  let uniform_matrix4fv c location transpose data =
    ignore @@ Jv.call c "uniformMatrix4fv" [|location; Jv.of_bool transpose; Tarray.to_jv data|]

  let uniform_matrix4x2fv c location transpose data =
    ignore @@ Jv.call c "uniformMatrix4x2fv" [|location; Jv.of_bool transpose; Tarray.to_jv data|]

  let uniform_matrix4x3fv c location transpose data =
    ignore @@ Jv.call c "uniformMatrix4x3fv" [|location; Jv.of_bool transpose; Tarray.to_jv data|]

  let use_program c program =
    ignore @@ Jv.call c "useProgram" [|program|]

  let validate_program c program =
    ignore @@ Jv.call c "validateProgram" [|program|]

  let vertex_attrib1f c index x =
    ignore @@ Jv.call c "vertexAttrib1f" Jv.[|of_int index; of_float x|]

  let vertex_attrib1fv c index values =
    ignore @@ Jv.call c "vertexAttrib1fv" Jv.[|of_int index; Tarray.to_jv values|]

  let vertex_attrib2f c index x y =
    ignore @@ Jv.call c "vertexAttrib2f" Jv.[|of_int index; of_float x; of_float y|]

  let vertex_attrib2fv c index values =
    ignore @@ Jv.call c "vertexAttrib2fv" Jv.[|of_int index; Tarray.to_jv values|]

  let vertex_attrib3f c index x y z =
    ignore @@ Jv.call c "vertexAttrib3f" Jv.[|of_int index; of_float x; of_float y; of_float z|]

  let vertex_attrib3fv c index values =
    ignore @@ Jv.call c "vertexAttrib3fv" Jv.[|of_int index; Tarray.to_jv values|]

  let vertex_attrib4f c index x y z w =
    ignore @@ Jv.call c "vertexAttrib4f" Jv.[|of_int index; of_float x; of_float y; of_float z; of_float w|]

  let vertex_attrib4fv c index values =
    ignore @@ Jv.call c "vertexAttrib4fv" Jv.[|of_int index; Tarray.to_jv values|]

  let vertex_attrib_divisor c index divisor =
    ignore @@ Jv.call c "vertexAttribDivisor" Jv.[|of_int index; of_int divisor|]

  let vertex_attrib_i4i c index x y z w =
    ignore @@ Jv.call c "vertexAttribI4i" Jv.[|of_int index; of_int x; of_int y; of_int z; of_int w|]

  let vertex_attrib_i4iv c index values =
    ignore @@ Jv.call c "vertexAttribI4iv" Jv.[|of_int index; Tarray.to_jv values|]

  let vertex_attrib_i4ui c index x y z w =
    ignore @@ Jv.call c "vertexAttribI4ui" Jv.[|of_int index; of_int x; of_int y; of_int z; of_int w|]

  let vertex_attrib_i4uiv c index values =
    ignore @@ Jv.call c "vertexAttribI4uiv" Jv.[|of_int index; Tarray.to_jv values|]

  let vertex_attrib_ipointer c index size type' stride offset =
    ignore @@ Jv.call c "vertexAttribIPointer" Jv.[|of_int index; of_int size; of_int type'; of_int stride; of_int offset|]

  let vertex_attrib_pointer c index size type' normalized stride offset =
    ignore @@ Jv.call c "vertexAttribPointer" Jv.[|of_int index; of_int size; of_int type'; Jv.of_bool normalized; of_int stride; of_int offset|]

  let viewport c x y width height =
    ignore @@ Jv.call c "viewport" Jv.[|of_int x; of_int y; of_int width; of_int height|]

  let wait_sync c sync flags timeout =
    ignore @@ Jv.call c "waitSync" Jv.[|sync; of_int flags; of_int timeout|]

  (* Enums *)

  let get_int ctx f = if Jv.is_none ctx then 0 else Jv.Int.get ctx f

  let gl1ctx = Jv.get Jv.global "WebGLRenderingContext"
  let depth_buffer_bit = get_int gl1ctx "DEPTH_BUFFER_BIT"
  let stencil_buffer_bit = get_int gl1ctx "STENCIL_BUFFER_BIT"
  let color_buffer_bit = get_int gl1ctx "COLOR_BUFFER_BIT"
  let points = get_int gl1ctx "POINTS"
  let lines = get_int gl1ctx "LINES"
  let line_loop = get_int gl1ctx "LINE_LOOP"
  let line_strip = get_int gl1ctx "LINE_STRIP"
  let triangles = get_int gl1ctx "TRIANGLES"
  let triangle_strip = get_int gl1ctx "TRIANGLE_STRIP"
  let triangle_fan = get_int gl1ctx "TRIANGLE_FAN"
  let zero = get_int gl1ctx "ZERO"
  let one = get_int gl1ctx "ONE"
  let src_color = get_int gl1ctx "SRC_COLOR"
  let one_minus_src_color = get_int gl1ctx "ONE_MINUS_SRC_COLOR"
  let src_alpha = get_int gl1ctx "SRC_ALPHA"
  let one_minus_src_alpha = get_int gl1ctx "ONE_MINUS_SRC_ALPHA"
  let dst_alpha = get_int gl1ctx "DST_ALPHA"
  let one_minus_dst_alpha = get_int gl1ctx "ONE_MINUS_DST_ALPHA"
  let dst_color = get_int gl1ctx "DST_COLOR"
  let one_minus_dst_color = get_int gl1ctx "ONE_MINUS_DST_COLOR"
  let src_alpha_saturate = get_int gl1ctx "SRC_ALPHA_SATURATE"
  let func_add = get_int gl1ctx "FUNC_ADD"
  let blend_equation' = get_int gl1ctx "BLEND_EQUATION"
  let blend_equation_rgb = get_int gl1ctx "BLEND_EQUATION_RGB"
  let blend_equation_alpha = get_int gl1ctx "BLEND_EQUATION_ALPHA"
  let func_subtract = get_int gl1ctx "FUNC_SUBTRACT"
  let func_reverse_subtract = get_int gl1ctx "FUNC_REVERSE_SUBTRACT"
  let blend_dst_rgb = get_int gl1ctx "BLEND_DST_RGB"
  let blend_src_rgb = get_int gl1ctx "BLEND_SRC_RGB"
  let blend_dst_alpha = get_int gl1ctx "BLEND_DST_ALPHA"
  let blend_src_alpha = get_int gl1ctx "BLEND_SRC_ALPHA"
  let constant_color = get_int gl1ctx "CONSTANT_COLOR"
  let one_minus_constant_color = get_int gl1ctx "ONE_MINUS_CONSTANT_COLOR"
  let constant_alpha = get_int gl1ctx "CONSTANT_ALPHA"
  let one_minus_constant_alpha = get_int gl1ctx "ONE_MINUS_CONSTANT_ALPHA"
  let blend_color' = get_int gl1ctx "BLEND_COLOR"
  let array_buffer = get_int gl1ctx "ARRAY_BUFFER"
  let element_array_buffer = get_int gl1ctx "ELEMENT_ARRAY_BUFFER"
  let array_buffer_binding = get_int gl1ctx "ARRAY_BUFFER_BINDING"
  let element_array_buffer_binding = get_int gl1ctx "ELEMENT_ARRAY_BUFFER_BINDING"
  let stream_draw = get_int gl1ctx "STREAM_DRAW"
  let static_draw = get_int gl1ctx "STATIC_DRAW"
  let dynamic_draw = get_int gl1ctx "DYNAMIC_DRAW"
  let buffer_size = get_int gl1ctx "BUFFER_SIZE"
  let buffer_usage = get_int gl1ctx "BUFFER_USAGE"
  let current_vertex_attrib = get_int gl1ctx "CURRENT_VERTEX_ATTRIB"
  let front = get_int gl1ctx "FRONT"
  let back = get_int gl1ctx "BACK"
  let front_and_back = get_int gl1ctx "FRONT_AND_BACK"
  let cull_face' = get_int gl1ctx "CULL_FACE"
  let blend = get_int gl1ctx "BLEND"
  let dither = get_int gl1ctx "DITHER"
  let stencil_test = get_int gl1ctx "STENCIL_TEST"
  let depth_test = get_int gl1ctx "DEPTH_TEST"
  let scissor_test = get_int gl1ctx "SCISSOR_TEST"
  let polygon_offset_fill = get_int gl1ctx "POLYGON_OFFSET_FILL"
  let sample_alpha_to_coverage = get_int gl1ctx "SAMPLE_ALPHA_TO_COVERAGE"
  let sample_coverage' = get_int gl1ctx "SAMPLE_COVERAGE"
  let no_error = get_int gl1ctx "NO_ERROR"
  let invalid_enum = get_int gl1ctx "INVALID_ENUM"
  let invalid_value = get_int gl1ctx "INVALID_VALUE"
  let invalid_operation = get_int gl1ctx "INVALID_OPERATION"
  let out_of_memory = get_int gl1ctx "OUT_OF_MEMORY"
  let cw = get_int gl1ctx "CW"
  let ccw = get_int gl1ctx "CCW"
  let line_width' = get_int gl1ctx "LINE_WIDTH"
  let aliased_point_size_range = get_int gl1ctx "ALIASED_POINT_SIZE_RANGE"
  let aliased_line_width_range = get_int gl1ctx "ALIASED_LINE_WIDTH_RANGE"
  let cull_face_mode = get_int gl1ctx "CULL_FACE_MODE"
  let front_face' = get_int gl1ctx "FRONT_FACE"
  let depth_range = get_int gl1ctx "DEPTH_RANGE"
  let depth_writemask = get_int gl1ctx "DEPTH_WRITEMASK"
  let depth_clear_value = get_int gl1ctx "DEPTH_CLEAR_VALUE"
  let depth_func' = get_int gl1ctx "DEPTH_FUNC"
  let stencil_clear_value = get_int gl1ctx "STENCIL_CLEAR_VALUE"
  let stencil_func' = get_int gl1ctx "STENCIL_FUNC"
  let stencil_fail = get_int gl1ctx "STENCIL_FAIL"
  let stencil_pass_depth_fail = get_int gl1ctx "STENCIL_PASS_DEPTH_FAIL"
  let stencil_pass_depth_pass = get_int gl1ctx "STENCIL_PASS_DEPTH_PASS"
  let stencil_ref = get_int gl1ctx "STENCIL_REF"
  let stencil_value_mask = get_int gl1ctx "STENCIL_VALUE_MASK"
  let stencil_writemask = get_int gl1ctx "STENCIL_WRITEMASK"
  let stencil_back_func = get_int gl1ctx "STENCIL_BACK_FUNC"
  let stencil_back_fail = get_int gl1ctx "STENCIL_BACK_FAIL"
  let stencil_back_pass_depth_fail = get_int gl1ctx "STENCIL_BACK_PASS_DEPTH_FAIL"
  let stencil_back_pass_depth_pass = get_int gl1ctx "STENCIL_BACK_PASS_DEPTH_PASS"
  let stencil_back_ref = get_int gl1ctx "STENCIL_BACK_REF"
  let stencil_back_value_mask = get_int gl1ctx "STENCIL_BACK_VALUE_MASK"
  let stencil_back_writemask = get_int gl1ctx "STENCIL_BACK_WRITEMASK"
  let viewport' = get_int gl1ctx "VIEWPORT"
  let scissor_box = get_int gl1ctx "SCISSOR_BOX"
  let color_clear_value = get_int gl1ctx "COLOR_CLEAR_VALUE"
  let color_writemask = get_int gl1ctx "COLOR_WRITEMASK"
  let unpack_alignment = get_int gl1ctx "UNPACK_ALIGNMENT"
  let pack_alignment = get_int gl1ctx "PACK_ALIGNMENT"
  let max_texture_size = get_int gl1ctx "MAX_TEXTURE_SIZE"
  let max_viewport_dims = get_int gl1ctx "MAX_VIEWPORT_DIMS"
  let subpixel_bits = get_int gl1ctx "SUBPIXEL_BITS"
  let red_bits = get_int gl1ctx "RED_BITS"
  let green_bits = get_int gl1ctx "GREEN_BITS"
  let blue_bits = get_int gl1ctx "BLUE_BITS"
  let alpha_bits = get_int gl1ctx "ALPHA_BITS"
  let depth_bits = get_int gl1ctx "DEPTH_BITS"
  let stencil_bits = get_int gl1ctx "STENCIL_BITS"
  let polygon_offset_units = get_int gl1ctx "POLYGON_OFFSET_UNITS"
  let polygon_offset_factor = get_int gl1ctx "POLYGON_OFFSET_FACTOR"
  let texture_binding_2d = get_int gl1ctx "TEXTURE_BINDING_2D"
  let sample_buffers = get_int gl1ctx "SAMPLE_BUFFERS"
  let samples = get_int gl1ctx "SAMPLES"
  let sample_coverage_value = get_int gl1ctx "SAMPLE_COVERAGE_VALUE"
  let sample_coverage_invert = get_int gl1ctx "SAMPLE_COVERAGE_INVERT"
  let compressed_texture_formats = get_int gl1ctx "COMPRESSED_TEXTURE_FORMATS"
  let dont_care = get_int gl1ctx "DONT_CARE"
  let fastest = get_int gl1ctx "FASTEST"
  let nicest = get_int gl1ctx "NICEST"
  let generate_mipmap_hint = get_int gl1ctx "GENERATE_MIPMAP_HINT"
  let byte = get_int gl1ctx "BYTE"
  let unsigned_byte = get_int gl1ctx "UNSIGNED_BYTE"
  let short = get_int gl1ctx "SHORT"
  let unsigned_short = get_int gl1ctx "UNSIGNED_SHORT"
  let int = get_int gl1ctx "INT"
  let unsigned_int = get_int gl1ctx "UNSIGNED_INT"
  let float = get_int gl1ctx "FLOAT"
  let depth_component = get_int gl1ctx "DEPTH_COMPONENT"
  let alpha = get_int gl1ctx "ALPHA"
  let rgb = get_int gl1ctx "RGB"
  let rgba = get_int gl1ctx "RGBA"
  let luminance = get_int gl1ctx "LUMINANCE"
  let luminance_alpha = get_int gl1ctx "LUMINANCE_ALPHA"
  let unsigned_short_4_4_4_4 = get_int gl1ctx "UNSIGNED_SHORT_4_4_4_4"
  let unsigned_short_5_5_5_1 = get_int gl1ctx "UNSIGNED_SHORT_5_5_5_1"
  let unsigned_short_5_6_5 = get_int gl1ctx "UNSIGNED_SHORT_5_6_5"
  let fragment_shader = get_int gl1ctx "FRAGMENT_SHADER"
  let vertex_shader = get_int gl1ctx "VERTEX_SHADER"
  let max_vertex_attribs = get_int gl1ctx "MAX_VERTEX_ATTRIBS"
  let max_vertex_uniform_vectors = get_int gl1ctx "MAX_VERTEX_UNIFORM_VECTORS"
  let max_varying_vectors = get_int gl1ctx "MAX_VARYING_VECTORS"
  let max_combined_texture_image_units = get_int gl1ctx "MAX_COMBINED_TEXTURE_IMAGE_UNITS"
  let max_vertex_texture_image_units = get_int gl1ctx "MAX_VERTEX_TEXTURE_IMAGE_UNITS"
  let max_texture_image_units = get_int gl1ctx "MAX_TEXTURE_IMAGE_UNITS"
  let max_fragment_uniform_vectors = get_int gl1ctx "MAX_FRAGMENT_UNIFORM_VECTORS"
  let shader_type = get_int gl1ctx "SHADER_TYPE"
  let delete_status = get_int gl1ctx "DELETE_STATUS"
  let link_status = get_int gl1ctx "LINK_STATUS"
  let validate_status = get_int gl1ctx "VALIDATE_STATUS"
  let attached_shaders = get_int gl1ctx "ATTACHED_SHADERS"
  let active_uniforms = get_int gl1ctx "ACTIVE_UNIFORMS"
  let active_attributes = get_int gl1ctx "ACTIVE_ATTRIBUTES"
  let shading_language_version = get_int gl1ctx "SHADING_LANGUAGE_VERSION"
  let current_program = get_int gl1ctx "CURRENT_PROGRAM"
  let never = get_int gl1ctx "NEVER"
  let less = get_int gl1ctx "LESS"
  let equal = get_int gl1ctx "EQUAL"
  let lequal = get_int gl1ctx "LEQUAL"
  let greater = get_int gl1ctx "GREATER"
  let notequal = get_int gl1ctx "NOTEQUAL"
  let gequal = get_int gl1ctx "GEQUAL"
  let always = get_int gl1ctx "ALWAYS"
  let keep = get_int gl1ctx "KEEP"
  let replace = get_int gl1ctx "REPLACE"
  let incr = get_int gl1ctx "INCR"
  let decr = get_int gl1ctx "DECR"
  let invert = get_int gl1ctx "INVERT"
  let incr_wrap = get_int gl1ctx "INCR_WRAP"
  let decr_wrap = get_int gl1ctx "DECR_WRAP"
  let vendor = get_int gl1ctx "VENDOR"
  let renderer = get_int gl1ctx "RENDERER"
  let version = get_int gl1ctx "VERSION"
  let nearest = get_int gl1ctx "NEAREST"
  let linear = get_int gl1ctx "LINEAR"
  let nearest_mipmap_nearest = get_int gl1ctx "NEAREST_MIPMAP_NEAREST"
  let linear_mipmap_nearest = get_int gl1ctx "LINEAR_MIPMAP_NEAREST"
  let nearest_mipmap_linear = get_int gl1ctx "NEAREST_MIPMAP_LINEAR"
  let linear_mipmap_linear = get_int gl1ctx "LINEAR_MIPMAP_LINEAR"
  let texture_mag_filter = get_int gl1ctx "TEXTURE_MAG_FILTER"
  let texture_min_filter = get_int gl1ctx "TEXTURE_MIN_FILTER"
  let texture_wrap_s = get_int gl1ctx "TEXTURE_WRAP_S"
  let texture_wrap_t = get_int gl1ctx "TEXTURE_WRAP_T"
  let texture_2d = get_int gl1ctx "TEXTURE_2D"
  let texture = get_int gl1ctx "TEXTURE"
  let texture_cube_map = get_int gl1ctx "TEXTURE_CUBE_MAP"
  let texture_binding_cube_map = get_int gl1ctx "TEXTURE_BINDING_CUBE_MAP"
  let texture_cube_map_positive_x = get_int gl1ctx "TEXTURE_CUBE_MAP_POSITIVE_X"
  let texture_cube_map_negative_x = get_int gl1ctx "TEXTURE_CUBE_MAP_NEGATIVE_X"
  let texture_cube_map_positive_y = get_int gl1ctx "TEXTURE_CUBE_MAP_POSITIVE_Y"
  let texture_cube_map_negative_y = get_int gl1ctx "TEXTURE_CUBE_MAP_NEGATIVE_Y"
  let texture_cube_map_positive_z = get_int gl1ctx "TEXTURE_CUBE_MAP_POSITIVE_Z"
  let texture_cube_map_negative_z = get_int gl1ctx "TEXTURE_CUBE_MAP_NEGATIVE_Z"
  let max_cube_map_texture_size = get_int gl1ctx "MAX_CUBE_MAP_TEXTURE_SIZE"
  let texture0 = get_int gl1ctx "TEXTURE0"
  let texture1 = get_int gl1ctx "TEXTURE1"
  let texture2 = get_int gl1ctx "TEXTURE2"
  let texture3 = get_int gl1ctx "TEXTURE3"
  let texture4 = get_int gl1ctx "TEXTURE4"
  let texture5 = get_int gl1ctx "TEXTURE5"
  let texture6 = get_int gl1ctx "TEXTURE6"
  let texture7 = get_int gl1ctx "TEXTURE7"
  let texture8 = get_int gl1ctx "TEXTURE8"
  let texture9 = get_int gl1ctx "TEXTURE9"
  let texture10 = get_int gl1ctx "TEXTURE10"
  let texture11 = get_int gl1ctx "TEXTURE11"
  let texture12 = get_int gl1ctx "TEXTURE12"
  let texture13 = get_int gl1ctx "TEXTURE13"
  let texture14 = get_int gl1ctx "TEXTURE14"
  let texture15 = get_int gl1ctx "TEXTURE15"
  let texture16 = get_int gl1ctx "TEXTURE16"
  let texture17 = get_int gl1ctx "TEXTURE17"
  let texture18 = get_int gl1ctx "TEXTURE18"
  let texture19 = get_int gl1ctx "TEXTURE19"
  let texture20 = get_int gl1ctx "TEXTURE20"
  let texture21 = get_int gl1ctx "TEXTURE21"
  let texture22 = get_int gl1ctx "TEXTURE22"
  let texture23 = get_int gl1ctx "TEXTURE23"
  let texture24 = get_int gl1ctx "TEXTURE24"
  let texture25 = get_int gl1ctx "TEXTURE25"
  let texture26 = get_int gl1ctx "TEXTURE26"
  let texture27 = get_int gl1ctx "TEXTURE27"
  let texture28 = get_int gl1ctx "TEXTURE28"
  let texture29 = get_int gl1ctx "TEXTURE29"
  let texture30 = get_int gl1ctx "TEXTURE30"
  let texture31 = get_int gl1ctx "TEXTURE31"
  let active_texture' = get_int gl1ctx "ACTIVE_TEXTURE"
  let repeat = get_int gl1ctx "REPEAT"
  let clamp_to_edge = get_int gl1ctx "CLAMP_TO_EDGE"
  let mirrored_repeat = get_int gl1ctx "MIRRORED_REPEAT"
  let float_vec2 = get_int gl1ctx "FLOAT_VEC2"
  let float_vec3 = get_int gl1ctx "FLOAT_VEC3"
  let float_vec4 = get_int gl1ctx "FLOAT_VEC4"
  let int_vec2 = get_int gl1ctx "INT_VEC2"
  let int_vec3 = get_int gl1ctx "INT_VEC3"
  let int_vec4 = get_int gl1ctx "INT_VEC4"
  let bool = get_int gl1ctx "BOOL"
  let bool_vec2 = get_int gl1ctx "BOOL_VEC2"
  let bool_vec3 = get_int gl1ctx "BOOL_VEC3"
  let bool_vec4 = get_int gl1ctx "BOOL_VEC4"
  let float_mat2 = get_int gl1ctx "FLOAT_MAT2"
  let float_mat3 = get_int gl1ctx "FLOAT_MAT3"
  let float_mat4 = get_int gl1ctx "FLOAT_MAT4"
  let sampler_2d = get_int gl1ctx "SAMPLER_2D"
  let sampler_cube = get_int gl1ctx "SAMPLER_CUBE"
  let vertex_attrib_array_enabled = get_int gl1ctx "VERTEX_ATTRIB_ARRAY_ENABLED"
  let vertex_attrib_array_size = get_int gl1ctx "VERTEX_ATTRIB_ARRAY_SIZE"
  let vertex_attrib_array_stride = get_int gl1ctx "VERTEX_ATTRIB_ARRAY_STRIDE"
  let vertex_attrib_array_type = get_int gl1ctx "VERTEX_ATTRIB_ARRAY_TYPE"
  let vertex_attrib_array_normalized = get_int gl1ctx "VERTEX_ATTRIB_ARRAY_NORMALIZED"
  let vertex_attrib_array_pointer = get_int gl1ctx "VERTEX_ATTRIB_ARRAY_POINTER"
  let vertex_attrib_array_buffer_binding = get_int gl1ctx "VERTEX_ATTRIB_ARRAY_BUFFER_BINDING"
  let implementation_color_read_type = get_int gl1ctx "IMPLEMENTATION_COLOR_READ_TYPE"
  let implementation_color_read_format = get_int gl1ctx "IMPLEMENTATION_COLOR_READ_FORMAT"
  let compile_status = get_int gl1ctx "COMPILE_STATUS"
  let low_float = get_int gl1ctx "LOW_FLOAT"
  let medium_float = get_int gl1ctx "MEDIUM_FLOAT"
  let high_float = get_int gl1ctx "HIGH_FLOAT"
  let low_int = get_int gl1ctx "LOW_INT"
  let medium_int = get_int gl1ctx "MEDIUM_INT"
  let high_int = get_int gl1ctx "HIGH_INT"
  let framebuffer = get_int gl1ctx "FRAMEBUFFER"
  let renderbuffer = get_int gl1ctx "RENDERBUFFER"
  let rgba4 = get_int gl1ctx "RGBA4"
  let rgb5_a1 = get_int gl1ctx "RGB5_A1"
  let rgb565 = get_int gl1ctx "RGB565"
  let depth_component16 = get_int gl1ctx "DEPTH_COMPONENT16"
  let stencil_index8 = get_int gl1ctx "STENCIL_INDEX8"
  let depth_stencil = get_int gl1ctx "DEPTH_STENCIL"
  let renderbuffer_width = get_int gl1ctx "RENDERBUFFER_WIDTH"
  let renderbuffer_height = get_int gl1ctx "RENDERBUFFER_HEIGHT"
  let renderbuffer_internal_format = get_int gl1ctx "RENDERBUFFER_INTERNAL_FORMAT"
  let renderbuffer_red_size = get_int gl1ctx "RENDERBUFFER_RED_SIZE"
  let renderbuffer_green_size = get_int gl1ctx "RENDERBUFFER_GREEN_SIZE"
  let renderbuffer_blue_size = get_int gl1ctx "RENDERBUFFER_BLUE_SIZE"
  let renderbuffer_alpha_size = get_int gl1ctx "RENDERBUFFER_ALPHA_SIZE"
  let renderbuffer_depth_size = get_int gl1ctx "RENDERBUFFER_DEPTH_SIZE"
  let renderbuffer_stencil_size = get_int gl1ctx "RENDERBUFFER_STENCIL_SIZE"
  let framebuffer_attachment_object_type = get_int gl1ctx "FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE"
  let framebuffer_attachment_object_name = get_int gl1ctx "FRAMEBUFFER_ATTACHMENT_OBJECT_NAME"
  let framebuffer_attachment_texture_level = get_int gl1ctx "FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL"
  let framebuffer_attachment_texture_cube_map_face = get_int gl1ctx "FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE"
  let color_attachment0 = get_int gl1ctx "COLOR_ATTACHMENT0"
  let depth_attachment = get_int gl1ctx "DEPTH_ATTACHMENT"
  let stencil_attachment = get_int gl1ctx "STENCIL_ATTACHMENT"
  let depth_stencil_attachment = get_int gl1ctx "DEPTH_STENCIL_ATTACHMENT"
  let none = get_int gl1ctx "NONE"
  let framebuffer_complete = get_int gl1ctx "FRAMEBUFFER_COMPLETE"
  let framebuffer_incomplete_attachment = get_int gl1ctx "FRAMEBUFFER_INCOMPLETE_ATTACHMENT"
  let framebuffer_incomplete_missing_attachment = get_int gl1ctx "FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT"
  let framebuffer_incomplete_dimensions = get_int gl1ctx "FRAMEBUFFER_INCOMPLETE_DIMENSIONS"
  let framebuffer_unsupported = get_int gl1ctx "FRAMEBUFFER_UNSUPPORTED"
  let framebuffer_binding = get_int gl1ctx "FRAMEBUFFER_BINDING"
  let renderbuffer_binding = get_int gl1ctx "RENDERBUFFER_BINDING"
  let max_renderbuffer_size = get_int gl1ctx "MAX_RENDERBUFFER_SIZE"
  let invalid_framebuffer_operation = get_int gl1ctx "INVALID_FRAMEBUFFER_OPERATION"
  let unpack_flip_y_webgl = get_int gl1ctx "UNPACK_FLIP_Y_WEBGL"
  let unpack_premultiply_alpha_webgl = get_int gl1ctx "UNPACK_PREMULTIPLY_ALPHA_WEBGL"
  let context_lost_webgl = get_int gl1ctx "CONTEXT_LOST_WEBGL"
  let unpack_colorspace_conversion_webgl = get_int gl1ctx "UNPACK_COLORSPACE_CONVERSION_WEBGL"
  let browser_default_webgl = get_int gl1ctx "BROWSER_DEFAULT_WEBGL"

  let gl2ctx = Jv.get Jv.global "WebGL2RenderingContext"
  let read_buffer' = get_int gl2ctx "READ_BUFFER"
  let unpack_row_length = get_int gl2ctx "UNPACK_ROW_LENGTH"
  let unpack_skip_rows = get_int gl2ctx "UNPACK_SKIP_ROWS"
  let unpack_skip_pixels = get_int gl2ctx "UNPACK_SKIP_PIXELS"
  let pack_row_length = get_int gl2ctx "PACK_ROW_LENGTH"
  let pack_skip_rows = get_int gl2ctx "PACK_SKIP_ROWS"
  let pack_skip_pixels = get_int gl2ctx "PACK_SKIP_PIXELS"
  let color = get_int gl2ctx "COLOR"
  let depth = get_int gl2ctx "DEPTH"
  let stencil = get_int gl2ctx "STENCIL"
  let red = get_int gl2ctx "RED"
  let rgb8 = get_int gl2ctx "RGB8"
  let rgba8 = get_int gl2ctx "RGBA8"
  let rgb10_a2 = get_int gl2ctx "RGB10_A2"
  let texture_binding_3d = get_int gl2ctx "TEXTURE_BINDING_3D"
  let unpack_skip_images = get_int gl2ctx "UNPACK_SKIP_IMAGES"
  let unpack_image_height = get_int gl2ctx "UNPACK_IMAGE_HEIGHT"
  let texture_3d = get_int gl2ctx "TEXTURE_3D"
  let texture_wrap_r = get_int gl2ctx "TEXTURE_WRAP_R"
  let max_3d_texture_size = get_int gl2ctx "MAX_3D_TEXTURE_SIZE"
  let unsigned_int_2_10_10_10_rev = get_int gl2ctx "UNSIGNED_INT_2_10_10_10_REV"
  let max_elements_vertices = get_int gl2ctx "MAX_ELEMENTS_VERTICES"
  let max_elements_indices = get_int gl2ctx "MAX_ELEMENTS_INDICES"
  let texture_min_lod = get_int gl2ctx "TEXTURE_MIN_LOD"
  let texture_max_lod = get_int gl2ctx "TEXTURE_MAX_LOD"
  let texture_base_level = get_int gl2ctx "TEXTURE_BASE_LEVEL"
  let texture_max_level = get_int gl2ctx "TEXTURE_MAX_LEVEL"
  let min = get_int gl2ctx "MIN"
  let max = get_int gl2ctx "MAX"
  let depth_component24 = get_int gl2ctx "DEPTH_COMPONENT24"
  let max_texture_lod_bias = get_int gl2ctx "MAX_TEXTURE_LOD_BIAS"
  let texture_compare_mode = get_int gl2ctx "TEXTURE_COMPARE_MODE"
  let texture_compare_func = get_int gl2ctx "TEXTURE_COMPARE_FUNC"
  let current_query = get_int gl2ctx "CURRENT_QUERY"
  let query_result = get_int gl2ctx "QUERY_RESULT"
  let query_result_available = get_int gl2ctx "QUERY_RESULT_AVAILABLE"
  let stream_read = get_int gl2ctx "STREAM_READ"
  let stream_copy = get_int gl2ctx "STREAM_COPY"
  let static_read = get_int gl2ctx "STATIC_READ"
  let static_copy = get_int gl2ctx "STATIC_COPY"
  let dynamic_read = get_int gl2ctx "DYNAMIC_READ"
  let dynamic_copy = get_int gl2ctx "DYNAMIC_COPY"
  let max_draw_buffers = get_int gl2ctx "MAX_DRAW_BUFFERS"
  let draw_buffer0 = get_int gl2ctx "DRAW_BUFFER0"
  let draw_buffer1 = get_int gl2ctx "DRAW_BUFFER1"
  let draw_buffer2 = get_int gl2ctx "DRAW_BUFFER2"
  let draw_buffer3 = get_int gl2ctx "DRAW_BUFFER3"
  let draw_buffer4 = get_int gl2ctx "DRAW_BUFFER4"
  let draw_buffer5 = get_int gl2ctx "DRAW_BUFFER5"
  let draw_buffer6 = get_int gl2ctx "DRAW_BUFFER6"
  let draw_buffer7 = get_int gl2ctx "DRAW_BUFFER7"
  let draw_buffer8 = get_int gl2ctx "DRAW_BUFFER8"
  let draw_buffer9 = get_int gl2ctx "DRAW_BUFFER9"
  let draw_buffer10 = get_int gl2ctx "DRAW_BUFFER10"
  let draw_buffer11 = get_int gl2ctx "DRAW_BUFFER11"
  let draw_buffer12 = get_int gl2ctx "DRAW_BUFFER12"
  let draw_buffer13 = get_int gl2ctx "DRAW_BUFFER13"
  let draw_buffer14 = get_int gl2ctx "DRAW_BUFFER14"
  let draw_buffer15 = get_int gl2ctx "DRAW_BUFFER15"
  let max_fragment_uniform_components = get_int gl2ctx "MAX_FRAGMENT_UNIFORM_COMPONENTS"
  let max_vertex_uniform_components = get_int gl2ctx "MAX_VERTEX_UNIFORM_COMPONENTS"
  let sampler_3d = get_int gl2ctx "SAMPLER_3D"
  let sampler_2d_shadow = get_int gl2ctx "SAMPLER_2D_SHADOW"
  let fragment_shader_derivative_hint = get_int gl2ctx "FRAGMENT_SHADER_DERIVATIVE_HINT"
  let pixel_pack_buffer = get_int gl2ctx "PIXEL_PACK_BUFFER"
  let pixel_unpack_buffer = get_int gl2ctx "PIXEL_UNPACK_BUFFER"
  let pixel_pack_buffer_binding = get_int gl2ctx "PIXEL_PACK_BUFFER_BINDING"
  let pixel_unpack_buffer_binding = get_int gl2ctx "PIXEL_UNPACK_BUFFER_BINDING"
  let float_mat2x3 = get_int gl2ctx "FLOAT_MAT2x3"
  let float_mat2x4 = get_int gl2ctx "FLOAT_MAT2x4"
  let float_mat3x2 = get_int gl2ctx "FLOAT_MAT3x2"
  let float_mat3x4 = get_int gl2ctx "FLOAT_MAT3x4"
  let float_mat4x2 = get_int gl2ctx "FLOAT_MAT4x2"
  let float_mat4x3 = get_int gl2ctx "FLOAT_MAT4x3"
  let srgb = get_int gl2ctx "SRGB"
  let srgb8 = get_int gl2ctx "SRGB8"
  let srgb8_alpha8 = get_int gl2ctx "SRGB8_ALPHA8"
  let compare_ref_to_texture = get_int gl2ctx "COMPARE_REF_TO_TEXTURE"
  let rgba32f = get_int gl2ctx "RGBA32F"
  let rgb32f = get_int gl2ctx "RGB32F"
  let rgba16f = get_int gl2ctx "RGBA16F"
  let rgb16f = get_int gl2ctx "RGB16F"
  let vertex_attrib_array_integer = get_int gl2ctx "VERTEX_ATTRIB_ARRAY_INTEGER"
  let max_array_texture_layers = get_int gl2ctx "MAX_ARRAY_TEXTURE_LAYERS"
  let min_program_texel_offset = get_int gl2ctx "MIN_PROGRAM_TEXEL_OFFSET"
  let max_program_texel_offset = get_int gl2ctx "MAX_PROGRAM_TEXEL_OFFSET"
  let max_varying_components = get_int gl2ctx "MAX_VARYING_COMPONENTS"
  let texture_2d_array = get_int gl2ctx "TEXTURE_2D_ARRAY"
  let texture_binding_2d_array = get_int gl2ctx "TEXTURE_BINDING_2D_ARRAY"
  let r11f_g11f_b10f = get_int gl2ctx "R11F_G11F_B10F"
  let unsigned_int_10f_11f_11f_rev = get_int gl2ctx "UNSIGNED_INT_10F_11F_11F_REV"
  let rgb9_e5 = get_int gl2ctx "RGB9_E5"
  let unsigned_int_5_9_9_9_rev = get_int gl2ctx "UNSIGNED_INT_5_9_9_9_REV"
  let transform_feedback_buffer_mode = get_int gl2ctx "TRANSFORM_FEEDBACK_BUFFER_MODE"
  let max_transform_feedback_separate_components = get_int gl2ctx "MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS"
  let transform_feedback_varyings' = get_int gl2ctx "TRANSFORM_FEEDBACK_VARYINGS"
  let transform_feedback_buffer_start = get_int gl2ctx "TRANSFORM_FEEDBACK_BUFFER_START"
  let transform_feedback_buffer_size = get_int gl2ctx "TRANSFORM_FEEDBACK_BUFFER_SIZE"
  let transform_feedback_primitives_written = get_int gl2ctx "TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN"
  let rasterizer_discard = get_int gl2ctx "RASTERIZER_DISCARD"
  let max_transform_feedback_interleaved_components = get_int gl2ctx "MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS"
  let max_transform_feedback_separate_attribs = get_int gl2ctx "MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS"
  let interleaved_attribs = get_int gl2ctx "INTERLEAVED_ATTRIBS"
  let separate_attribs = get_int gl2ctx "SEPARATE_ATTRIBS"
  let transform_feedback_buffer = get_int gl2ctx "TRANSFORM_FEEDBACK_BUFFER"
  let transform_feedback_buffer_binding = get_int gl2ctx "TRANSFORM_FEEDBACK_BUFFER_BINDING"
  let rgba32ui = get_int gl2ctx "RGBA32UI"
  let rgb32ui = get_int gl2ctx "RGB32UI"
  let rgba16ui = get_int gl2ctx "RGBA16UI"
  let rgb16ui = get_int gl2ctx "RGB16UI"
  let rgba8ui = get_int gl2ctx "RGBA8UI"
  let rgb8ui = get_int gl2ctx "RGB8UI"
  let rgba32i = get_int gl2ctx "RGBA32I"
  let rgb32i = get_int gl2ctx "RGB32I"
  let rgba16i = get_int gl2ctx "RGBA16I"
  let rgb16i = get_int gl2ctx "RGB16I"
  let rgba8i = get_int gl2ctx "RGBA8I"
  let rgb8i = get_int gl2ctx "RGB8I"
  let red_integer = get_int gl2ctx "RED_INTEGER"
  let rgb_integer = get_int gl2ctx "RGB_INTEGER"
  let rgba_integer = get_int gl2ctx "RGBA_INTEGER"
  let sampler_2d_array = get_int gl2ctx "SAMPLER_2D_ARRAY"
  let sampler_2d_array_shadow = get_int gl2ctx "SAMPLER_2D_ARRAY_SHADOW"
  let sampler_cube_shadow = get_int gl2ctx "SAMPLER_CUBE_SHADOW"
  let unsigned_int_vec2 = get_int gl2ctx "UNSIGNED_INT_VEC2"
  let unsigned_int_vec3 = get_int gl2ctx "UNSIGNED_INT_VEC3"
  let unsigned_int_vec4 = get_int gl2ctx "UNSIGNED_INT_VEC4"
  let int_sampler_2d = get_int gl2ctx "INT_SAMPLER_2D"
  let int_sampler_3d = get_int gl2ctx "INT_SAMPLER_3D"
  let int_sampler_cube = get_int gl2ctx "INT_SAMPLER_CUBE"
  let int_sampler_2d_array = get_int gl2ctx "INT_SAMPLER_2D_ARRAY"
  let unsigned_int_sampler_2d = get_int gl2ctx "UNSIGNED_INT_SAMPLER_2D"
  let unsigned_int_sampler_3d = get_int gl2ctx "UNSIGNED_INT_SAMPLER_3D"
  let unsigned_int_sampler_cube = get_int gl2ctx "UNSIGNED_INT_SAMPLER_CUBE"
  let unsigned_int_sampler_2d_array = get_int gl2ctx "UNSIGNED_INT_SAMPLER_2D_ARRAY"
  let depth_component32f = get_int gl2ctx "DEPTH_COMPONENT32F"
  let depth32f_stencil8 = get_int gl2ctx "DEPTH32F_STENCIL8"
  let float_32_unsigned_int_24_8_rev = get_int gl2ctx "FLOAT_32_UNSIGNED_INT_24_8_REV"
  let framebuffer_attachment_color_encoding = get_int gl2ctx "FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING"
  let framebuffer_attachment_component_type = get_int gl2ctx "FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE"
  let framebuffer_attachment_red_size = get_int gl2ctx "FRAMEBUFFER_ATTACHMENT_RED_SIZE"
  let framebuffer_attachment_green_size = get_int gl2ctx "FRAMEBUFFER_ATTACHMENT_GREEN_SIZE"
  let framebuffer_attachment_blue_size = get_int gl2ctx "FRAMEBUFFER_ATTACHMENT_BLUE_SIZE"
  let framebuffer_attachment_alpha_size = get_int gl2ctx "FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE"
  let framebuffer_attachment_depth_size = get_int gl2ctx "FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE"
  let framebuffer_attachment_stencil_size = get_int gl2ctx "FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE"
  let framebuffer_default = get_int gl2ctx "FRAMEBUFFER_DEFAULT"
  let unsigned_int_24_8 = get_int gl2ctx "UNSIGNED_INT_24_8"
  let depth24_stencil8 = get_int gl2ctx "DEPTH24_STENCIL8"
  let unsigned_normalized = get_int gl2ctx "UNSIGNED_NORMALIZED"
  let draw_framebuffer_binding = get_int gl2ctx "DRAW_FRAMEBUFFER_BINDING"
  let read_framebuffer = get_int gl2ctx "READ_FRAMEBUFFER"
  let draw_framebuffer = get_int gl2ctx "DRAW_FRAMEBUFFER"
  let read_framebuffer_binding = get_int gl2ctx "READ_FRAMEBUFFER_BINDING"
  let renderbuffer_samples = get_int gl2ctx "RENDERBUFFER_SAMPLES"
  let framebuffer_attachment_texture_layer = get_int gl2ctx "FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER"
  let max_color_attachments = get_int gl2ctx "MAX_COLOR_ATTACHMENTS"
  let color_attachment1 = get_int gl2ctx "COLOR_ATTACHMENT1"
  let color_attachment2 = get_int gl2ctx "COLOR_ATTACHMENT2"
  let color_attachment3 = get_int gl2ctx "COLOR_ATTACHMENT3"
  let color_attachment4 = get_int gl2ctx "COLOR_ATTACHMENT4"
  let color_attachment5 = get_int gl2ctx "COLOR_ATTACHMENT5"
  let color_attachment6 = get_int gl2ctx "COLOR_ATTACHMENT6"
  let color_attachment7 = get_int gl2ctx "COLOR_ATTACHMENT7"
  let color_attachment8 = get_int gl2ctx "COLOR_ATTACHMENT8"
  let color_attachment9 = get_int gl2ctx "COLOR_ATTACHMENT9"
  let color_attachment10 = get_int gl2ctx "COLOR_ATTACHMENT10"
  let color_attachment11 = get_int gl2ctx "COLOR_ATTACHMENT11"
  let color_attachment12 = get_int gl2ctx "COLOR_ATTACHMENT12"
  let color_attachment13 = get_int gl2ctx "COLOR_ATTACHMENT13"
  let color_attachment14 = get_int gl2ctx "COLOR_ATTACHMENT14"
  let color_attachment15 = get_int gl2ctx "COLOR_ATTACHMENT15"
  let framebuffer_incomplete_multisample = get_int gl2ctx "FRAMEBUFFER_INCOMPLETE_MULTISAMPLE"
  let max_samples = get_int gl2ctx "MAX_SAMPLES"
  let half_float = get_int gl2ctx "HALF_FLOAT"
  let rg = get_int gl2ctx "RG"
  let rg_integer = get_int gl2ctx "RG_INTEGER"
  let r8 = get_int gl2ctx "R8"
  let rg8 = get_int gl2ctx "RG8"
  let r16f = get_int gl2ctx "R16F"
  let r32f = get_int gl2ctx "R32F"
  let rg16f = get_int gl2ctx "RG16F"
  let rg32f = get_int gl2ctx "RG32F"
  let r8i = get_int gl2ctx "R8I"
  let r8ui = get_int gl2ctx "R8UI"
  let r16i = get_int gl2ctx "R16I"
  let r16ui = get_int gl2ctx "R16UI"
  let r32i = get_int gl2ctx "R32I"
  let r32ui = get_int gl2ctx "R32UI"
  let rg8i = get_int gl2ctx "RG8I"
  let rg8ui = get_int gl2ctx "RG8UI"
  let rg16i = get_int gl2ctx "RG16I"
  let rg16ui = get_int gl2ctx "RG16UI"
  let rg32i = get_int gl2ctx "RG32I"
  let rg32ui = get_int gl2ctx "RG32UI"
  let vertex_array_binding = get_int gl2ctx "VERTEX_ARRAY_BINDING"
  let r8_snorm = get_int gl2ctx "R8_SNORM"
  let rg8_snorm = get_int gl2ctx "RG8_SNORM"
  let rgb8_snorm = get_int gl2ctx "RGB8_SNORM"
  let rgba8_snorm = get_int gl2ctx "RGBA8_SNORM"
  let signed_normalized = get_int gl2ctx "SIGNED_NORMALIZED"
  let copy_read_buffer = get_int gl2ctx "COPY_READ_BUFFER"
  let copy_write_buffer = get_int gl2ctx "COPY_WRITE_BUFFER"
  let copy_read_buffer_binding = get_int gl2ctx "COPY_READ_BUFFER_BINDING"
  let copy_write_buffer_binding = get_int gl2ctx "COPY_WRITE_BUFFER_BINDING"
  let uniform_buffer = get_int gl2ctx "UNIFORM_BUFFER"
  let uniform_buffer_binding = get_int gl2ctx "UNIFORM_BUFFER_BINDING"
  let uniform_buffer_start = get_int gl2ctx "UNIFORM_BUFFER_START"
  let uniform_buffer_size = get_int gl2ctx "UNIFORM_BUFFER_SIZE"
  let max_vertex_uniform_blocks = get_int gl2ctx "MAX_VERTEX_UNIFORM_BLOCKS"
  let max_fragment_uniform_blocks = get_int gl2ctx "MAX_FRAGMENT_UNIFORM_BLOCKS"
  let max_combined_uniform_blocks = get_int gl2ctx "MAX_COMBINED_UNIFORM_BLOCKS"
  let max_uniform_buffer_bindings = get_int gl2ctx "MAX_UNIFORM_BUFFER_BINDINGS"
  let max_uniform_block_size = get_int gl2ctx "MAX_UNIFORM_BLOCK_SIZE"
  let max_combined_vertex_uniform_components = get_int gl2ctx "MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS"
  let max_combined_fragment_uniform_components = get_int gl2ctx "MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS"
  let uniform_buffer_offset_alignment = get_int gl2ctx "UNIFORM_BUFFER_OFFSET_ALIGNMENT"
  let active_uniform_blocks = get_int gl2ctx "ACTIVE_UNIFORM_BLOCKS"
  let uniform_type = get_int gl2ctx "UNIFORM_TYPE"
  let uniform_size = get_int gl2ctx "UNIFORM_SIZE"
  let uniform_block_index = get_int gl2ctx "UNIFORM_BLOCK_INDEX"
  let uniform_offset = get_int gl2ctx "UNIFORM_OFFSET"
  let uniform_array_stride = get_int gl2ctx "UNIFORM_ARRAY_STRIDE"
  let uniform_matrix_stride = get_int gl2ctx "UNIFORM_MATRIX_STRIDE"
  let uniform_is_row_major = get_int gl2ctx "UNIFORM_IS_ROW_MAJOR"
  let uniform_block_binding' = get_int gl2ctx "UNIFORM_BLOCK_BINDING"
  let uniform_block_data_size = get_int gl2ctx "UNIFORM_BLOCK_DATA_SIZE"
  let uniform_block_active_uniforms = get_int gl2ctx "UNIFORM_BLOCK_ACTIVE_UNIFORMS"
  let uniform_block_active_uniform_indices = get_int gl2ctx "UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES"
  let uniform_block_referenced_by_vertex_shader = get_int gl2ctx "UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER"
  let uniform_block_referenced_by_fragment_shader = get_int gl2ctx "UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER"
  let invalid_index = get_int gl2ctx "INVALID_INDEX"
  let max_vertex_output_components = get_int gl2ctx "MAX_VERTEX_OUTPUT_COMPONENTS"
  let max_fragment_input_components = get_int gl2ctx "MAX_FRAGMENT_INPUT_COMPONENTS"
  let max_server_wait_timeout = get_int gl2ctx "MAX_SERVER_WAIT_TIMEOUT"
  let object_type = get_int gl2ctx "OBJECT_TYPE"
  let sync_condition = get_int gl2ctx "SYNC_CONDITION"
  let sync_status = get_int gl2ctx "SYNC_STATUS"
  let sync_flags = get_int gl2ctx "SYNC_FLAGS"
  let sync_fence = get_int gl2ctx "SYNC_FENCE"
  let sync_gpu_commands_complete = get_int gl2ctx "SYNC_GPU_COMMANDS_COMPLETE"
  let unsignaled = get_int gl2ctx "UNSIGNALED"
  let signaled = get_int gl2ctx "SIGNALED"
  let already_signaled = get_int gl2ctx "ALREADY_SIGNALED"
  let timeout_expired = get_int gl2ctx "TIMEOUT_EXPIRED"
  let condition_satisfied = get_int gl2ctx "CONDITION_SATISFIED"
  let wait_failed = get_int gl2ctx "WAIT_FAILED"
  let sync_flush_commands_bit = get_int gl2ctx "SYNC_FLUSH_COMMANDS_BIT"
  let vertex_attrib_array_divisor = get_int gl2ctx "VERTEX_ATTRIB_ARRAY_DIVISOR"
  let any_samples_passed = get_int gl2ctx "ANY_SAMPLES_PASSED"
  let any_samples_passed_conservative = get_int gl2ctx "ANY_SAMPLES_PASSED_CONSERVATIVE"
  let sampler_binding = get_int gl2ctx "SAMPLER_BINDING"
  let rgb10_a2ui = get_int gl2ctx "RGB10_A2UI"
  let int_2_10_10_10_rev = get_int gl2ctx "INT_2_10_10_10_REV"
  let transform_feedback = get_int gl2ctx "TRANSFORM_FEEDBACK"
  let transform_feedback_paused = get_int gl2ctx "TRANSFORM_FEEDBACK_PAUSED"
  let transform_feedback_active = get_int gl2ctx "TRANSFORM_FEEDBACK_ACTIVE"
  let transform_feedback_binding = get_int gl2ctx "TRANSFORM_FEEDBACK_BINDING"
  let texture_immutable_format = get_int gl2ctx "TEXTURE_IMMUTABLE_FORMAT"
  let max_element_index = get_int gl2ctx "MAX_ELEMENT_INDEX"
  let texture_immutable_levels = get_int gl2ctx "TEXTURE_IMMUTABLE_LEVELS"
  let timeout_ignored = get_int gl2ctx "TIMEOUT_IGNORED"
  let max_client_wait_timeout_webgl = get_int gl2ctx "MAX_CLIENT_WAIT_TIMEOUT_WEBGL"
end
