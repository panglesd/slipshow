(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Canvas APIs.

    Open this module to use it. It defines only modules in your scope. *)

open Brr

(** 4x4 matrices. *)
module Matrix4 : sig
  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/DOMMatrixReadOnly}
      [DomMatrixReadOnly]} objects. *)

  val is_2d : t -> bool
  (** [is_2d m] is [true] iff the matrix was initialized as 2D matrix. *)

  val is_identity : t -> bool
  (** [is_identity m] is [true] iff the matrix is the identity matrix. *)

  val inverse : t -> t
  (** [inverse m] is [m]'s inverse. *)

  val multiply : t -> t -> t
  (** [multiply m m'] multiplies [m] by [m']. *)

  (** {1:accessors Element accessors}

      For the order see {{:https://drafts.fxtf.org/geometry/#DOMMatrix}here}. *)

  val m11 : t -> float
  val m12 : t -> float
  val m13 : t -> float
  val m14 : t -> float
  val m21 : t -> float
  val m22 : t -> float
  val m23 : t -> float
  val m24 : t -> float
  val m31 : t -> float
  val m32 : t -> float
  val m33 : t -> float
  val m34 : t -> float
  val m41 : t -> float
  val m42 : t -> float
  val m43 : t -> float
  val m44 : t -> float
  val a : t -> float
  val b : t -> float
  val c : t -> float
  val d : t -> float
  val e : t -> float
  val f : t -> float

  (** {1:typed_array Typed array conversions}

      In arrays matrix elements are stored in column-major order. *)

  val to_float32_array : t -> Tarray.float32
  val of_float32_array : Tarray.float32 -> t
  val to_float64_array : t -> Tarray.float64
  val of_float64_array : Tarray.float64 -> t

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** 4D vector. *)
module Vec4 : sig

  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/DOMPointReadOnly}
      [DomPointReadOnly]} objects. *)

  val v : x:float -> y:float -> z:float -> w:float -> t
  (** [v ~x ~y ~z ~w] is a vector ([w] = 0) or point ([w] = 1) with the
      given coordinates. *)

  val tr : Matrix4.t -> t -> t
  (** [tr m v] transforms [v] by [m]. *)

  val to_json : t -> Json.t
  (** [to_json v] is [v] as {{:https://developer.mozilla.org/en-US/docs/Web/API/DOMPointReadOnly/toJSON}JSON}. *)

  (** {1:accessors Element accessors} *)

  val x : t -> float
  val y : t -> float
  val z : t -> float
  val w : t -> float

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** Canvas element. *)
module Canvas : sig

  type t
  (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement}HTMLCanvasElement} objects. *)

  val create :
    ?d:Document.t -> ?at:At.t list -> ?w:int -> ?h:int -> El.t list -> t
  (** [create ~w ~h []] is a canvas element with a render buffer of [w]x[h]
      pixels (they default to [0]). *)

  val of_el : El.t -> t
  (** [of_el e] is a canvas from element [e]. This throws a JavaScript
      error if [e] is not a canvas element. *)

  val to_el : t -> El.t
  (** [to_el c] is [c] as an an element. *)

  (** {1:dim Render buffer dimensions} *)

  val w : t -> int
  (** [w c] is the render buffer width of [c] in pixels. *)

  val h : t -> int
  (** [h c] is the render buffer height of [c] in pixels. *)

  val set_w : t -> int -> unit
  (** [set_w c w] sets the render buffer width of [c] to [w] pixels. *)

  val set_h : t -> int -> unit
  (** [set_h c h] sets the render buffer height of [c] to [h] pixels. *)

  val set_size_to_layout_size : ?hidpi:bool -> t -> unit
  (** [set_size_to_layout_size t] sets the render buffer size to the canvas'
      element {!Brr.El.inner_w} {!Brr.El.inner_h} and values. If [hidpi] is
      [true] (defaults), these values are multiplied by
      {!Brr.Window.device_pixel_ratio}. *)

  (** {1:ctx Contexts}

      Context are obtained by the modules that handle them.
      {ul
      {- For the 2D context see {!C2d.get_context}.}
      {- For the WebGL2 context see {!Gl.get_context}.}
      {- For the WebGPU context see {!Brr_webgpu.Gpu.Canvas_context.get}.}}
  *)

  (** {1:conv Converting} *)

  type image_encode
  (** The type for image encode parameters. *)

  val image_encode : ?type':Jstr.t -> ?quality:float -> unit -> image_encode
  (** [image_encode ~type' ~quality ()] are image encoding parameters
      [type'] is the mime type of the image, it defaults to
      ["image/png"]. [quality] a number from [0.] to [1.] if it makes
      sense for the data format (e.g. JPEG), default is implementation
      dependent. *)

  val to_data_url : ?encode:image_encode -> t -> (Jstr.t, Jv.Error.t) result
  (** [to_data_url ~encode t] is the canvas's image as a data url. *)

  val to_blob : ?encode:image_encode -> t -> Blob.t option Fut.or_error
  (** [to_blob ~encode t] is the canvas's image a blob object. [None]
      is returned either if the canvas has no pixels or if an error
      occurs during image serialisation. *)

  val capture_stream : hz:int option -> t -> Brr_io.Media.Stream.t
  (** [capture_stream ~hz] is a
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/captureStream}capture media stream} for the canvas at the frequency of
      [hz] or manually if unspecified. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** The {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D}2D canvas} context. *)
module C2d : sig

  (** {1:enum Enumerations} *)

  (** Fill rule enum. *)
  module Fill_rule : sig
    type t = Jstr.t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fill#Parameters}fill rule} values. *)

    val nonzero : t
    val evenodd : t
  end

  (** Image smoothing quality enum. *)
  module Image_smoothing_quality : sig
    type t = Jstr.t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/imageSmoothingQuality#Options}image smoothing quality}
        values. *)

    val low : t
    val medium : t
    val high : t
  end

  (** Line cap. *)
  module Line_cap : sig
    type t = Jstr.t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineCap#Options}line cap} values. *)

    val butt : t
    val round : t
    val square : t
  end

  (** Line join. *)
  module Line_join : sig
    type t = Jstr.t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineJoin#Options}line join} values. *)

    val round : t
    val bevel : t
    val miter : t
  end

  (** Text alignement. *)
  module Text_align : sig
    type t = Jstr.t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/textAlign#Options}text align} values. *)

    val start : t
    val end' : t
    val left : t
    val right : t
    val center : t
  end

  (** Text baseline. *)
  module Text_baseline : sig
    type t = Jstr.t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/textBaseline#Options}text baseline} values. *)

    val top : t
    val hanging : t
    val middle : t
    val alphabetic : t
    val ideographic : t
    val bottom : t
  end

  (** Text direction. *)
  module Text_direction : sig
    type t = Jstr.t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/direction#Options}text direction} values. *)

    val ltr : t
    val rtl : t
    val inherit' : t
  end

  (** Compositing operators. *)
  module Composite_op : sig
    type t = Jstr.t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalCompositeOperation}compositing operators}. *)

    val normal : t
    val multiply : t
    val screen : t
    val overlay : t
    val darken : t
    val lighten : t
    val color_dodge : t
    val color_burn : t
    val hard_light : t
    val soft_light : t
    val difference : t
    val exclusion : t
    val hue : t
    val saturation : t
    val color : t
    val luminosity : t
    val clear : t
    val copy : t
    val source_over : t
    val destination_over : t
    val source_in : t
    val destination_in : t
    val source_out : t
    val destination_out : t
    val source_atop : t
    val destination_atop : t
    val xor : t
    val lighter : t
    val plus_darker : t
    val plus_lighter : t
  end

  (** Pattern repetition. *)
  module Repeat : sig
    type t = Jstr.t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createPattern#Parameters}pattern repetition} values. *)

    val xy : t
    val x : t
    val y : t
    val no : t
  end

  (** {1:paths Paths} *)

  (** Path2D objects. *)
  module Path : sig

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Path2D}[Path2D]}
        objects. *)

    val create : unit -> t
    (** [create ()] is a new empty path. *)

    val of_svg : Jstr.t -> t
    (** [of_svg p] is a path from the SVG path data [p]. *)

    val of_path : t -> t
    (** [of_path p] is a copy of [p]. *)

    val add : ?tr:Matrix4.t -> t -> t -> unit
    (** [add p ~tr p'] {{:https://developer.mozilla.org/en-US/docs/Web/API/Path2D/addPath}adds} path [p'] transformed by [tr] to [p]. *)

    val close : t -> unit
    (** [close p] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/closePath}closes} path [p]. *)

    val move_to : t -> x:float -> y:float -> unit
    (** [move_to p x y] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/moveTo}moves} to ([x],[y]). *)

    val line_to : t -> x:float -> y:float -> unit
    (** [line_to p x y] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineTo}lines} to ([x],[y]). *)

    val qcurve_to : t -> cx:float -> cy:float -> x:float -> y:float -> unit
    (** [qcurve_to p ~cx ~cy x y] is a {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/quadraticCurveTo}quadratic curve} to
        ([x],[y]) with control point ([cx],[cy]). *)

    val ccurve_to :
      t -> cx:float -> cy:float -> cx':float -> cy':float -> x:float ->
      y:float -> unit
    (** [ccurve_to p ~cx ~cy ~cx' ~cy' x y] is a {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/bezierCurveTo}cubic bezier curve}
        to ([x],[y]) with control point ([cx],[cy]) and ([cx'],[cy']). *)

    val arc_to :
      t -> cx:float -> cy:float -> cx':float -> cy':float -> r:float -> unit
    (** [arc_to p ~cx ~cy ~cx' ~cy' r] is a {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/arcTo}circular arc} with
        control points ([cx],[cy]), ([cx'],[cy']) and radius [r]. *)

    val arc :
      ?anticlockwise:bool -> t -> cx:float -> cy:float -> r:float ->
      start:float -> stop:float -> unit
    (** [arc p ~anticlockwise ~cx ~cy ~r ~start ~stop] is a {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/arc}circular arc} centered on ([cx],[cy]) with radius [r] starting at angle [start] and stopping
        at [stop]. *)

    val rect : t -> x:float -> y:float -> w:float -> h:float -> unit
    (** [react p x y ~w ~h] is a {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/arc}rectangle} with top-left corner ([x],[y]) extending
        down by [w] units and right by [h] units (or the opposite directions
        with negative values). *)

    val ellipse :
      ?anticlockwise:bool -> t -> cx:float -> cy:float -> rx:float ->
      ry:float -> rot:float -> start:float -> stop:float -> unit
    (** [ellipse p ~anticlockwise ~cx ~cy ~rot ~rx ~ry ~start ~stop]
        is an {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/ellipse}elliptical arc} centered on ([cx],[cy]) with radii
        ([rx],[ry]) rotated by [rot] starting at angle [start] and stopping
        at [stop]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** {1:image_sources Image sources} *)

  type image_src
  (** The type for canvas image sources. This
      can be {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasImageSource}many things}. *)

  val image_src_of_el : El.t -> image_src
  (** [image_src_of_el e] use this with an {!Brr.El.img}, {!Brr.El.video},
      {!Brr.El.canvas} element. No checks are performed. *)

  val image_src_of_jv : Jv.t -> image_src
  (** [image_src_of_jv jv] is an image source from the given JavaScript
      value. [jv] must be one of
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasImageSource}
      these things}, no checks are performed. *)

  (** {1:ctx_attrs Context attributes} *)

  type attrs
  (** The type for {{:https://html.spec.whatwg.org/multipage/canvas.html#canvasrenderingcontext2dsettings}CanvasRenderingContext2DSettings}. *)

  (* val attrs : *)
  (*   ?alpha:bool -> ?color_space:Jstr.t -> ?desynchronized:bool -> unit -> attrs *)
  (* (\** [attrs ()] are {!type-attrs} with the given attributes. *\) *)

  val attrs_alpha : attrs -> bool
  (** [attrs_alpha a] is the [alpha] attribute of [a]. *)

  val attrs_color_space : attrs -> Jstr.t
  (** [attrs_color_space a] is the [colorSpace] attribute of [a]. *)

  val attrs_desynchronized : attrs -> bool
  (** [attrs_desynchronized a] is the [desynchronized] attribute of [a]. *)

  val attrs_will_read_frequently : attrs -> bool
  (** [attrs_will_read_frequenty a] is the [willReadFrequently] attribute of
      [a]. *)

  (** {1:ctx Context} *)

  type t
  (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D}CanvasRenderingContext2D} objects. *)

  val get_context : ?attrs:attrs -> Canvas.t -> t
  (** [get_context ~attrs cnv] is a 2D context for canvas [cnv] with
      attributes [attrs]. *)

  val create : ?attrs:attrs -> Canvas.t -> t
  [@@ocaml.deprecated "use Brr_canvas.C2d.get_context instead."]

  val canvas : t -> Canvas.t option
  (** [canvas c] is the canvas element associated to the context
      [c] (if any). *)

  val attrs : t -> attrs
  (** [attrs c] are the context's attributes. *)

  val save : t -> unit
  (** [save c] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/save}saves} the state of [c]. *)

  val restore : t -> unit
  (** [restore c] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/restore}restores} last save of [c]. *)

  (** {1:antialiasing Antialiasing} *)

  val image_smoothing_enabled : t -> bool
  (** [image_smoothing_enabled c] determines the {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/imageSmoothingEnabled}image smoothing} (antialiasing) performed on [c]. *)

  val set_image_smoothing_enabled : t -> bool -> unit
  (** [image_smoothing_enabled c b] sets the {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/imageSmoothingEnabled}image smoothing} (antialiasing) performed on [c]. *)


  val image_smoothing_quality : t -> Image_smoothing_quality.t
  (** [image_smoothing_enabled c] determines {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/imageSmoothingQuality}image smoothing quality} (antialiasing) performed on [c]. *)


  val set_image_smoothing_quality : t -> Image_smoothing_quality.t -> unit
  (** [image_smoothing_enabled c] sets the {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/imageSmoothingQuality}image smoothing quality} (antialiasing) performed on [c]. *)

  (** {1:compositing Compositing} *)

  val global_alpha : t -> float
  (** [global_alpha c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalAlpha}global alpha} of [c]. *)

  val set_global_alpha : t -> float -> unit
  (** [set_global_alpha c a] setes the {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalAlpha}global alpha} of [c] to [a]. *)

  val global_composite_op : t -> Composite_op.t
  (** [global_composite_op c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalCompositeOperation}global composite operator} of [c]. *)

  val set_global_composite_op : t -> Composite_op.t -> unit
  (** [set_global_composite_op c op] sets the {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalCompositeOperation}global composite operator} of [c] to [op]. *)

  val filter : t -> Jstr.t
  (** [filter c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/filter}filter} of [c]. *)

  val set_filter : t -> Jstr.t -> unit
  (** [set_filter c f] sets the {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/filter}filter} of [c] to [f]. *)

  (** {1:transform Transformations} *)

  val get_transform : t -> Matrix4.t
  (** [get_transform c]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/getTransform}gets} the current transformation matrix. *)

  val set_transform : t -> Matrix4.t -> unit
  (** [set_transform c m]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/setTransform}sets} the current transformation matrix. *)

  val set_transform' : t ->
    a:float -> b:float -> c:float -> d:float -> e:float -> f:float -> unit
  (** [set_transform' c ~a ~b ~c ~d ~e ~f]
    {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/setTransform}sets} the current transformation matrix. *)

  val reset_transform : t -> unit
  (** [reset_transform c] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/resetTransform}resets} the current transformation matrix to the identity. *)

  val transform : t -> Matrix4.t -> unit
  (** [transform c m] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/transform}transforms} space by matrix [m]. *)

  val transform' : t ->
    a:float -> b:float -> c:float -> d:float -> e:float -> f:float -> unit
  (** [transform' c ~a ~b ~c ~d ~e ~f]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/transform}transforms} space by matrix [m]. *)

  val translate : t -> x:float -> y:float -> unit
  (** [translate c ~x ~y] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/translate}translates} space by ([x],[y]). *)

  val rotate : t -> float -> unit
  (** [rotate c r]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/rotate}rotates} space by [r] radians. *)

  val scale : t -> sx:float -> sy:float -> unit
  (** [scale c ~sx ~sy] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/scale}scales} space by ([sx], [sy]). *)

  (** {1:fillstroke Style fills and strokes} *)

  type style
  (** The type for stroke and fill styles. *)

  val set_stroke_style : t -> style -> unit
  (** [set_stroke_style c s] sets the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeStyle}stroke style} of [c] to [s]. *)

  val set_fill_style : t -> style -> unit
  (** [set_fill_style c s] sets the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillStyle}fill style} of [c] to [s]. *)

  val color : Jstr.t -> style
  (** [color s] is the color [s] parsed as a
      {{:https://developer.mozilla.org/en-US/docs/Web/CSS/color_value}
      CSS color value} as a style. *)

  type gradient
  (** The type for gradients. *)

  val gradient_style : gradient -> style
  (** [gradient_style g] is a style from the given gradient. *)

  val linear_gradient :
    t -> x0:float -> y0:float -> x1:float -> y1:float ->
    stops:(float * Jstr.t) list -> gradient
  (** [linear_gradient c ~x0 ~y0 ~x1 ~y1 ~stops]
      create a {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createLinearGradient}linear gradient} from ([x0],[y0]) to
      ([x1],[y1]) with
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasGradient/addColorStop}color stops} [stops]. *)

  val radial_gradient :
    t -> x0:float -> y0:float -> r0:float -> x1:float -> y1:float ->
    r1:float -> stops:(float * Jstr.t) list -> gradient
  (** [radial_gradient c ~x0 ~y0 ~r0 ~x1 ~y1 ~r1 ~stops]
      create a {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createRadialGradient}radial gradient} from circle centered
      at ([x0],[y0])
      with radius [r0] to circle centered at
      ([x1],[y1]) with radius [r1] and
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasGradient/addColorStop}color stops} [stops]. *)

  type pattern
  (** The type for patterns. *)

  val pattern_style : pattern -> style
  (** [pattern_style p] is a style from the given pattern. *)

  val pattern :
    t -> image_src -> Repeat.t -> tr:Matrix4.t option -> pattern
  (** [pattern c img repeat ~tr] creates a {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createPattern}pattern} from [img]
      repeatint it according to [repeat] and transform [tr]. *)

  (** {1:style_lines Style lines} *)

  val line_width : t -> float
  (** [line_width c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineWidth}line width} in [c]. *)

  val set_line_width : t -> float -> unit
  (** [set_line_width c w] set the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineWidth}line width} to [w] in [c]. *)

  val line_cap : t -> Line_cap.t
  (** [line_cap c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineCap}line cap} in [c]. *)

  val set_line_cap : t -> Line_cap.t -> unit
  (** [set_line_cap c cap] set the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineCap}line cap} to [cap] in [c]. *)

  val line_join : t -> Line_join.t
  (** [line_join c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineJoin}line join} in [c]. *)

  val set_line_join : t -> Line_join.t -> unit
  (** [set_line_join c join] set the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineJoin}line join} to [join] in [c]. *)

  val miter_limit : t -> float
  (** [miter_limit c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/miterLimit}miter limit} in [c]. *)

  val set_miter_limit : t -> float -> unit
  (** [set_miter_limit c l] set the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/miterLimit}miter limit} to [l] in [c]. *)

  val line_dash : t -> float list
  (** [line_dash c] are the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/getLineDash}line dashes} in [c]. *)

  val set_line_dash : t -> float list -> unit
  (** [set_line_dash c ds]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/setLineDash}sets} the line dashes to [ds] in [c]. *)

  val line_dash_offset : t -> float
  (** [line_dash_offset c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineDashOffset}line dash offset} in [c]. *)

  val set_line_dash_offset : t -> float -> unit
  (** [set_line_dash_offset c o] set the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineDashOffset}line dash offset} to [o] in [c]. *)

  (** {1:style_shadows Style shadows} *)

  val shadow_blur : t -> float
  (** [shadow_blur c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowBlur}shadow blur} of [c]. *)

  val set_shadow_blur : t -> float -> unit
  (** [set_shadow_blur c b] sets the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowBlur}shadow blur} of [c] to [b]. *)

  val shadow_offset_x : t -> float
  (** [shadow_offset_x c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowOffsetX}x shadow offset} of [c]. *)

  val set_shadow_offset_x : t -> float -> unit
  (** [set_shadow_offset_x c o] sets the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowOffsetX}x shadow offset} of [c] to [o] *)

  val shadow_offset_y : t -> float
  (** [shadow_offset_y c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowOffsetY}y shadow offset} of [c]. *)

  val set_shadow_offset_y : t -> float -> unit
  (** [set_shadow_offset_x c o] sets the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowOffsetY}y shadow offset} of [c] to [o]. *)

  val shadow_color : t -> Jstr.t
  (** [shadow_color c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowColor}shadow color} of [c]. *)

  val set_shadow_color : t -> Jstr.t -> unit
  (** [set_shadow_color c col] sets the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowColor}shadow color} of [c] to [col]. *)

  (** {1:text_style Style text} *)

  val font : t -> Jstr.t
  (** [font c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/font}font} in [c]. *)

  val set_font : t -> Jstr.t -> unit
  (** [set_font c fnt] set the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/font}font} to [fnt] in [c]. *)

  val text_align : t -> Text_align.t
  (** [text_align c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/textAlign}text align} in [c]. *)

  val set_text_align : t -> Text_align.t -> unit
  (** [set_text_align c a] set the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/textAlign}text align} to [a] in [c]. *)

  val text_baseline : t -> Text_baseline.t
  (** [text_baseline c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/textBaseline}text baseline} in [c]. *)

  val set_text_baseline : t -> Text_baseline.t -> unit
  (** [set_text_baseline c b] set the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/textBaseline}text baseline} to [b] in [c]. *)

  val text_direction : t -> Text_direction.t
  (** [text_direction c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/direction}text direction} in [c]. *)

  val set_text_direction : t -> Text_direction.t -> unit
  (** [set_direction c d] set the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/direction}text direction} to [d] in [c]. *)

  (** {1:draw_rect Draw rectangles} *)

  val clear_rect : t -> x:float -> y:float -> w:float -> h:float -> unit
  (** [clear_rect c x y ~w ~h] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/clearRect}clears} the given rectangular
      area by setting it to transparent black. *)

  val fill_rect : t -> x:float -> y:float -> w:float -> h:float -> unit
  (** [fill_rect c x y ~w ~h] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillRect}fill} the given rectangular
      area with current {{!set_fill_style}fill style}. *)

  val stroke_rect : t -> x:float -> y:float -> w:float -> h:float -> unit
  (** [stroke_rect c x y ~w ~h] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeRect}strokes} the given rectangular
      area with current {{!set_stroke_style}stroke style}. *)

  (** {1:draw_path Draw paths}

      {b Note.} [fill_rule] always defaults to {!Fill_rule.nonzero}. *)

  val fill : ?fill_rule:Fill_rule.t -> t -> Path.t -> unit
  (** [fill ~fill_rule c p] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fill}fills} [p] in [c] according to [fill_rule]. *)

  val stroke : t -> Path.t -> unit
  (** [stroke c p] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/stroke}strokes} path [p] in [c]. *)

  val clip : ?fill_rule:Fill_rule.t -> t -> Path.t -> unit
  (** [clip ~fill_rule c p] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/clip}clip} drawing to the region of [p] in [c]
      according to [fill_rule]. *)

  val draw_focus_if_needed : t -> Path.t -> El.t -> unit
  (** [draw_focus_if_needed c p e] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/drawFocusIfNeeded}draws} a focus ring
      around [p] in [c] if [e] {{!Brr.El.has_focus}has focus}. *)

  val scroll_path_into_view : t -> Path.t -> unit
  (** [scroll_path_into_view c p]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/scrollPathIntoView}scrolls} path [p] into view in [c]. *)

  val is_point_in_fill :
    ?fill_rule:Fill_rule.t -> t -> Path.t -> x:float -> y:float -> bool
  (** [is_point_in_fill ~fill_rule c p x y] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/isPointInPath}determines} whether ([x],[y])
      is in the fill determiend by path [p] in [c] according to [fill_rule]. *)

  val is_point_in_stroke : t -> Path.t -> x:float -> y:float -> bool
  (** [point_in_path c p x y] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/isPointInStroke}determines} whether ([x],[y])
      is in the stroke determiend by path [p]. *)

  (** {1:draw_text Draw text} *)

  val fill_text : ?max_width:float -> t -> Jstr.t -> x:float -> y:float -> unit
  (** [fill_text c txt x y] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillText}fills text} [txt] at position ([x],[y]). *)

  val stroke_text :
    ?max_width:float -> t -> Jstr.t -> x:float -> y:float -> unit
  (** [fill_text c txt x y] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeText}fills text} [txt] at position ([x],[y]). *)

  (** Text metrics. *)
  module Text_metrics : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/TextMetrics}
        [TextMetrics]} objects. *)

    val width : t -> float
    val actual_bounding_box_left : t -> float
    val actual_bounding_box_right : t -> float
    val font_bounding_box_ascent : t -> float
    val font_bounding_box_descent : t -> float
    val actual_bounding_box_ascent : t -> float
    val actual_bounding_box_descent : t -> float
    val em_height_ascent : t -> float
    val em_height_descent : t -> float
    val hanging_baseline : t -> float
    val alphabetic_baseline : t -> float
    val ideographic_baseline : t -> float
    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  val measure_text : t -> Jstr.t -> Text_metrics.t
  (** [measure_text txt] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/measureText}measures text} [txt]. *)

  (** {1:draw_image Draw images} *)

  val draw_image : t -> image_src -> x:float -> y:float -> unit
  (** [draw_image c i x y] {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/drawImage}draws}
      image [i] in the rectangle of [c] with top-left corner ([x],[y])
      and bottom-right corner ([x+iw], [y+ih]), with [iw] and [ih] the width
      and height of [i] (unclear which unit that is though). *)

  val draw_image_in_rect :
    t -> image_src -> x:float -> y:float -> w:float -> h:float -> unit
  (** [draw_image_in_rect c i x y ~w ~h]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/drawImage}draws}
      image [i] in the rectangle of [c] with top-left corner ([x],[y])
      and bottom-right corner ([x+w], [y+h]). *)

  val draw_sub_image_in_rect :
    t -> image_src -> sx:float -> sy:float -> sw:float -> sh:float ->
    x:float -> y:float -> w:float -> h:float -> unit
  (** [draw_sub_image_in_rect c i ~sx ~sy ~xw ~sh x y ~w ~h]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/drawImage}draws}
      the pixels of [i] in the image space rectangle with
      top-left corner ([sx],[sy]) and bottom-right corner
      ([sx+sw],[sy+sh]) in the rectangle of [c] with top-left corner
      ([x],[y]) and bottom-right corner ([x+w], [y+h]). *)

  (** {1:pixel_manipulation Pixel manipulation} *)

  (** Image data objects *)
  module Image_data : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ImageData}
        ImageData} objects. *)

    val create :
      ?color_space:Jstr.t -> ?data:Tarray.uint8_clamped -> w:int -> h:int ->
      unit -> t
    (** [create ~data ~w ~h ()] is the image data [data] for an image of
        width [w] and height [h]. If [data] is unspecified it is created
        as a transparent black rectangle. If [color_space] is specified
        the given color space is requested. Raises if [data] is specified
        and its length is not [4 * w * h]. *)

    val w : t -> int
    (** [w d] is the image data width. *)

    val h : t -> int
    (** [h d] is the image data height. *)

    val data : t -> Tarray.uint8_clamped
    (** [data d] is the image data of size [4 * w d * h d]. *)

    val color_space : t -> Jstr.t
    (** [color_space d] is the color space of {!data}. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  val create_image_data :
    ?color_space:Jstr.t -> t -> w:int -> h:int -> Image_data.t
  (** [create_image_data c ~w ~h] is a new image data of [w]x[h] transparent
      black pixels. *)

  val get_image_data :
    ?color_space:Jstr.t -> t -> x:int -> y:int -> w:int -> h:int -> Image_data.t
  (** [get_image_data c x y ~w ~h] are the pixels of canvas [c] in the
      image space rectangle with top-left corner ([x],[y]) and
      bottom-right corner ([x+w], [y+h]). *)

  val put_image_data : t -> Image_data.t -> x:int -> y:int -> unit
  (** [put_image_data c d x y] writes the pixels of [d] in the
      image space rectangle of [c] with top-left corner ([x],[y])
      and bottom-right corner ([x+iw], [y+ih]), with [iw] and [ih] the
      width and height of [i]. *)

  val put_sub_image_data :
    t -> Image_data.t -> sx:int -> sy:int -> sw:int -> sh:int -> x:int ->
    y:int -> unit
  (** [put_sub_image_data c d ~sx ~sy ~xw ~sh x y] writes the pixels
      of [d] in the image space rectangle with top-left corner
      ([sx],[sy]) and bottom-right corner ([sx+sw],[sy+sh]) to the
      image space rectangle of [c] with top-left corner ([x],[y]) and
      bottom-right corner ([x+sx], [y+sy]). *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** The {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext}WebGL2} context.

    If you want to get started with WebGL2 from the basics look
    {{:https://webgl2fundamentals.org/}here}. See also the
    {{:https://www.khronos.org/registry/webgl/specs/latest/2.0/}
    WebGL2 specification} and the
    {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API} MDN
    WebGL page}.

    {b Note.} Enumerants like [ARRAY_BUFFER] are lowercased to
    [array_buffer]. If they clash with a function name we prime
    them. If a function is overloaded alternate versions live
    as seperate entry point with an additional suffix, e.g.
    {!Brr_canvas.Gl.buffer_data_size} or
    {!Brr_canvas.Gl.read_pixels_to_pixel_pack}.

    {b Warning.} These bindings were semi-automatically generated.
    Some of the functions signatures may require tweaking; if you doubt
    a signature you may be right. *)
module Gl : sig

  (** {1:ctx Context} *)

  (** Context attributes. *)
  module Attrs : sig

    (** Power preference enumeration. *)
    module Power_preference : sig
      type t = Jstr.t
      val default : t
      val high_performance : t
      val low_power : t
    end

    type t
    (** The type for {{:https://www.khronos.org/registry/webgl/specs/latest/1.0/index.html#WEBGLCONTEXTATTRIBUTES}[WebGLContextAttributes]}. *)

    val v :
      ?alpha:bool -> ?depth:bool -> ?stencil:bool -> ?antialias:bool ->
      ?premultiplied_alpha:bool -> ?preserve_drawing_buffer:bool ->
      ?power_preference:Power_preference.t ->
      ?fail_if_major_performance_caveat:bool -> ?desynchronized:bool -> unit ->
      t
  (** [v ()] are WebGL context attributes with the given {{:https://www.khronos.org/registry/webgl/specs/latest/1.0/index.html#WEBGLCONTEXTATTRIBUTES}
      properties and defaults}. *)

    val alpha : t -> bool
    val depth : t -> bool
    val stencil : t -> bool
    val antialias : t -> bool
    val premultiplied_alpha : t -> bool
    val preserve_drawing_buffer : t -> bool
    val power_preference : t -> Power_preference.t
    val desynchronized : t -> bool
    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext}[WebGL2RenderingContext]} objects *)

  val get_context : ?attrs:Attrs.t -> ?v1:bool -> Canvas.t -> t option
  (** [get_context ~attrs cnv] is WebGL2 context for canvas [cnv] with
      attributes [attrs]. If [v1] is [true] (defaults to [false]) it will
      be a WebGL1 context but beware that some of the functions below do
      not work on it. *)

  val create : ?attrs:Attrs.t -> ?v1:bool -> Canvas.t -> t option
  [@@ocaml.deprecated "use Brr_canvas.Gl.get_context instead."]

  val canvas : t -> Canvas.t option
  (** [canvas c] is the canvas element associated to the context
      [c] (if any). *)

  val drawing_buffer_width : t -> int
  (** [drawing_buffer_width c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/drawingBufferWidth}drawing buffer width} of [c]. *)

  val drawing_buffer_height : t -> int
  (** [drawing_buffer_height c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/drawingBufferHeight}drawing buffer height} of [c]. *)

  val attrs : t -> Attrs.t
  (** [attrs c] are the context's attributes. *)

  val is_context_lost : t -> bool
  (** [is_context_lost c] is [true] if the
      context is {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/isContextLost}lost}. *)

  val get_supported_extensions : t -> Jstr.t list
  (** [get_supported_extensions c] are the {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getSupportedExtensions}extensions} of [c].
  *)

  val get_extension : t -> Jstr.t -> Jv.t
  (** [get_extension c ext] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getExtension}extension} [ext] of [c]. *)

  (** {1:types Types} *)

  type enum = int
  (** The type for GLenum. *)

  type buffer
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLBuffer}
      [WebGLBuffer]} objects. *)

  type framebuffer
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLFramebuffer}
      [WebGLFramebuffer]} objects. *)

  type program
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLProgram}
      [WebGLProgram]} objects. *)

  type query
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLQuery}
      [WebGLQuery]} objects. *)

  type renderbuffer
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderbuffer}
      [WebGLRenderbuffer]} objects. *)

  type sampler
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLSampler}
      [WebGLSampler]} objects. *)

  type shader
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLShader}
      [WebGLShader]} objects. *)

  type sync
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLSync}
      [WebGLSync]} objects. *)

  type texture
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLTexture}
      [WebGLTexture]} objects. *)

  type transform_feedback
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLTransformFeedback}
      [WebGLTransformFeedback]} objects. *)

  type uniform_location
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLUniformLocation}
      [WebGLUniformLocation]} objects. *)

  type vertex_array_object
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLVertexArrayObject} [WebGLVertexArrayObject]} objects. *)

  (** WebGLActiveInfo objects. *)
  module Active_info : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLActiveInfo}
        [WebGLActiveInfo]} objects. *)

    val size : t -> int
    val type' : t -> enum
    val name : t -> Jstr.t
  end

  (** [WebGLShaderPrecisionFormat] objects. *)
  module Shader_precision_format : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLShaderPrecisionFormat}
        [WebGLShaderPrecisionFormat]} objects. *)

    val range_min : t -> int
    val range_max : t -> int
    val precision : t -> int
  end

  (** Texture image sources. *)
  module Tex_image_source : sig
    type t
    val of_image_data : C2d.Image_data.t -> t
    val of_img_el : El.t -> t
    val of_canvas_el : Canvas.t -> t
    val of_video_el : Brr_io.Media.El.t -> t
    val of_offscreen_canvas : Jv.t -> t
  end

  (** {1:funs Functions} *)

  val active_texture : t -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/activeTexture}[activeTexture]}[ ctexture] *)

  val attach_shader : t -> program -> shader -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/attachShader}[attachShader]}[ cprogram shader] *)

  val begin_query : t -> enum -> query -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/beginQuery}[beginQuery]}[ ctarget query] *)

  val begin_transform_feedback : t -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/beginTransformFeedback}[beginTransformFeedback]}[ cprimitiveMode] *)

  val bind_attrib_location : t -> program -> int -> Jstr.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/bindAttribLocation}[bindAttribLocation]}[ cprogram index name] *)

  val bind_buffer : t -> enum -> buffer option -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/bindBuffer}[bindBuffer]}[ ctarget buffer] *)

  val bind_buffer_base : t -> enum -> int -> buffer -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/bindBufferBase}[bindBufferBase]}[ ctarget index buffer] *)

  val bind_buffer_range : t -> enum -> int -> buffer -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/bindBufferRange}[bindBufferRange]}[ ctarget index buffer offset size] *)

  val bind_framebuffer : t -> enum -> framebuffer option -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/bindFramebuffer}[bindFramebuffer]}[ ctarget framebuffer] *)

  val bind_renderbuffer : t -> enum -> renderbuffer option -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/bindRenderbuffer}[bindRenderbuffer]}[ ctarget renderbuffer] *)

  val bind_sampler : t -> int -> sampler option -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/bindSampler}[bindSampler]}[ cunit sampler] *)

  val bind_texture : t -> enum -> texture option -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/bindTexture}[bindTexture]}[ ctarget texture] *)

  val bind_transform_feedback : t -> enum -> transform_feedback option -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/bindTransformFeedback}[bindTransformFeedback]}[ ctarget tf] *)

  val bind_vertex_array : t -> vertex_array_object option -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/bindVertexArray}[bindVertexArray]}[ carray] *)

  val blend_color : t -> float -> float -> float -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/blendColor}[blendColor]}[ cred green blue alpha] *)

  val blend_equation : t -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/blendEquation}[blendEquation]}[ cmode] *)

  val blend_equation_separate : t -> enum -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/blendEquationSeparate}[blendEquationSeparate]}[ cmodeRGB modeAlpha] *)

  val blend_func : t -> enum -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/blendFunc}[blendFunc]}[ csfactor dfactor] *)

  val blend_func_separate : t -> enum -> enum -> enum -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/blendFuncSeparate}[blendFuncSeparate]}[ csrcRGB dstRGB srcAlpha dstAlpha] *)

  val blit_framebuffer : t -> int -> int -> int -> int -> int -> int -> int -> int -> int -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/blitFramebuffer}[blitFramebuffer]}[ csrcX0 srcY0 srcX1 srcY1 dstX0 dstY0 dstX1 dstY1 mask filter] *)

  val buffer_data : t -> enum -> ('a, 'b) Tarray.t -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/bufferData}[bufferData]}[ ctarget srcData usage]. See also {!buffer_data_size}*)

  val buffer_data_size : t -> enum -> int -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/bufferData}[bufferData]}[ ctarget size usage]. *)

  val buffer_sub_data : t -> enum -> int -> ('a, 'b) Tarray.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/bufferSubData}[bufferSubData]}[ ctarget dstByteOffset srcData] *)

  val check_framebuffer_status : t -> enum -> enum
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/checkFramebufferStatus}[checkFramebufferStatus]}[ ctarget] *)

  val clear : t -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/clear}[clear]}[ cmask] *)

  val clear_bufferfi : t -> enum -> int -> float -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/clearBufferfi}[clearBufferfi]}[ cbuffer drawbuffer depth stencil] *)

  val clear_bufferfv : t -> enum -> int -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/clearBufferfv}[clearBufferfv]}[ cbuffer drawbuffer values] *)

  val clear_bufferiv : t -> enum -> int -> Tarray.int32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/clearBufferiv}[clearBufferiv]}[ cbuffer drawbuffer values] *)

  val clear_bufferuiv : t -> enum -> int -> Tarray.uint32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/clearBufferuiv}[clearBufferuiv]}[ cbuffer drawbuffer values] *)

  val clear_color : t -> float -> float -> float -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/clearColor}[clearColor]}[ cred green blue alpha] *)

  val clear_depth : t -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/clearDepth}[clearDepth]}[ cdepth] *)

  val clear_stencil : t -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/clearStencil}[clearStencil]}[ cs] *)

  val client_wait_sync : t -> sync -> int -> int -> enum
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/clientWaitSync}[clientWaitSync]}[ csync flags timeout] *)

  val color_mask : t -> bool -> bool -> bool -> bool -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/colorMask}[colorMask]}[ cred green blue alpha] *)

  val compile_shader : t -> shader -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/compileShader}[compileShader]}[ cshader] *)

  val compressed_tex_image2d : t -> enum -> int -> enum -> int -> int -> int -> ('a, 'b) Tarray.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/compressedTexImage2D}[compressedTexImage2D]}[ ctarget level internalformat width height border srcData] *)

  val compressed_tex_image2d_size : t -> enum -> int -> enum -> int -> int -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/compressedTexImage2D}[compressedTexImage2D]}[ ctarget level internalformat width height border imageSize offset] *)

  val compressed_tex_image3d : t -> enum -> int -> enum -> int -> int -> int -> int -> ('a, 'b) Tarray.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/compressedTexImage3D}[compressedTexImage3D]}[ ctarget level internalformat width height depth border srcData] *)

  val compressed_tex_image3d_size : t -> enum -> int -> enum -> int -> int -> int -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/compressedTexImage3D}[compressedTexImage3D]}[ ctarget level internalformat width height depth border imageSize offset] *)

  val compressed_tex_sub_image2d : t -> enum -> int -> int -> int -> int -> int -> enum -> ('a, 'b) Tarray.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/compressedTexSubImage2D}[compressedTexSubImage2D]}[ ctarget level xoffset yoffset width height format srcData] *)

  val compressed_tex_sub_image2d_size : t -> enum -> int -> int -> int -> int -> int -> enum -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/compressedTexSubImage2D}[compressedTexSubImage2D]}[ ctarget level xoffset yoffset width height format imageSize offset] *)

  val compressed_tex_sub_image3d : t -> enum -> int -> int -> int -> int -> int -> int -> int -> enum -> ('a, 'b) Tarray.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/compressedTexSubImage3D}[compressedTexSubImage3D]}[ ctarget level xoffset yoffset zoffset width height depth format srcData] *)

  val compressed_tex_sub_image3d_size : t -> enum -> int -> int -> int -> int -> int -> int -> int -> enum -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/compressedTexSubImage3D}[compressedTexSubImage3D]}[ ctarget level xoffset yoffset zoffset width height depth format imageSize offset] *)

  val copy_buffer_sub_data : t -> enum -> enum -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/copyBufferSubData}[copyBufferSubData]}[ creadTarget writeTarget readOffset writeOffset size] *)

  val copy_tex_image2d : t -> enum -> int -> enum -> int -> int -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/copyTexImage2D}[copyTexImage2D]}[ ctarget level internalformat x y width height border] *)

  val copy_tex_sub_image2d : t -> enum -> int -> int -> int -> int -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/copyTexSubImage2D}[copyTexSubImage2D]}[ ctarget level xoffset yoffset x y width height] *)

  val copy_tex_sub_image3d : t -> enum -> int -> int -> int -> int -> int -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/copyTexSubImage3D}[copyTexSubImage3D]}[ ctarget level xoffset yoffset zoffset x y width height] *)

  val create_buffer : t -> buffer
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/createBuffer}[createBuffer]}[ c] *)

  val create_framebuffer : t -> framebuffer
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/createFramebuffer}[createFramebuffer]}[ c] *)

  val create_program : t -> program
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/createProgram}[createProgram]}[ c] *)

  val create_query : t -> query
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/createQuery}[createQuery]}[ c] *)

  val create_renderbuffer : t -> renderbuffer
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/createRenderbuffer}[createRenderbuffer]}[ c] *)

  val create_sampler : t -> sampler
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/createSampler}[createSampler]}[ c] *)

  val create_shader : t -> enum -> shader
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/createShader}[createShader]}[ ctype] *)

  val create_texture : t -> texture
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/createTexture}[createTexture]}[ c] *)

  val create_transform_feedback : t -> transform_feedback
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/createTransformFeedback}[createTransformFeedback]}[ c] *)

  val create_vertex_array : t -> vertex_array_object
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/createVertexArray}[createVertexArray]}[ c] *)

  val cull_face : t -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/cullFace}[cullFace]}[ cmode] *)

  val delete_buffer : t -> buffer -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/deleteBuffer}[deleteBuffer]}[ cbuffer] *)

  val delete_framebuffer : t -> framebuffer -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/deleteFramebuffer}[deleteFramebuffer]}[ cframebuffer] *)

  val delete_program : t -> program -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/deleteProgram}[deleteProgram]}[ cprogram] *)

  val delete_query : t -> query -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/deleteQuery}[deleteQuery]}[ cquery] *)

  val delete_renderbuffer : t -> renderbuffer -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/deleteRenderbuffer}[deleteRenderbuffer]}[ crenderbuffer] *)

  val delete_sampler : t -> sampler -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/deleteSampler}[deleteSampler]}[ csampler] *)

  val delete_shader : t -> shader -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/deleteShader}[deleteShader]}[ cshader] *)

  val delete_sync : t -> sync -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/deleteSync}[deleteSync]}[ csync] *)

  val delete_texture : t -> texture -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/deleteTexture}[deleteTexture]}[ ctexture] *)

  val delete_transform_feedback : t -> transform_feedback -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/deleteTransformFeedback}[deleteTransformFeedback]}[ ctf] *)

  val delete_vertex_array : t -> vertex_array_object -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/deleteVertexArray}[deleteVertexArray]}[ cvertexArray] *)

  val depth_func : t -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/depthFunc}[depthFunc]}[ cfunc] *)

  val depth_mask : t -> bool -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/depthMask}[depthMask]}[ cflag] *)

  (* val depth_range : t -> float -> float -> unit *)
  (* (\** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/depthRange}[depthRange]}[ czNear zFar] *\) *)

  val detach_shader : t -> program -> shader -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/detachShader}[detachShader]}[ cprogram shader] *)

  val disable : t -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/disable}[disable]}[ ccap] *)

  val disable_vertex_attrib_array : t -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/disableVertexAttribArray}[disableVertexAttribArray]}[ cindex] *)

  val draw_arrays : t -> enum -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/drawArrays}[drawArrays]}[ cmode first count] *)

  val draw_arrays_instanced : t -> enum -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/drawArraysInstanced}[drawArraysInstanced]}[ cmode first count instanceCount] *)

  val draw_buffers : t -> enum list -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/drawBuffers}[drawBuffers]}[ cbuffers] *)

  val draw_elements : t -> enum -> int -> enum -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/drawElements}[drawElements]}[ cmode count type offset] *)

  val draw_elements_instanced : t -> enum -> int -> enum -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/drawElementsInstanced}[drawElementsInstanced]}[ cmode count type offset instanceCount] *)

  val draw_range_elements : t -> enum -> int -> int -> int -> enum -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/drawRangeElements}[drawRangeElements]}[ cmode start end count type offset] *)

  val enable : t -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/enable}[enable]}[ ccap] *)

  val enable_vertex_attrib_array : t -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/enableVertexAttribArray}[enableVertexAttribArray]}[ cindex] *)

  val end_query : t -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/endQuery}[endQuery]}[ ctarget] *)

  val end_transform_feedback : t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/endTransformFeedback}[endTransformFeedback]}[ c] *)

  val fence_sync : t -> enum -> int -> sync
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/fenceSync}[fenceSync]}[ ccondition flags] *)

  val finish : t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/finish}[finish]}[ c] *)

  val flush : t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/flush}[flush]}[ c] *)

  val framebuffer_renderbuffer : t -> enum -> enum -> enum -> renderbuffer -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/framebufferRenderbuffer}[framebufferRenderbuffer]}[ ctarget attachment renderbuffertarget renderbuffer] *)

  val framebuffer_texture2d : t -> enum -> enum -> enum -> texture -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/framebufferTexture2D}[framebufferTexture2D]}[ ctarget attachment textarget texture level] *)

  val framebuffer_texture_layer : t -> enum -> enum -> texture -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/framebufferTextureLayer}[framebufferTextureLayer]}[ ctarget attachment texture level layer] *)

  val front_face : t -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/frontFace}[frontFace]}[ cmode] *)

  val generate_mipmap : t -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/generateMipmap}[generateMipmap]}[ ctarget] *)

  val get_active_attrib : t -> program -> int -> Active_info.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getActiveAttrib}[getActiveAttrib]}[ cprogram index] *)

  val get_active_uniform : t -> program -> int -> Active_info.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getActiveUniform}[getActiveUniform]}[ cprogram index] *)

  val get_active_uniform_block_name : t -> program -> int -> Jstr.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getActiveUniformBlockName}[getActiveUniformBlockName]}[ cprogram uniformBlockIndex] *)

  val get_active_uniform_block_parameter : t -> program -> int -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getActiveUniformBlockParameter}[getActiveUniformBlockParameter]}[ cprogram uniformBlockIndex pname] *)

  val get_active_uniforms : t -> program -> int list -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getActiveUniforms}[getActiveUniforms]}[ cprogram uniformIndices pname] *)

  val get_attached_shaders : t -> program -> shader list
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getAttachedShaders}[getAttachedShaders]}[ cprogram] *)

  val get_attrib_location : t -> program -> Jstr.t -> int
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getAttribLocation}[getAttribLocation]}[ cprogram name] *)

  val get_buffer_parameter : t -> enum -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getBufferParameter}[getBufferParameter]}[ ctarget pname] *)

  val get_buffer_sub_data : t -> enum -> int -> ('a, 'b) Tarray.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getBufferSubData}[getBufferSubData]}[ ctarget srcByteOffset dstBuffer] *)

  val get_error : t -> enum
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getError}[getError]}[ c] *)

  val get_frag_data_location : t -> program -> Jstr.t -> int
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getFragDataLocation}[getFragDataLocation]}[ cprogram name] *)

  val get_framebuffer_attachment_parameter : t -> enum -> enum -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getFramebufferAttachmentParameter}[getFramebufferAttachmentParameter]}[ ctarget attachment pname] *)

  val get_indexed_parameter : t -> enum -> int -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getIndexedParameter}[getIndexedParameter]}[ ctarget index] *)

  val get_internalformat_parameter : t -> enum -> enum -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getInternalformatParameter}[getInternalformatParameter]}[ ctarget internalformat pname] *)

  val get_parameter : t -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getParameter}[getParameter]}[ cpname] *)

  val get_program_info_log : t -> program -> Jstr.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getProgramInfoLog}[getProgramInfoLog]}[ cprogram] *)

  val get_program_parameter : t -> program -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getProgramParameter}[getProgramParameter]}[ cprogram pname] *)

  val get_query : t -> enum -> enum -> query
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getQuery}[getQuery]}[ ctarget pname] *)

  val get_query_parameter : t -> query -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getQueryParameter}[getQueryParameter]}[ cquery pname] *)

  val get_renderbuffer_parameter : t -> enum -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getRenderbufferParameter}[getRenderbufferParameter]}[ ctarget pname] *)

  val get_sampler_parameter : t -> sampler -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getSamplerParameter}[getSamplerParameter]}[ csampler pname] *)

  val get_shader_info_log : t -> shader -> Jstr.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getShaderInfoLog}[getShaderInfoLog]}[ cshader] *)

  val get_shader_parameter : t -> shader -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getShaderParameter}[getShaderParameter]}[ cshader pname] *)

  val get_shader_precision_format : t -> enum -> enum -> Shader_precision_format.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getShaderPrecisionFormat}[getShaderPrecisionFormat]}[ cshadertype precisiontype] *)

  val get_shader_source : t -> shader -> Jstr.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getShaderSource}[getShaderSource]}[ cshader] *)

  val get_sync_parameter : t -> sync -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getSyncParameter}[getSyncParameter]}[ csync pname] *)

  val get_tex_parameter : t -> enum -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getTexParameter}[getTexParameter]}[ ctarget pname] *)

  val get_transform_feedback_varying : t -> program -> int -> Active_info.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getTransformFeedbackVarying}[getTransformFeedbackVarying]}[ cprogram index] *)

  val get_uniform : t -> program -> uniform_location -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getUniform}[getUniform]}[ cprogram location] *)

  val get_uniform_block_index : t -> program -> Jstr.t -> int
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getUniformBlockIndex}[getUniformBlockIndex]}[ cprogram uniformBlockName] *)

  val get_uniform_indices : t -> program -> Jstr.t list -> int list
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/getUniformIndices}[getUniformIndices]}[ cprogram uniformNames] *)

  val get_uniform_location : t -> program -> Jstr.t -> uniform_location
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getUniformLocation}[getUniformLocation]}[ cprogram name] *)

  val get_vertex_attrib : t -> int -> enum -> Jv.t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getVertexAttrib}[getVertexAttrib]}[ cindex pname] *)

  val get_vertex_attrib_offset : t -> int -> enum -> int
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/getVertexAttribOffset}[getVertexAttribOffset]}[ cindex pname] *)

  val hint : t -> enum -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/hint}[hint]}[ ctarget mode] *)

  val invalidate_framebuffer : t -> enum -> enum list -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/invalidateFramebuffer}[invalidateFramebuffer]}[ ctarget attachments] *)

  val invalidate_sub_framebuffer : t -> enum -> enum list -> int -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/invalidateSubFramebuffer}[invalidateSubFramebuffer]}[ ctarget attachments x y width height] *)

  val is_buffer : t -> buffer -> bool
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/isBuffer}[isBuffer]}[ cbuffer] *)

  val is_enabled : t -> enum -> bool
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/isEnabled}[isEnabled]}[ ccap] *)

  val is_framebuffer : t -> framebuffer -> bool
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/isFramebuffer}[isFramebuffer]}[ cframebuffer] *)

  val is_program : t -> program -> bool
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/isProgram}[isProgram]}[ cprogram] *)

  val is_query : t -> query -> bool
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/isQuery}[isQuery]}[ cquery] *)

  val is_renderbuffer : t -> renderbuffer -> bool
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/isRenderbuffer}[isRenderbuffer]}[ crenderbuffer] *)

  val is_sampler : t -> sampler -> bool
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/isSampler}[isSampler]}[ csampler] *)

  val is_shader : t -> shader -> bool
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/isShader}[isShader]}[ cshader] *)

  val is_texture : t -> texture -> bool
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/isTexture}[isTexture]}[ ctexture] *)

  val is_transform_feedback : t -> transform_feedback -> bool
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/isTransformFeedback}[isTransformFeedback]}[ ctf] *)

  val is_vertex_array : t -> vertex_array_object -> bool
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/isVertexArray}[isVertexArray]}[ cvertexArray] *)

  val line_width : t -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/lineWidth}[lineWidth]}[ cwidth] *)

  val link_program : t -> program -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/linkProgram}[linkProgram]}[ cprogram] *)

  val pause_transform_feedback : t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/pauseTransformFeedback}[pauseTransformFeedback]}[ c] *)

  val pixel_storei : t -> enum -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/pixelStorei}[pixelStorei]}[ cpname param] *)

  val polygon_offset : t -> float -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/polygonOffset}[polygonOffset]}[ cfactor units] *)

  val read_buffer : t -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/readBuffer}[readBuffer]}[ csrc] *)

  val read_pixels_to_pixel_pack : t -> int -> int -> int -> int -> enum -> enum -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/readPixels}[readPixels]}[ cx y width height format type offset] *)

  val read_pixels : t -> int -> int -> int -> int -> enum -> enum -> ('a, 'b) Tarray.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/readPixels}[readPixels]}[ cx y width height format type dstData] *)

  val renderbuffer_storage : t -> enum -> enum -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/renderbufferStorage}[renderbufferStorage]}[ ctarget internalformat width height] *)

  val renderbuffer_storage_multisample : t -> enum -> int -> enum -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/renderbufferStorageMultisample}[renderbufferStorageMultisample]}[ ctarget samples internalformat width height] *)

  val resume_transform_feedback : t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/resumeTransformFeedback}[resumeTransformFeedback]}[ c] *)

  val sample_coverage : t -> float -> bool -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/sampleCoverage}[sampleCoverage]}[ cvalue invert] *)

  val sampler_parameterf : t -> sampler -> enum -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/samplerParameterf}[samplerParameterf]}[ csampler pname param] *)

  val sampler_parameteri : t -> sampler -> enum -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/samplerParameteri}[samplerParameteri]}[ csampler pname param] *)

  val scissor : t -> int -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/scissor}[scissor]}[ cx y width height] *)

  val shader_source : t -> shader -> Jstr.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/shaderSource}[shaderSource]}[ cshader source] *)

  val stencil_func : t -> enum -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/stencilFunc}[stencilFunc]}[ cfunc ref mask] *)

  val stencil_func_separate : t -> enum -> enum -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/stencilFuncSeparate}[stencilFuncSeparate]}[ cface func ref mask] *)

  val stencil_mask : t -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/stencilMask}[stencilMask]}[ cmask] *)

  val stencil_mask_separate : t -> enum -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/stencilMaskSeparate}[stencilMaskSeparate]}[ cface mask] *)

  val stencil_op : t -> enum -> enum -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/stencilOp}[stencilOp]}[ cfail zfail zpass] *)

  val stencil_op_separate : t -> enum -> enum -> enum -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/stencilOpSeparate}[stencilOpSeparate]}[ cface fail zfail zpass] *)

  val tex_image2d : t -> enum -> int -> int -> int -> int -> int -> enum -> enum -> ('a, 'b) Tarray.t -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texImage2D}[texImage2D]}[ ctarget level internalformat width height border format type srcData srcOffset] *)

  val tex_image2d_of_source : t -> enum -> int -> int -> int -> int -> int -> enum -> enum -> Tex_image_source.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texImage2D}[texImage2D]}[ ctarget level internalformat width height border format type source] *)

  val tex_image2d_of_pixel_unpack : t -> enum -> int -> int -> int -> int -> int -> enum -> enum -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texImage2D}[texImage2D]}[ ctarget level internalformat width height border format type pboOffset] *)

  val tex_image3d : t -> enum -> int -> int -> int -> int -> int -> int -> enum -> enum -> ('a, 'b) Tarray.t -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texImage3D}[texImage3D]}[ ctarget level internalformat width height depth border format type srcData srcOffset] *)

  val tex_image3d_of_source : t -> enum -> int -> int -> int -> int -> int -> int -> enum -> enum -> Tex_image_source.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texImage3D}[texImage3D]}[ ctarget level internalformat width height depth border format type source] *)

  val tex_image3d_of_pixel_unpack : t -> enum -> int -> int -> int -> int -> int -> int -> enum -> enum -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texImage3D}[texImage3D]}[ ctarget level internalformat width height depth border format type pboOffset] *)

  val tex_parameterf : t -> enum -> enum -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/texParameterf}[texParameterf]}[ ctarget pname param] *)

  val tex_parameteri : t -> enum -> enum -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/texParameteri}[texParameteri]}[ ctarget pname param] *)

  val tex_storage2d : t -> enum -> int -> enum -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texStorage2D}[texStorage2D]}[ ctarget levels internalformat width height] *)

  val tex_storage3d : t -> enum -> int -> enum -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texStorage3D}[texStorage3D]}[ ctarget levels internalformat width height depth] *)

  val tex_sub_image2d : t -> enum -> int -> int -> int -> int -> int -> enum -> enum -> ('a, 'b) Tarray.t -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texSubImage2D}[texSubImage2D]}[ ctarget level xoffset yoffset width height format type srcData srcOffset] *)

  val tex_sub_image2d_of_source : t -> enum -> int -> int -> int -> int -> int -> enum -> enum -> Tex_image_source.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texSubImage2D}[texSubImage2D]}[ ctarget level xoffset yoffset width height format type source] *)

  val tex_sub_image2d_of_pixel_unpack : t -> enum -> int -> int -> int -> int -> int -> enum -> enum -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texSubImage2D}[texSubImage2D]}[ ctarget level xoffset yoffset width height format type pboOffset] *)

  val tex_sub_image3d : t -> enum -> int -> int -> int -> int -> int -> int -> int -> enum -> enum -> ('a, 'b) Tarray.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texSubImage3D}[texSubImage3D]}[ ctarget level xoffset yoffset zoffset width height depth format type srcData] *)

  val tex_sub_image3d_of_source : t -> enum -> int -> int -> int -> int -> int -> int -> int -> enum -> enum -> Tex_image_source.t -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texSubImage3D}[texSubImage3D]}[ ctarget level xoffset yoffset zoffset width height depth format type source] *)

  val tex_sub_image3d_of_pixel_unpack : t -> enum -> int -> int -> int -> int -> int -> int -> int -> enum -> enum -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/texSubImage3D}[texSubImage3D]}[ ctarget level xoffset yoffset zoffset width height depth format type pboOffset] *)

  val transform_feedback_varyings : t -> program -> Jstr.t list -> enum -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/transformFeedbackVaryings}[transformFeedbackVaryings]}[ cprogram varyings bufferMode] *)

  val uniform1f : t -> uniform_location -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/uniform1f}[uniform1f]}[ clocation x] *)

  val uniform1fv : t -> uniform_location -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform1fv}[uniform1fv]}[ clocation data] *)

  val uniform1i : t -> uniform_location -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/uniform1i}[uniform1i]}[ clocation x] *)

  val uniform1iv : t -> uniform_location -> Tarray.int32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform1iv}[uniform1iv]}[ clocation data] *)

  val uniform1ui : t -> uniform_location -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform1ui}[uniform1ui]}[ clocation v0] *)

  val uniform1uiv : t -> uniform_location -> Tarray.uint32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform1uiv}[uniform1uiv]}[ clocation data] *)

  val uniform2f : t -> uniform_location -> float -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/uniform2f}[uniform2f]}[ clocation x y] *)

  val uniform2fv : t -> uniform_location -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform2fv}[uniform2fv]}[ clocation data] *)

  val uniform2i : t -> uniform_location -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/uniform2i}[uniform2i]}[ clocation x y] *)

  val uniform2iv : t -> uniform_location -> Tarray.int32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform2iv}[uniform2iv]}[ clocation data] *)

  val uniform2ui : t -> uniform_location -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform2ui}[uniform2ui]}[ clocation v0 v1] *)

  val uniform2uiv : t -> uniform_location -> Tarray.uint32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform2uiv}[uniform2uiv]}[ clocation data] *)

  val uniform3f : t -> uniform_location -> float -> float -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/uniform3f}[uniform3f]}[ clocation x y z] *)

  val uniform3fv : t -> uniform_location -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform3fv}[uniform3fv]}[ clocation data] *)

  val uniform3i : t -> uniform_location -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/uniform3i}[uniform3i]}[ clocation x y z] *)

  val uniform3iv : t -> uniform_location -> Tarray.int32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform3iv}[uniform3iv]}[ clocation data] *)

  val uniform3ui : t -> uniform_location -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform3ui}[uniform3ui]}[ clocation v0 v1 v2] *)

  val uniform3uiv : t -> uniform_location -> Tarray.uint32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform3uiv}[uniform3uiv]}[ clocation data] *)

  val uniform4f : t -> uniform_location -> float -> float -> float -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/uniform4f}[uniform4f]}[ clocation x y z w] *)

  val uniform4fv : t -> uniform_location -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform4fv}[uniform4fv]}[ clocation data] *)

  val uniform4i : t -> uniform_location -> int -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/uniform4i}[uniform4i]}[ clocation x y z w] *)

  val uniform4iv : t -> uniform_location -> Tarray.int32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform4iv}[uniform4iv]}[ clocation data] *)

  val uniform4ui : t -> uniform_location -> int -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform4ui}[uniform4ui]}[ clocation v0 v1 v2 v3] *)

  val uniform4uiv : t -> uniform_location -> Tarray.uint32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniform4uiv}[uniform4uiv]}[ clocation data] *)

  val uniform_block_binding : t -> program -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniformBlockBinding}[uniformBlockBinding]}[ cprogram uniformBlockIndex uniformBlockBinding] *)

  val uniform_matrix2fv : t -> uniform_location -> bool -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniformMatrix2fv}[uniformMatrix2fv]}[ clocation transpose data] *)

  val uniform_matrix2x3fv : t -> uniform_location -> bool -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniformMatrix2x3fv}[uniformMatrix2x3fv]}[ clocation transpose data] *)

  val uniform_matrix2x4fv : t -> uniform_location -> bool -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniformMatrix2x4fv}[uniformMatrix2x4fv]}[ clocation transpose data] *)

  val uniform_matrix3fv : t -> uniform_location -> bool -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniformMatrix3fv}[uniformMatrix3fv]}[ clocation transpose data] *)

  val uniform_matrix3x2fv : t -> uniform_location -> bool -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniformMatrix3x2fv}[uniformMatrix3x2fv]}[ clocation transpose data] *)

  val uniform_matrix3x4fv : t -> uniform_location -> bool -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniformMatrix3x4fv}[uniformMatrix3x4fv]}[ clocation transpose data] *)

  val uniform_matrix4fv : t -> uniform_location -> bool -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniformMatrix4fv}[uniformMatrix4fv]}[ clocation transpose data] *)

  val uniform_matrix4x2fv : t -> uniform_location -> bool -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniformMatrix4x2fv}[uniformMatrix4x2fv]}[ clocation transpose data] *)

  val uniform_matrix4x3fv : t -> uniform_location -> bool -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/uniformMatrix4x3fv}[uniformMatrix4x3fv]}[ clocation transpose data] *)

  val use_program : t -> program -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/useProgram}[useProgram]}[ cprogram] *)

  val validate_program : t -> program -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/validateProgram}[validateProgram]}[ cprogram] *)

  val vertex_attrib1f : t -> int -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttrib1f}[vertexAttrib1f]}[ cindex x] *)

  val vertex_attrib1fv : t -> int -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttrib1fv}[vertexAttrib1fv]}[ cindex values] *)

  val vertex_attrib2f : t -> int -> float -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttrib2f}[vertexAttrib2f]}[ cindex x y] *)

  val vertex_attrib2fv : t -> int -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttrib2fv}[vertexAttrib2fv]}[ cindex values] *)

  val vertex_attrib3f : t -> int -> float -> float -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttrib3f}[vertexAttrib3f]}[ cindex x y z] *)

  val vertex_attrib3fv : t -> int -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttrib3fv}[vertexAttrib3fv]}[ cindex values] *)

  val vertex_attrib4f : t -> int -> float -> float -> float -> float -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttrib4f}[vertexAttrib4f]}[ cindex x y z w] *)

  val vertex_attrib4fv : t -> int -> Tarray.float32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttrib4fv}[vertexAttrib4fv]}[ cindex values] *)

  val vertex_attrib_divisor : t -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/vertexAttribDivisor}[vertexAttribDivisor]}[ cindex divisor] *)

  val vertex_attrib_i4i : t -> int -> int -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/vertexAttribI4i}[vertexAttribI4i]}[ cindex x y z w] *)

  val vertex_attrib_i4iv : t -> int -> Tarray.int32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/vertexAttribI4iv}[vertexAttribI4iv]}[ cindex values] *)

  val vertex_attrib_i4ui : t -> int -> int -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/vertexAttribI4ui}[vertexAttribI4ui]}[ cindex x y z w] *)

  val vertex_attrib_i4uiv : t -> int -> Tarray.uint32 -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/vertexAttribI4uiv}[vertexAttribI4uiv]}[ cindex values] *)

  val vertex_attrib_ipointer : t -> int -> int -> enum -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/vertexAttribIPointer}[vertexAttribIPointer]}[ cindex size type stride offset] *)

  val vertex_attrib_pointer : t -> int -> int -> enum -> bool -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/vertexAttribPointer}[vertexAttribPointer]}[ cindex size type normalized stride offset] *)

  val viewport : t -> int -> int -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/viewport}[viewport]}[ cx y width height] *)

  val wait_sync : t -> sync -> int -> int -> unit
  (** {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/waitSync}[waitSync]}[ csync flags timeout] *)




  (** {1:enum Enum values} *)

  val active_attributes : enum
  val active_texture' : enum
  val active_uniform_blocks : enum
  val active_uniforms : enum
  val aliased_line_width_range : enum
  val aliased_point_size_range : enum
  val alpha : enum
  val alpha_bits : enum
  val already_signaled : enum
  val always : enum
  val any_samples_passed : enum
  val any_samples_passed_conservative : enum
  val array_buffer : enum
  val array_buffer_binding : enum
  val attached_shaders : enum
  val back : enum
  val blend : enum
  val blend_color' : enum
  val blend_dst_alpha : enum
  val blend_dst_rgb : enum
  val blend_equation' : enum
  val blend_equation_alpha : enum
  val blend_equation_rgb : enum
  val blend_src_alpha : enum
  val blend_src_rgb : enum
  val blue_bits : enum
  val bool : enum
  val bool_vec2 : enum
  val bool_vec3 : enum
  val bool_vec4 : enum
  val browser_default_webgl : enum
  val buffer_size : enum
  val buffer_usage : enum
  val byte : enum
  val ccw : enum
  val clamp_to_edge : enum
  val color : enum
  val color_attachment0 : enum
  val color_attachment1 : enum
  val color_attachment10 : enum
  val color_attachment11 : enum
  val color_attachment12 : enum
  val color_attachment13 : enum
  val color_attachment14 : enum
  val color_attachment15 : enum
  val color_attachment2 : enum
  val color_attachment3 : enum
  val color_attachment4 : enum
  val color_attachment5 : enum
  val color_attachment6 : enum
  val color_attachment7 : enum
  val color_attachment8 : enum
  val color_attachment9 : enum
  val color_buffer_bit : enum
  val color_clear_value : enum
  val color_writemask : enum
  val compare_ref_to_texture : enum
  val compile_status : enum
  val compressed_texture_formats : enum
  val condition_satisfied : enum
  val constant_alpha : enum
  val constant_color : enum
  val context_lost_webgl : enum
  val copy_read_buffer : enum
  val copy_read_buffer_binding : enum
  val copy_write_buffer : enum
  val copy_write_buffer_binding : enum
  val cull_face' : enum
  val cull_face_mode : enum
  val current_program : enum
  val current_query : enum
  val current_vertex_attrib : enum
  val cw : enum
  val decr : enum
  val decr_wrap : enum
  val delete_status : enum
  val depth : enum
  val depth24_stencil8 : enum
  val depth32f_stencil8 : enum
  val depth_attachment : enum
  val depth_bits : enum
  val depth_buffer_bit : enum
  val depth_clear_value : enum
  val depth_component : enum
  val depth_component16 : enum
  val depth_component24 : enum
  val depth_component32f : enum
  val depth_func' : enum
  val depth_range : enum
  val depth_stencil : enum
  val depth_stencil_attachment : enum
  val depth_test : enum
  val depth_writemask : enum
  val dither : enum
  val dont_care : enum
  val draw_buffer0 : enum
  val draw_buffer1 : enum
  val draw_buffer10 : enum
  val draw_buffer11 : enum
  val draw_buffer12 : enum
  val draw_buffer13 : enum
  val draw_buffer14 : enum
  val draw_buffer15 : enum
  val draw_buffer2 : enum
  val draw_buffer3 : enum
  val draw_buffer4 : enum
  val draw_buffer5 : enum
  val draw_buffer6 : enum
  val draw_buffer7 : enum
  val draw_buffer8 : enum
  val draw_buffer9 : enum
  val draw_framebuffer : enum
  val draw_framebuffer_binding : enum
  val dst_alpha : enum
  val dst_color : enum
  val dynamic_copy : enum
  val dynamic_draw : enum
  val dynamic_read : enum
  val element_array_buffer : enum
  val element_array_buffer_binding : enum
  val equal : enum
  val fastest : enum
  val float : enum
  val float_32_unsigned_int_24_8_rev : enum
  val float_mat2 : enum
  val float_mat2x3 : enum
  val float_mat2x4 : enum
  val float_mat3 : enum
  val float_mat3x2 : enum
  val float_mat3x4 : enum
  val float_mat4 : enum
  val float_mat4x2 : enum
  val float_mat4x3 : enum
  val float_vec2 : enum
  val float_vec3 : enum
  val float_vec4 : enum
  val fragment_shader : enum
  val fragment_shader_derivative_hint : enum
  val framebuffer : enum
  val framebuffer_attachment_alpha_size : enum
  val framebuffer_attachment_blue_size : enum
  val framebuffer_attachment_color_encoding : enum
  val framebuffer_attachment_component_type : enum
  val framebuffer_attachment_depth_size : enum
  val framebuffer_attachment_green_size : enum
  val framebuffer_attachment_object_name : enum
  val framebuffer_attachment_object_type : enum
  val framebuffer_attachment_red_size : enum
  val framebuffer_attachment_stencil_size : enum
  val framebuffer_attachment_texture_cube_map_face : enum
  val framebuffer_attachment_texture_layer : enum
  val framebuffer_attachment_texture_level : enum
  val framebuffer_binding : enum
  val framebuffer_complete : enum
  val framebuffer_default : enum
  val framebuffer_incomplete_attachment : enum
  val framebuffer_incomplete_dimensions : enum
  val framebuffer_incomplete_missing_attachment : enum
  val framebuffer_incomplete_multisample : enum
  val framebuffer_unsupported : enum
  val front : enum
  val front_and_back : enum
  val front_face' : enum
  val func_add : enum
  val func_reverse_subtract : enum
  val func_subtract : enum
  val generate_mipmap_hint : enum
  val gequal : enum
  val greater : enum
  val green_bits : enum
  val half_float : enum
  val high_float : enum
  val high_int : enum
  val implementation_color_read_format : enum
  val implementation_color_read_type : enum
  val incr : enum
  val incr_wrap : enum
  val int : enum
  val int_2_10_10_10_rev : enum
  val int_sampler_2d : enum
  val int_sampler_2d_array : enum
  val int_sampler_3d : enum
  val int_sampler_cube : enum
  val int_vec2 : enum
  val int_vec3 : enum
  val int_vec4 : enum
  val interleaved_attribs : enum
  val invalid_enum : enum
  val invalid_framebuffer_operation : enum
  val invalid_index : enum
  val invalid_operation : enum
  val invalid_value : enum
  val invert : enum
  val keep : enum
  val lequal : enum
  val less : enum
  val line_loop : enum
  val line_strip : enum
  val line_width' : enum
  val linear : enum
  val linear_mipmap_linear : enum
  val linear_mipmap_nearest : enum
  val lines : enum
  val link_status : enum
  val low_float : enum
  val low_int : enum
  val luminance : enum
  val luminance_alpha : enum
  val max : enum
  val max_3d_texture_size : enum
  val max_array_texture_layers : enum
  val max_client_wait_timeout_webgl : enum
  val max_color_attachments : enum
  val max_combined_fragment_uniform_components : enum
  val max_combined_texture_image_units : enum
  val max_combined_uniform_blocks : enum
  val max_combined_vertex_uniform_components : enum
  val max_cube_map_texture_size : enum
  val max_draw_buffers : enum
  val max_element_index : enum
  val max_elements_indices : enum
  val max_elements_vertices : enum
  val max_fragment_input_components : enum
  val max_fragment_uniform_blocks : enum
  val max_fragment_uniform_components : enum
  val max_fragment_uniform_vectors : enum
  val max_program_texel_offset : enum
  val max_renderbuffer_size : enum
  val max_samples : enum
  val max_server_wait_timeout : enum
  val max_texture_image_units : enum
  val max_texture_lod_bias : enum
  val max_texture_size : enum
  val max_transform_feedback_interleaved_components : enum
  val max_transform_feedback_separate_attribs : enum
  val max_transform_feedback_separate_components : enum
  val max_uniform_block_size : enum
  val max_uniform_buffer_bindings : enum
  val max_varying_components : enum
  val max_varying_vectors : enum
  val max_vertex_attribs : enum
  val max_vertex_output_components : enum
  val max_vertex_texture_image_units : enum
  val max_vertex_uniform_blocks : enum
  val max_vertex_uniform_components : enum
  val max_vertex_uniform_vectors : enum
  val max_viewport_dims : enum
  val medium_float : enum
  val medium_int : enum
  val min : enum
  val min_program_texel_offset : enum
  val mirrored_repeat : enum
  val nearest : enum
  val nearest_mipmap_linear : enum
  val nearest_mipmap_nearest : enum
  val never : enum
  val nicest : enum
  val no_error : enum
  val none : enum
  val notequal : enum
  val object_type : enum
  val one : enum
  val one_minus_constant_alpha : enum
  val one_minus_constant_color : enum
  val one_minus_dst_alpha : enum
  val one_minus_dst_color : enum
  val one_minus_src_alpha : enum
  val one_minus_src_color : enum
  val out_of_memory : enum
  val pack_alignment : enum
  val pack_row_length : enum
  val pack_skip_pixels : enum
  val pack_skip_rows : enum
  val pixel_pack_buffer : enum
  val pixel_pack_buffer_binding : enum
  val pixel_unpack_buffer : enum
  val pixel_unpack_buffer_binding : enum
  val points : enum
  val polygon_offset_factor : enum
  val polygon_offset_fill : enum
  val polygon_offset_units : enum
  val query_result : enum
  val query_result_available : enum
  val r11f_g11f_b10f : enum
  val r16f : enum
  val r16i : enum
  val r16ui : enum
  val r32f : enum
  val r32i : enum
  val r32ui : enum
  val r8 : enum
  val r8_snorm : enum
  val r8i : enum
  val r8ui : enum
  val rasterizer_discard : enum
  val read_buffer' : enum
  val read_framebuffer : enum
  val read_framebuffer_binding : enum
  val red : enum
  val red_bits : enum
  val red_integer : enum
  val renderbuffer : enum
  val renderbuffer_alpha_size : enum
  val renderbuffer_binding : enum
  val renderbuffer_blue_size : enum
  val renderbuffer_depth_size : enum
  val renderbuffer_green_size : enum
  val renderbuffer_height : enum
  val renderbuffer_internal_format : enum
  val renderbuffer_red_size : enum
  val renderbuffer_samples : enum
  val renderbuffer_stencil_size : enum
  val renderbuffer_width : enum
  val renderer : enum
  val repeat : enum
  val replace : enum
  val rg : enum
  val rg16f : enum
  val rg16i : enum
  val rg16ui : enum
  val rg32f : enum
  val rg32i : enum
  val rg32ui : enum
  val rg8 : enum
  val rg8_snorm : enum
  val rg8i : enum
  val rg8ui : enum
  val rg_integer : enum
  val rgb : enum
  val rgb10_a2 : enum
  val rgb10_a2ui : enum
  val rgb16f : enum
  val rgb16i : enum
  val rgb16ui : enum
  val rgb32f : enum
  val rgb32i : enum
  val rgb32ui : enum
  val rgb565 : enum
  val rgb5_a1 : enum
  val rgb8 : enum
  val rgb8_snorm : enum
  val rgb8i : enum
  val rgb8ui : enum
  val rgb9_e5 : enum
  val rgb_integer : enum
  val rgba : enum
  val rgba16f : enum
  val rgba16i : enum
  val rgba16ui : enum
  val rgba32f : enum
  val rgba32i : enum
  val rgba32ui : enum
  val rgba4 : enum
  val rgba8 : enum
  val rgba8_snorm : enum
  val rgba8i : enum
  val rgba8ui : enum
  val rgba_integer : enum
  val sample_alpha_to_coverage : enum
  val sample_buffers : enum
  val sample_coverage' : enum
  val sample_coverage_invert : enum
  val sample_coverage_value : enum
  val sampler_2d : enum
  val sampler_2d_array : enum
  val sampler_2d_array_shadow : enum
  val sampler_2d_shadow : enum
  val sampler_3d : enum
  val sampler_binding : enum
  val sampler_cube : enum
  val sampler_cube_shadow : enum
  val samples : enum
  val scissor_box : enum
  val scissor_test : enum
  val separate_attribs : enum
  val shader_type : enum
  val shading_language_version : enum
  val short : enum
  val signaled : enum
  val signed_normalized : enum
  val src_alpha : enum
  val src_alpha_saturate : enum
  val src_color : enum
  val srgb : enum
  val srgb8 : enum
  val srgb8_alpha8 : enum
  val static_copy : enum
  val static_draw : enum
  val static_read : enum
  val stencil : enum
  val stencil_attachment : enum
  val stencil_back_fail : enum
  val stencil_back_func : enum
  val stencil_back_pass_depth_fail : enum
  val stencil_back_pass_depth_pass : enum
  val stencil_back_ref : enum
  val stencil_back_value_mask : enum
  val stencil_back_writemask : enum
  val stencil_bits : enum
  val stencil_buffer_bit : enum
  val stencil_clear_value : enum
  val stencil_fail : enum
  val stencil_func' : enum
  val stencil_index8 : enum
  val stencil_pass_depth_fail : enum
  val stencil_pass_depth_pass : enum
  val stencil_ref : enum
  val stencil_test : enum
  val stencil_value_mask : enum
  val stencil_writemask : enum
  val stream_copy : enum
  val stream_draw : enum
  val stream_read : enum
  val subpixel_bits : enum
  val sync_condition : enum
  val sync_fence : enum
  val sync_flags : enum
  val sync_flush_commands_bit : enum
  val sync_gpu_commands_complete : enum
  val sync_status : enum
  val texture : enum
  val texture0 : enum
  val texture1 : enum
  val texture10 : enum
  val texture11 : enum
  val texture12 : enum
  val texture13 : enum
  val texture14 : enum
  val texture15 : enum
  val texture16 : enum
  val texture17 : enum
  val texture18 : enum
  val texture19 : enum
  val texture2 : enum
  val texture20 : enum
  val texture21 : enum
  val texture22 : enum
  val texture23 : enum
  val texture24 : enum
  val texture25 : enum
  val texture26 : enum
  val texture27 : enum
  val texture28 : enum
  val texture29 : enum
  val texture3 : enum
  val texture30 : enum
  val texture31 : enum
  val texture4 : enum
  val texture5 : enum
  val texture6 : enum
  val texture7 : enum
  val texture8 : enum
  val texture9 : enum
  val texture_2d : enum
  val texture_2d_array : enum
  val texture_3d : enum
  val texture_base_level : enum
  val texture_binding_2d : enum
  val texture_binding_2d_array : enum
  val texture_binding_3d : enum
  val texture_binding_cube_map : enum
  val texture_compare_func : enum
  val texture_compare_mode : enum
  val texture_cube_map : enum
  val texture_cube_map_negative_x : enum
  val texture_cube_map_negative_y : enum
  val texture_cube_map_negative_z : enum
  val texture_cube_map_positive_x : enum
  val texture_cube_map_positive_y : enum
  val texture_cube_map_positive_z : enum
  val texture_immutable_format : enum
  val texture_immutable_levels : enum
  val texture_mag_filter : enum
  val texture_max_level : enum
  val texture_max_lod : enum
  val texture_min_filter : enum
  val texture_min_lod : enum
  val texture_wrap_r : enum
  val texture_wrap_s : enum
  val texture_wrap_t : enum
  val timeout_expired : enum
  val timeout_ignored : int
  val transform_feedback : enum
  val transform_feedback_active : enum
  val transform_feedback_binding : enum
  val transform_feedback_buffer : enum
  val transform_feedback_buffer_binding : enum
  val transform_feedback_buffer_mode : enum
  val transform_feedback_buffer_size : enum
  val transform_feedback_buffer_start : enum
  val transform_feedback_paused : enum
  val transform_feedback_primitives_written : enum
  val transform_feedback_varyings' : enum
  val triangle_fan : enum
  val triangle_strip : enum
  val triangles : enum
  val uniform_array_stride : enum
  val uniform_block_active_uniform_indices : enum
  val uniform_block_active_uniforms : enum
  val uniform_block_binding' : enum
  val uniform_block_data_size : enum
  val uniform_block_index : enum
  val uniform_block_referenced_by_fragment_shader : enum
  val uniform_block_referenced_by_vertex_shader : enum
  val uniform_buffer : enum
  val uniform_buffer_binding : enum
  val uniform_buffer_offset_alignment : enum
  val uniform_buffer_size : enum
  val uniform_buffer_start : enum
  val uniform_is_row_major : enum
  val uniform_matrix_stride : enum
  val uniform_offset : enum
  val uniform_size : enum
  val uniform_type : enum
  val unpack_alignment : enum
  val unpack_colorspace_conversion_webgl : enum
  val unpack_flip_y_webgl : enum
  val unpack_image_height : enum
  val unpack_premultiply_alpha_webgl : enum
  val unpack_row_length : enum
  val unpack_skip_images : enum
  val unpack_skip_pixels : enum
  val unpack_skip_rows : enum
  val unsignaled : enum
  val unsigned_byte : enum
  val unsigned_int : enum
  val unsigned_int_10f_11f_11f_rev : enum
  val unsigned_int_24_8 : enum
  val unsigned_int_2_10_10_10_rev : enum
  val unsigned_int_5_9_9_9_rev : enum
  val unsigned_int_sampler_2d : enum
  val unsigned_int_sampler_2d_array : enum
  val unsigned_int_sampler_3d : enum
  val unsigned_int_sampler_cube : enum
  val unsigned_int_vec2 : enum
  val unsigned_int_vec3 : enum
  val unsigned_int_vec4 : enum
  val unsigned_normalized : enum
  val unsigned_short : enum
  val unsigned_short_4_4_4_4 : enum
  val unsigned_short_5_5_5_1 : enum
  val unsigned_short_5_6_5 : enum
  val validate_status : enum
  val vendor : enum
  val version : enum
  val vertex_array_binding : enum
  val vertex_attrib_array_buffer_binding : enum
  val vertex_attrib_array_divisor : enum
  val vertex_attrib_array_enabled : enum
  val vertex_attrib_array_integer : enum
  val vertex_attrib_array_normalized : enum
  val vertex_attrib_array_pointer : enum
  val vertex_attrib_array_size : enum
  val vertex_attrib_array_stride : enum
  val vertex_attrib_array_type : enum
  val vertex_shader : enum
  val viewport' : enum
  val wait_failed : enum
  val zero : enum
end
