open Js_of_ocaml

type raw_node = Dom.node Js.t
type 'a live = 'a Lwd_seq.t Lwd.t
type 'a attr = 'a option Lwd.t

(** {1 TyXML compatible representation of XML documents} *)

module Xml : Xml_sigs.T
  with type 'a W.t = 'a Lwd.t
   and type (-'a, 'b) W.ft = 'a -> 'b
   and type 'a W.tlist = 'a Lwd.t list
   and type uri = string
   and type elt = raw_node live
   and type event_handler          = (Dom_html.event Js.t -> bool) attr
   and type mouse_event_handler    = (Dom_html.mouseEvent Js.t -> bool) attr
   and type keyboard_event_handler = (Dom_html.keyboardEvent Js.t -> bool) attr
   and type touch_event_handler    = (Dom_html.touchEvent Js.t -> bool) attr

(** {1 TyXML produced Svg and Html} *)

type +'a node = private raw_node

open Svg_types
module Svg : sig
  type +'a elt = 'a node live
  type doc = [`Svg] elt
  type +'a attrib

  module Xml = Xml
  type ('a, 'b) nullary = ?a:'a attrib list -> unit -> 'b elt
  type ('a, 'b, 'c) unary = ?a:'a attrib list -> 'b elt -> 'c elt
  type ('a, 'b, 'c) star = ?a:'a attrib list -> 'b elt list -> 'c elt

  module Info : Xml_sigs.Info
  type uri = string
  val string_of_uri : uri -> string
  val uri_of_string : string -> uri

  val a_x : Unit.length Lwd.t -> [>`X] attrib
  val a_y : Unit.length Lwd.t -> [>`Y] attrib
  val a_width : Unit.length Lwd.t -> [>`Width] attrib
  val a_height : Unit.length Lwd.t -> [>`Height] attrib
  val a_preserveAspectRatio : uri Lwd.t -> [>`PreserveAspectRatio] attrib
  val a_zoomAndPan : [<`Disable|`Magnify] Lwd.t -> [>`ZoomAndSpan] attrib
  val a_href : uri Lwd.t -> [>`Xlink_href] attrib
  val a_requiredExtensions : spacestrings Lwd.t -> [>`RequiredExtension] attrib
  val a_systemLanguage :
    commastrings Lwd.t -> [>`SystemLanguage] attrib
  val a_externalRessourcesRequired :
    bool Lwd.t -> [>`ExternalRessourcesRequired] attrib
  val a_id : uri Lwd.t -> [>`Id] attrib
  val a_user_data : uri -> uri Lwd.t -> [>`User_data] attrib
  val a_xml_lang : uri Lwd.t -> [>`Xml_Lang] attrib
  val a_type : uri Lwd.t -> [>`Type] attrib
  val a_media : commastrings Lwd.t -> [>`Media] attrib
  val a_class : spacestrings Lwd.t -> [>`Class] attrib
  val a_style : uri Lwd.t -> [>`Style] attrib
  val a_transform : transforms Lwd.t -> [>`Transform] attrib
  val a_viewBox : fourfloats Lwd.t -> [>`ViewBox] attrib
  val a_d : uri Lwd.t -> [>`D] attrib
  val a_pathLength : float Lwd.t -> [>`PathLength] attrib
  val a_rx : Unit.length Lwd.t -> [>`Rx] attrib
  val a_ry : Unit.length Lwd.t -> [>`Ry] attrib
  val a_cx : Unit.length Lwd.t -> [>`Cx] attrib
  val a_cy : Unit.length Lwd.t -> [>`Cy] attrib
  val a_r : Unit.length Lwd.t -> [>`R] attrib
  val a_x1 : Unit.length Lwd.t -> [>`X1] attrib
  val a_y1 : Unit.length Lwd.t -> [>`Y1] attrib
  val a_x2 : Unit.length Lwd.t -> [>`X2] attrib
  val a_y2 : Unit.length Lwd.t -> [>`Y2] attrib
  val a_points : coords Lwd.t -> [>`Points] attrib
  val a_x_list : lengths Lwd.t -> [>`X_list] attrib
  val a_y_list : lengths Lwd.t -> [>`Y_list] attrib
  val a_dx : float Lwd.t -> [>`Dx] attrib
  val a_dy : float Lwd.t -> [>`Dy] attrib
  val a_dx_list : lengths Lwd.t -> [>`Dx_list] attrib
  val a_dy_list : lengths Lwd.t -> [>`Dy_list] attrib
  val a_lengthAdjust :
    [<`Spacing|`SpacingAndGlyphs] Lwd.t -> [>`LengthAdjust] attrib
  val a_textLength : Unit.length Lwd.t -> [>`TextLength] attrib
  val a_text_anchor :
    [<`End|`Inherit|`Middle|`Start] Lwd.t -> [>`Text_Anchor] attrib
  val a_text_decoration :
    [<`Blink|`Inherit|`Line_through|`None|`Overline|`Underline] Lwd.t ->
    [>`Text_Decoration] attrib
  val a_text_rendering :
    [<`Auto|`GeometricPrecision|`Inherit
    |`OptimizeLegibility|`OptimizeSpeed] Lwd.t ->
    [>`Text_Rendering] attrib
  val a_rotate : numbers Lwd.t -> [>`Rotate] attrib
  val a_startOffset : Unit.length Lwd.t -> [>`StartOffset] attrib
  val a_method : [<`Align | `Stretch] Lwd.t -> [>`Method] attrib
  val a_spacing : [<`Auto | `Exact] Lwd.t -> [>`Spacing] attrib
  val a_glyphRef : uri Lwd.t -> [>`GlyphRef] attrib
  val a_format : uri Lwd.t -> [>`Format] attrib
  val a_markerUnits :
    [<`StrokeWidth | `UserSpaceOnUse] Lwd.t -> [>`MarkerUnits] attrib
  val a_refX : Unit.length Lwd.t -> [>`RefX] attrib
  val a_refY : Unit.length Lwd.t -> [>`RefY] attrib
  val a_markerWidth : Unit.length Lwd.t -> [>`MarkerWidth] attrib
  val a_markerHeight :
    Unit.length Lwd.t -> [>`MarkerHeight] attrib
  val a_orient : Unit.angle option Lwd.t -> [>`Orient] attrib
  val a_local : uri Lwd.t -> [>`Local] attrib
  val a_rendering_intent :
    [<`Absolute_colorimetric|`Auto|`Perceptual
    |`Relative_colorimetric|`Saturation] Lwd.t ->
    [>`Rendering_Indent] attrib
  val a_gradientUnits :
    [<`ObjectBoundingBox|`UserSpaceOnUse] Lwd.t -> [`GradientUnits] attrib
  val a_gradientTransform : transforms Lwd.t -> [>`Gradient_Transform] attrib
  val a_spreadMethod : [<`Pad|`Reflect|`Repeat] Lwd.t -> [>`SpreadMethod] attrib
  val a_fx : Unit.length Lwd.t -> [>`Fx] attrib
  val a_fy : Unit.length Lwd.t -> [>`Fy] attrib
  val a_offset : [<`Number of float | `Percentage of float] Lwd.t ->
    [>`Offset] attrib
  val a_patternUnits : [<`ObjectBoundingBox|`UserSpaceOnUse] Lwd.t ->
    [>`PatternUnits] attrib
  val a_patternContentUnits : [<`ObjectBoundingBox|`UserSpaceOnUse] Lwd.t ->
    [>`PatternContentUnits] attrib
  val a_patternTransform : transforms Lwd.t -> [>`PatternTransform] attrib
  val a_clipPathUnits : [<`ObjectBoundingBox|`UserSpaceOnUse] Lwd.t ->
    [>`ClipPathUnits] attrib
  val a_maskUnits : [<`ObjectBoundingBox|`UserSpaceOnUse] Lwd.t ->
    [>`MaskUnits] attrib
  val a_maskContentUnits : [<`ObjectBoundingBox|`UserSpaceOnUse] Lwd.t ->
    [>`MaskContentUnits] attrib
  val a_primitiveUnits : [<`ObjectBoundingBox|`UserSpaceOnUse] Lwd.t ->
    [>`PrimitiveUnits] attrib
  val a_filterRes : number_optional_number Lwd.t -> [>`FilterResUnits] attrib
  val a_result : uri Lwd.t -> [>`Result] attrib
  val a_in :
    [<`BackgroundAlpha|`BackgroundImage|`FillPaint|`Ref of uri
    |`SourceAlpha|`SourceGraphic|`StrokePaint] Lwd.t -> [>`In] attrib
  val a_in2 :
    [<`BackgroundAlpha|`BackgroundImage|`FillPaint|`Ref of uri
    |`SourceAlpha|`SourceGraphic|`StrokePaint] Lwd.t -> [>`In2] attrib
  val a_azimuth : float Lwd.t -> [>`Azimuth] attrib
  val a_elevation : float Lwd.t -> [>`Elevation] attrib
  val a_pointsAtX : float Lwd.t -> [>`PointsAtX] attrib
  val a_pointsAtY : float Lwd.t -> [>`PointsAtY] attrib
  val a_pointsAtZ : float Lwd.t -> [>`PointsAtZ] attrib
  val a_specularExponent : float Lwd.t -> [>`SpecularExponent] attrib
  val a_specularConstant : float Lwd.t -> [>`SpecularConstant] attrib
  val a_limitingConeAngle : float Lwd.t -> [>`LimitingConeAngle] attrib
  val a_mode :
    [<`Darken|`Lighten|`Multiply|`Normal|`Screen] Lwd.t -> [>`Mode] attrib
  val a_feColorMatrix_type :
    [<`HueRotate|`LuminanceToAlpha|`Matrix|`Saturate] Lwd.t ->
    [>`Typefecolor] attrib
  val a_values : numbers Lwd.t -> [>`Values] attrib
  val a_transfer_type : [<`Discrete|`Gamma|`Identity|`Linear|`Table] Lwd.t ->
    [>`Type_transfert] attrib
  val a_tableValues : numbers Lwd.t -> [>`TableValues] attrib
  val a_intercept : float Lwd.t -> [>`Intercept] attrib
  val a_amplitude : float Lwd.t -> [>`Amplitude] attrib
  val a_exponent : float Lwd.t -> [>`Exponent] attrib
  val a_transfer_offset : float Lwd.t -> [>`Offset_transfer] attrib
  val a_feComposite_operator : [<`Arithmetic|`Atop|`In|`Out|`Over|`Xor] Lwd.t ->
    [>`OperatorComposite] attrib
  val a_k1 : float Lwd.t -> [>`K1] attrib
  val a_k2 : float Lwd.t -> [>`K2] attrib
  val a_k3 : float Lwd.t -> [>`K3] attrib
  val a_k4 : float Lwd.t -> [>`K4] attrib
  val a_order : number_optional_number Lwd.t -> [>`Order] attrib
  val a_kernelMatrix : numbers Lwd.t -> [>`KernelMatrix] attrib
  val a_divisor : float Lwd.t -> [>`Divisor] attrib
  val a_bias : float Lwd.t -> [>`Bias] attrib
  val a_kernelUnitLength :
    number_optional_number Lwd.t -> [>`KernelUnitLength] attrib
  val a_targetX : int Lwd.t -> [>`TargetX] attrib
  val a_targetY : int Lwd.t -> [>`TargetY] attrib
  val a_edgeMode : [<`Duplicate|`None|`Wrap] Lwd.t -> [>`TargetY] attrib
  val a_preserveAlpha : bool Lwd.t -> [>`TargetY] attrib
  val a_surfaceScale : float Lwd.t -> [>`SurfaceScale] attrib
  val a_diffuseConstant : float Lwd.t -> [>`DiffuseConstant] attrib
  val a_scale : float Lwd.t -> [>`Scale] attrib
  val a_xChannelSelector : [<`A|`B|`G|`R] Lwd.t -> [>`XChannelSelector] attrib
  val a_yChannelSelector : [<`A|`B|`G|`R] Lwd.t -> [>`YChannelSelector] attrib
  val a_stdDeviation : number_optional_number Lwd.t -> [>`StdDeviation] attrib
  val a_feMorphology_operator : [<`Dilate|`Erode] Lwd.t -> [>`OperatorMorphology] attrib
  val a_radius : number_optional_number Lwd.t -> [>`Radius] attrib
  val a_baseFrenquency : number_optional_number Lwd.t -> [>`BaseFrequency] attrib
  val a_numOctaves : int Lwd.t -> [>`NumOctaves] attrib
  val a_seed : float Lwd.t -> [>`Seed] attrib
  val a_stitchTiles : [<`NoStitch|`Stitch] Lwd.t -> [>`StitchTiles] attrib
  val a_feTurbulence_type : [<`FractalNoise|`Turbulence] Lwd.t -> [>`TypeStitch] attrib
  val a_target : uri Lwd.t -> [>`Xlink_target] attrib
  val a_attributeName : uri Lwd.t -> [>`AttributeName] attrib
  val a_attributeType : [<`Auto|`CSS|`XML] Lwd.t -> [>`AttributeType] attrib
  val a_begin : uri Lwd.t -> [>`Begin] attrib
  val a_dur : uri Lwd.t -> [>`Dur] attrib
  val a_min : uri Lwd.t -> [>`Min] attrib
  val a_max : uri Lwd.t -> [>`Max] attrib
  val a_restart : [<`Always|`Never|`WhenNotActive] Lwd.t -> [>`Restart] attrib
  val a_repeatCount : uri Lwd.t -> [>`RepeatCount] attrib
  val a_repeatDur : uri Lwd.t -> [>`RepeatDur] attrib
  val a_fill : paint Lwd.t -> [>`Fill] attrib
  val a_animation_fill : [<`Freeze|`Remove] Lwd.t -> [>`Fill_Animation] attrib
  val a_calcMode : [<`Discrete|`Linear|`Paced|`Spline] Lwd.t -> [>`CalcMode] attrib
  val a_animation_values : strings Lwd.t -> [>`Valuesanim] attrib
  val a_keyTimes : strings Lwd.t -> [>`KeyTimes] attrib
  val a_keySplines : strings Lwd.t -> [>`KeySplines] attrib
  val a_from : uri Lwd.t -> [>`From] attrib
  val a_to : uri Lwd.t -> [>`To] attrib
  val a_by : uri Lwd.t -> [>`By] attrib
  val a_additive : [<`Replace|`Sum] Lwd.t -> [>`Additive] attrib
  val a_accumulate : [<`None|`Sum] Lwd.t -> [>`Accumulate] attrib
  val a_keyPoints : numbers_semicolon Lwd.t -> [>`KeyPoints] attrib
  val a_path : uri Lwd.t -> [>`Path] attrib
  val a_animateTransform_type :
    [`Rotate|`Scale|`SkewX|`SkewY|`Translate] Lwd.t ->
    [`Typeanimatetransform] attrib
  val a_horiz_origin_x : float Lwd.t -> [>`HorizOriginX] attrib
  val a_horiz_origin_y : float Lwd.t -> [>`HorizOriginY] attrib
  val a_horiz_adv_x : float Lwd.t -> [>`HorizAdvX] attrib
  val a_vert_origin_x : float Lwd.t -> [>`VertOriginX] attrib
  val a_vert_origin_y : float Lwd.t -> [>`VertOriginY] attrib
  val a_vert_adv_y : float Lwd.t -> [>`VertAdvY] attrib
  val a_unicode : uri Lwd.t -> [>`Unicode] attrib
  val a_glyph_name : uri Lwd.t -> [>`glyphname] attrib
  val a_orientation : [<`H | `V] Lwd.t -> [>`Orientation] attrib
  val a_arabic_form : [<`Initial|`Isolated|`Medial|`Terminal] Lwd.t ->
    [>`Arabicform] attrib
  val a_lang : uri Lwd.t -> [>`Lang] attrib
  val a_u1 : uri Lwd.t -> [>`U1] attrib
  val a_u2 : uri Lwd.t -> [>`U2] attrib
  val a_g1 : uri Lwd.t -> [>`G1] attrib
  val a_g2 : uri Lwd.t -> [>`G2] attrib
  val a_k : uri Lwd.t -> [>`K] attrib
  val a_font_family : uri Lwd.t -> [>`Font_Family] attrib
  val a_font_style : uri Lwd.t -> [>`Font_Style] attrib
  val a_font_variant : uri Lwd.t -> [>`Font_Variant] attrib
  val a_font_weight : uri Lwd.t -> [>`Font_Weight] attrib
  val a_font_stretch : uri Lwd.t -> [>`Font_Stretch] attrib
  val a_font_size : uri Lwd.t -> [>`Font_Size] attrib
  val a_unicode_range : uri Lwd.t -> [>`UnicodeRange] attrib
  val a_units_per_em : uri Lwd.t -> [>`UnitsPerEm] attrib
  val a_stemv : float Lwd.t -> [>`Stemv] attrib
  val a_stemh : float Lwd.t -> [>`Stemh] attrib
  val a_slope : float Lwd.t -> [>`Slope] attrib
  val a_cap_height : float Lwd.t -> [>`CapHeight] attrib
  val a_x_height : float Lwd.t -> [>`XHeight] attrib
  val a_accent_height : float Lwd.t -> [>`AccentHeight] attrib
  val a_ascent : float Lwd.t -> [>`Ascent] attrib
  val a_widths : uri Lwd.t -> [>`Widths] attrib
  val a_bbox : uri Lwd.t -> [>`Bbox] attrib
  val a_ideographic : float Lwd.t -> [>`Ideographic] attrib
  val a_alphabetic : float Lwd.t -> [>`Alphabetic] attrib
  val a_mathematical : float Lwd.t -> [>`Mathematical] attrib
  val a_hanging : float Lwd.t -> [>`Hanging] attrib
  val a_videographic : float Lwd.t -> [>`VIdeographic] attrib
  val a_v_alphabetic : float Lwd.t -> [>`VAlphabetic] attrib
  val a_v_mathematical : float Lwd.t -> [>`VMathematical] attrib
  val a_v_hanging : float Lwd.t -> [>`VHanging] attrib
  val a_underline_position : float Lwd.t -> [>`UnderlinePosition] attrib
  val a_underline_thickness : float Lwd.t -> [>`UnderlineThickness] attrib
  val a_strikethrough_position : float Lwd.t -> [>`StrikethroughPosition] attrib
  val a_strikethrough_thickness : float Lwd.t -> [>`StrikethroughThickness] attrib
  val a_overline_position : float Lwd.t -> [>`OverlinePosition] attrib
  val a_overline_thickness : float Lwd.t -> [>`OverlineThickness] attrib
  val a_string : uri Lwd.t -> [>`String] attrib
  val a_name : uri Lwd.t -> [>`Name] attrib
  val a_alignment_baseline :
    [<`After_edge|`Alphabetic|`Auto|`Baseline|`Before_edge|`Central|`Hanging
    |`Ideographic|`Inherit|`Mathematical|`Middle
    |`Text_after_edge|`Text_before_edge] Lwd.t -> [>`Alignment_Baseline] attrib
  val a_dominant_baseline :
    [<`Alphabetic|`Auto|`Central|`Hanging|`Ideographic|`Inherit
    |`Mathematical|`Middle|`No_change|`Reset_size|`Text_after_edge
    |`Text_before_edge|`Use_script] Lwd.t -> [>`Dominant_Baseline] attrib
  val a_stop_color : uri Lwd.t -> [>`Stop_Color] attrib
  val a_stop_opacity : float Lwd.t -> [>`Stop_Opacity] attrib
  val a_stroke : paint Lwd.t -> [>`Stroke] attrib
  val a_stroke_width : Unit.length Lwd.t -> [>`Stroke_Width] attrib
  val a_stroke_linecap : [<`Butt|`Round|`Square] Lwd.t -> [>`Stroke_Linecap] attrib
  val a_stroke_linejoin : [<`Bever|`Miter|`Round] Lwd.t -> [>`Stroke_Linejoin] attrib
  val a_stroke_miterlimit : float Lwd.t -> [>`Stroke_Miterlimit] attrib
  val a_stroke_dasharray : Unit.length list Lwd.t -> [>`Stroke_Dasharray] attrib
  val a_stroke_dashoffset : Unit.length Lwd.t -> [>`Stroke_Dashoffset] attrib
  val a_stroke_opacity : float Lwd.t -> [>`Stroke_Opacity] attrib
  val a_onabort : Xml.event_handler -> [>`OnAbort] attrib
  val a_onactivate : Xml.event_handler -> [>`OnActivate] attrib
  val a_onbegin : Xml.event_handler -> [>`OnBegin] attrib
  val a_onend : Xml.event_handler -> [>`OnEnd] attrib
  val a_onerror : Xml.event_handler -> [>`OnError] attrib
  val a_onfocusin : Xml.event_handler -> [>`OnFocusIn] attrib
  val a_onfocusout : Xml.event_handler -> [>`OnFocusOut] attrib
  val a_onrepeat : Xml.event_handler -> [>`OnRepeat] attrib
  val a_onresize : Xml.event_handler -> [>`OnResize] attrib
  val a_onscroll : Xml.event_handler -> [>`OnScroll] attrib
  val a_onunload : Xml.event_handler -> [>`OnUnload] attrib
  val a_onzoom : Xml.event_handler -> [>`OnZoom] attrib
  val a_onclick : Xml.mouse_event_handler -> [>`OnClick] attrib
  val a_onmousedown : Xml.mouse_event_handler -> [>`OnMouseDown] attrib
  val a_onmouseup : Xml.mouse_event_handler -> [>`OnMouseUp] attrib
  val a_onmouseover : Xml.mouse_event_handler -> [>`OnMouseOver] attrib
  val a_onmouseout : Xml.mouse_event_handler -> [>`OnMouseOut] attrib
  val a_onmousemove : Xml.mouse_event_handler -> [>`OnMouseMove] attrib
  val a_ontouchstart : Xml.touch_event_handler -> [>`OnTouchStart] attrib
  val a_ontouchend : Xml.touch_event_handler -> [>`OnTouchEnd] attrib
  val a_ontouchmove : Xml.touch_event_handler -> [>`OnTouchMove] attrib
  val a_ontouchcancel : Xml.touch_event_handler -> [>`OnTouchCancel] attrib
  val txt : uri Lwd.t -> [>txt] elt
  val svg : ([<svg_attr], [<svg_content], [>svg]) star
  val g : ([<g_attr], [<g_content], [>g]) star
  val defs : ([<defs_attr], [<defs_content], [>defs]) star
  val desc : ([<desc_attr], [<desc_content], [>desc]) unary
  val title : ([<desc_attr], [<title_content], [>title]) unary
  val symbol : ([<symbol_attr], [<symbol_content], [>symbol]) star
  val use : ([<use_attr], [<use_content], [>use]) star
  val image : ([<image_attr], [<image_content], [>image]) star
  val switch : ([<switch_attr], [<switch_content], [>switch]) star
  val style : ([<style_attr], [<style_content], [>style]) unary
  val path : ([<path_attr], [<path_content], [>path]) star
  val rect : ([<rect_attr], [<rect_content], [>rect]) star
  val circle : ([<circle_attr], [<circle_content], [>circle]) star
  val ellipse : ([<ellipse_attr], [<ellipse_content], [>ellipse]) star
  val line : ([<line_attr], [<line_content], [>line]) star
  val polyline : ([<polyline_attr], [<polyline_content], [>polyline]) star
  val polygon : ([<polygon_attr], [<polygon_content], [>polygon]) star
  val text : ([<text_attr], [<text_content], [>text]) star
  val tspan : ([<tspan_attr], [<tspan_content], [>tspan]) star
  val textPath : ([<textpath_attr], [<textpath_content], [>textpath]) star
  val marker : ([<marker_attr], [<marker_content], [>marker]) star
  val linearGradient :
    ([<lineargradient_attr], [<lineargradient_content], [>lineargradient]) star
  val radialGradient :
    ([<radialgradient_attr], [<radialgradient_content], [>radialgradient]) star
  val stop : ([<stop_attr], [<stop_content], [>stop]) star
  val pattern : ([<pattern_attr], [<pattern_content], [>pattern]) star
  val clipPath : ([<clippath_attr], [<clippath_content], [>clippath]) star
  val filter : ([<filter_attr], [<filter_content], [>filter]) star
  val feDistantLight :
    ([<fedistantlight_attr], [<fedistantlight_content], [>fedistantlight]) star
  val fePointLight :
    ([<fepointlight_attr], [<fepointlight_content], [>fepointlight]) star
  val feSpotLight :
    ([<fespotlight_attr], [<fespotlight_content], [>fespotlight]) star
  val feBlend : ([<feblend_attr], [<feblend_content], [>feblend]) star
  val feColorMatrix :
    ([<fecolormatrix_attr], [<fecolormatrix_content], [>fecolormatrix]) star
  val feComponentTransfer :
    ([<fecomponenttransfer_attr], [<fecomponenttransfer_content],
     [>fecomponenttransfer]) star
  val feFuncA : ([<fefunca_attr], [<fefunca_content], [>fefunca]) star
  val feFuncG : ([<fefuncg_attr], [<fefuncg_content], [>fefuncg]) star
  val feFuncB : ([<fefuncb_attr], [<fefuncb_content], [>fefuncb]) star
  val feFuncR : ([<fefuncr_attr], [<fefuncr_content], [>fefuncr]) star
  val feComposite :
    ([<fecomposite_attr], [<fecomposite_content], [>fecomposite]) star
  val feConvolveMatrix :
    ([<feconvolvematrix_attr], [<feconvolvematrix_content],
     [>feconvolvematrix]) star
  val feDiffuseLighting :
    ([<fediffuselighting_attr], [<fediffuselighting_content],
     [>fediffuselighting]) star
  val feDisplacementMap :
    ([<fedisplacementmap_attr], [<fedisplacementmap_content],
     [>fedisplacementmap]) star
  val feFlood : ([<feflood_attr], [<feflood_content], [>feflood]) star
  val feGaussianBlur :
    ([<fegaussianblur_attr], [<fegaussianblur_content], [>fegaussianblur]) star
  val feImage : ([<feimage_attr], [<feimage_content], [>feimage]) star
  val feMerge : ([<femerge_attr], [<femerge_content], [>femerge]) star
  val feMorphology :
    ([<femorphology_attr], [<femorphology_content], [>femorphology]) star
  val feOffset :
    ([<feoffset_attr], [<feoffset_content], [>feoffset]) star
  val feSpecularLighting :
    ([<fespecularlighting_attr], [<fespecularlighting_content],
     [>fespecularlighting]) star
  val feTile : ([<fetile_attr], [<fetile_content], [>fetile]) star
  val feTurbulence :
    ([<feturbulence_attr], [<feturbulence_content], [>feturbulence]) star
  val cursor :
    ([<cursor_attr], [<descriptive_element], [>cursor]) star
  val a : ([<a_attr], [<a_content], [>a]) star
  val view : ([<view_attr], [<descriptive_element], [>view]) star
  val script : ([<script_attr], [<script_content], [>script]) unary
  val animate : ([<animate_attr], [<descriptive_element], [>animate]) star
  val animation :
    ([<animation_attr], [<descriptive_element], [>animation]) star
  [@@ocaml.warning "-3"]
  val set : ([<set_attr], [<descriptive_element], [>set]) star
  val animateMotion :
    ([<animatemotion_attr], [<animatemotion_content], [>animatemotion]) star
  val mpath :
    ([<mpath_attr], [<descriptive_element], [>mpath]) star
  val animateColor :
    ([<animatecolor_attr], [<descriptive_element], [>animatecolor]) star
  val animateTransform :
    ([<animatetransform_attr], [<descriptive_element],
     [>animatetransform]) star
  val metadata : ?a:metadata_attr attrib list -> Xml.elt list -> [>metadata] elt
  val foreignObject : ?a:foreignobject_attr attrib list -> Xml.elt list -> [>foreignobject] elt

  (* val pcdata : string Lwd.t -> [>txt] elt *)
  (* val of_seq : Xml_stream.signal Seq.t -> 'a elt list *)
  val tot : Xml.elt -> 'a elt
  (* val totl : Xml.elt list -> 'a elt list *)
  val toelt : 'a elt -> Xml.elt
  (* val toeltl : 'a elt list -> Xml.elt list *)
  val doc_toelt : doc -> Xml.elt
  val to_xmlattribs : 'a attrib list -> Xml.attrib list
  val to_attrib : Xml.attrib -> 'a attrib
end

open Html_types
module Html : sig
  type 'a elt = 'a node live
  type doc = html elt
  type +'a attrib
  type ('a, 'b) nullary = ?a:'a attrib list -> unit -> 'b elt
  type ('a, 'b, 'c) unary = ?a:'a attrib list -> 'b elt -> 'c elt
  type ('a, 'b, 'c) star = ?a:'a attrib list -> 'b elt list -> 'c elt
  module Info : Xml_sigs.Info

  val string_of_uri : Xml.uri -> string
  val uri_of_string : string -> Xml.uri
  val a_class : nmtokens Lwd.t -> [>`Class] attrib
  val a_user_data : string -> string Lwd.t -> [>`User_data] attrib
  val a_id : string Lwd.t -> [>`Id] attrib
  val a_title : string Lwd.t -> [>`Title] attrib
  val a_xml_lang : string Lwd.t -> [>`XML_lang] attrib
  val a_lang : string Lwd.t -> [>`Lang] attrib
  val a_onabort : Xml.event_handler -> [>`OnAbort] attrib
  val a_onafterprint : Xml.event_handler -> [>`OnAfterPrint] attrib
  val a_onbeforeprint : Xml.event_handler -> [>`OnBeforePrint] attrib
  val a_onbeforeunload : Xml.event_handler -> [>`OnBeforeUnload] attrib
  val a_onblur : Xml.event_handler -> [>`OnBlur] attrib
  val a_oncanplay : Xml.event_handler -> [>`OnCanPlay] attrib
  val a_oncanplaythrough : Xml.event_handler -> [>`OnCanPlayThrough] attrib
  val a_onchange : Xml.event_handler -> [>`OnChange] attrib
  val a_ondurationchange : Xml.event_handler -> [>`OnDurationChange] attrib
  val a_onemptied : Xml.event_handler -> [>`OnEmptied] attrib
  val a_onended : Xml.event_handler -> [>`OnEnded] attrib
  val a_onerror : Xml.event_handler -> [>`OnError] attrib
  val a_onfocus : Xml.event_handler -> [>`OnFocus] attrib
  val a_onformchange : Xml.event_handler -> [>`OnFormChange] attrib
  val a_onforminput : Xml.event_handler -> [>`OnFormInput] attrib
  val a_onhashchange : Xml.event_handler -> [>`OnHashChange] attrib
  val a_oninput : Xml.event_handler -> [>`OnInput] attrib
  val a_oninvalid : Xml.event_handler -> [>`OnInvalid] attrib
  val a_onmousewheel : Xml.event_handler -> [>`OnMouseWheel] attrib
  val a_onoffline : Xml.event_handler -> [>`OnOffLine] attrib
  val a_ononline : Xml.event_handler -> [>`OnOnLine] attrib
  val a_onpause : Xml.event_handler -> [>`OnPause] attrib
  val a_onplay : Xml.event_handler -> [>`OnPlay] attrib
  val a_onplaying : Xml.event_handler -> [>`OnPlaying] attrib
  val a_onpagehide : Xml.event_handler -> [>`OnPageHide] attrib
  val a_onpageshow : Xml.event_handler -> [>`OnPageShow] attrib
  val a_onpopstate : Xml.event_handler -> [>`OnPopState] attrib
  val a_onprogress : Xml.event_handler -> [>`OnProgress] attrib
  val a_onratechange : Xml.event_handler -> [>`OnRateChange] attrib
  val a_onreadystatechange : Xml.event_handler -> [>`OnReadyStateChange] attrib
  val a_onredo : Xml.event_handler -> [>`OnRedo] attrib
  val a_onresize : Xml.event_handler -> [>`OnResize] attrib
  val a_onscroll : Xml.event_handler -> [>`OnScroll] attrib
  val a_onseeked : Xml.event_handler -> [>`OnSeeked] attrib
  val a_onseeking : Xml.event_handler -> [>`OnSeeking] attrib
  val a_onselect : Xml.event_handler -> [>`OnSelect] attrib
  val a_onshow : Xml.event_handler -> [>`OnShow] attrib
  val a_onstalled : Xml.event_handler -> [>`OnStalled] attrib
  val a_onstorage : Xml.event_handler -> [>`OnStorage] attrib
  val a_onsubmit : Xml.event_handler -> [>`OnSubmit] attrib
  val a_onsuspend : Xml.event_handler -> [>`OnSuspend] attrib
  val a_ontimeupdate : Xml.event_handler -> [>`OnTimeUpdate] attrib
  val a_onundo : Xml.event_handler -> [>`OnUndo] attrib
  val a_onunload : Xml.event_handler -> [>`OnUnload] attrib
  val a_onvolumechange : Xml.event_handler -> [>`OnVolumeChange] attrib
  val a_onwaiting : Xml.event_handler -> [>`OnWaiting] attrib
  val a_onload : Xml.event_handler -> [>`OnLoad] attrib
  val a_onloadeddata : Xml.event_handler -> [>`OnLoadedData] attrib
  val a_onloadedmetadata : Xml.event_handler -> [>`OnLoadedMetaData] attrib
  val a_onloadstart : Xml.event_handler -> [>`OnLoadStart] attrib
  val a_onmessage : Xml.event_handler -> [>`OnMessage] attrib
  val a_onclick : Xml.mouse_event_handler -> [>`OnClick] attrib
  val a_oncontextmenu : Xml.mouse_event_handler -> [>`OnContextMenu] attrib
  val a_ondblclick : Xml.mouse_event_handler -> [>`OnDblClick] attrib
  val a_ondrag : Xml.mouse_event_handler -> [>`OnDrag] attrib
  val a_ondragend : Xml.mouse_event_handler -> [>`OnDragEnd] attrib
  val a_ondragenter : Xml.mouse_event_handler -> [>`OnDragEnter] attrib
  val a_ondragleave : Xml.mouse_event_handler -> [>`OnDragLeave] attrib
  val a_ondragover : Xml.mouse_event_handler -> [>`OnDragOver] attrib
  val a_ondragstart : Xml.mouse_event_handler -> [>`OnDragStart] attrib
  val a_ondrop : Xml.mouse_event_handler -> [>`OnDrop] attrib
  val a_onmousedown : Xml.mouse_event_handler -> [>`OnMouseDown] attrib
  val a_onmouseup : Xml.mouse_event_handler -> [>`OnMouseUp] attrib
  val a_onmouseover : Xml.mouse_event_handler -> [>`OnMouseOver] attrib
  val a_onmousemove : Xml.mouse_event_handler -> [>`OnMouseMove] attrib
  val a_onmouseout : Xml.mouse_event_handler -> [>`OnMouseOut] attrib
  val a_ontouchstart : Xml.touch_event_handler -> [>`OnTouchStart] attrib
  val a_ontouchend : Xml.touch_event_handler -> [>`OnTouchEnd] attrib
  val a_ontouchmove : Xml.touch_event_handler -> [>`OnTouchMove] attrib
  val a_ontouchcancel : Xml.touch_event_handler -> [>`OnTouchCancel] attrib
  val a_onkeypress : Xml.keyboard_event_handler -> [>`OnKeyPress] attrib
  val a_onkeydown : Xml.keyboard_event_handler -> [>`OnKeyDown] attrib
  val a_onkeyup : Xml.keyboard_event_handler -> [>`OnKeyUp] attrib
  val a_allowfullscreen : unit -> [>`Allowfullscreen] attrib
  val a_allowpaymentrequest : unit -> [>`Allowpaymentrequest] attrib
  val a_autocomplete : autocomplete_option Lwd.t -> [>`Autocomplete] attrib
  val a_async : unit -> [>`Async] attrib
  val a_autofocus : unit -> [>`Autofocus] attrib
  val a_autoplay : unit -> [>`Autoplay] attrib
  val a_muted : unit -> [>`Muted] attrib
  val a_crossorigin :
    [<`Anonymous|`Use_credentials] Lwd.t -> [>`Crossorigin] attrib
  val a_integrity : string Lwd.t -> [>`Integrity] attrib
  val a_mediagroup : string Lwd.t -> [>`Mediagroup] attrib
  val a_challenge : string Lwd.t -> [>`Challenge] attrib
  val a_contenteditable : bool Lwd.t -> [>`Contenteditable] attrib
  val a_contextmenu : string Lwd.t -> [>`Contextmenu] attrib
  val a_controls : unit -> [>`Controls] attrib
  val a_dir : [<`Ltr|`Rtl] Lwd.t -> [>`Dir] attrib
  val a_draggable : bool Lwd.t -> [>`Draggable] attrib
  val a_form : string Lwd.t -> [>`Form] attrib
  val a_formaction : Xml.uri Lwd.t -> [>`Formaction] attrib
  val a_formenctype : string Lwd.t -> [>`Formenctype] attrib
  val a_formnovalidate : unit -> [>`Formnovalidate] attrib
  val a_formtarget : string Lwd.t -> [>`Formtarget] attrib
  val a_hidden : unit -> [>`Hidden] attrib
  val a_high : float Lwd.t -> [>`High] attrib
  val a_icon : Xml.uri Lwd.t -> [>`Icon] attrib
  val a_ismap : unit -> [>`Ismap] attrib
  val a_keytype : string Lwd.t -> [>`Keytype] attrib
  val a_list : string Lwd.t -> [>`List] attrib
  val a_loop : unit -> [>`Loop] attrib
  val a_low : float Lwd.t -> [>`High] attrib
  val a_max : float Lwd.t -> [>`Max] attrib
  val a_input_max : number_or_datetime Lwd.t -> [>`Input_Max] attrib
  val a_min : float Lwd.t -> [>`Min] attrib
  val a_input_min : number_or_datetime Lwd.t -> [>`Input_Min] attrib
  val a_inputmode :
    [<`Decimal|`Email|`None|`Numeric|`Search|`Tel|`Text|`Url] Lwd.t ->
    [>`Inputmode] attrib
  val a_novalidate : unit -> [>`Novalidate] attrib
  val a_open : unit -> [>`Open] attrib
  val a_optimum : float Lwd.t -> [>`Optimum] attrib
  val a_pattern : string Lwd.t -> [>`Pattern] attrib
  val a_placeholder : string Lwd.t -> [>`Placeholder] attrib
  val a_poster : Xml.uri Lwd.t -> [>`Poster] attrib
  val a_preload : [<`Audio|`Metadata|`None] Lwd.t -> [>`Preload] attrib
  val a_pubdate : unit -> [>`Pubdate] attrib
  val a_radiogroup : string Lwd.t -> [>`Radiogroup] attrib
  val a_referrerpolicy : referrerpolicy Lwd.t -> [>`Referrerpolicy] attrib
  val a_required : unit -> [>`Required] attrib
  val a_reversed : unit -> [>`Reversed] attrib
  val a_sandbox : [<sandbox_token] list Lwd.t -> [>`Sandbox] attrib
  val a_spellcheck : bool Lwd.t -> [>`Spellcheck] attrib
  val a_scoped : unit -> [>`Scoped] attrib
  val a_seamless : unit -> [>`Seamless] attrib
  val a_sizes : (int * int) list option Lwd.t -> [>`Sizes] attrib
  val a_span : int Lwd.t -> [>`Span] attrib

  type image_candidate = [
    | `Url of Xml.uri
    | `Url_pixel of Xml.uri * float
    | `Url_width of Xml.uri * int
  ]
  val a_srcset : image_candidate list Lwd.t -> [>`Srcset] attrib
  val a_img_sizes : string list Lwd.t -> [>`Img_sizes] attrib
  val a_start : int Lwd.t -> [>`Start] attrib
  val a_step : float option Lwd.t -> [>`Step] attrib
  val a_wrap : [<`Hard | `Soft] Lwd.t -> [>`Wrap] attrib
  val a_version : string Lwd.t -> [>`Version] attrib
  val a_xmlns : [<`W3_org_1999_xhtml] Lwd.t -> [>`XMLns] attrib
  val a_manifest : Xml.uri Lwd.t -> [>`Manifest] attrib
  val a_cite : Xml.uri Lwd.t -> [>`Cite] attrib
  val a_xml_space : [<`Default | `Preserve] Lwd.t -> [>`XML_space] attrib
  val a_accesskey : char Lwd.t -> [>`Accesskey] attrib
  val a_charset : string Lwd.t -> [>`Charset] attrib
  val a_accept_charset : charsets Lwd.t -> [>`Accept_charset] attrib
  val a_accept : contenttypes Lwd.t -> [>`Accept] attrib
  val a_href : Xml.uri Lwd.t -> [>`Href] attrib
  val a_hreflang : string Lwd.t -> [>`Hreflang] attrib
  val a_download : string option Lwd.t -> [>`Download] attrib
  val a_rel : linktypes Lwd.t -> [>`Rel] attrib
  val a_tabindex : int Lwd.t -> [>`Tabindex] attrib
  val a_mime_type : string Lwd.t -> [>`Mime_type] attrib
  val a_datetime : string Lwd.t -> [>`Datetime] attrib
  val a_action : Xml.uri Lwd.t -> [>`Action] attrib
  val a_checked : unit -> [>`Checked] attrib
  val a_cols : int Lwd.t -> [>`Cols] attrib
  val a_enctype : string Lwd.t -> [>`Enctype] attrib
  val a_label_for : string Lwd.t -> [>`Label_for] attrib
  val a_output_for : idrefs Lwd.t -> [>`Output_for] attrib
  val a_maxlength : int Lwd.t -> [>`Maxlength] attrib
  val a_minlength : int Lwd.t -> [>`Minlength] attrib
  val a_method : [<`Get | `Post] Lwd.t -> [>`Method] attrib
  val a_multiple : unit -> [>`Multiple] attrib
  val a_name : string Lwd.t -> [>`Name] attrib
  val a_rows : int Lwd.t -> [>`Rows] attrib
  val a_selected : unit -> [>`Selected] attrib
  val a_size : int Lwd.t -> [>`Size] attrib
  val a_src : Xml.uri Lwd.t -> [>`Src] attrib
  val a_input_type :
    [<`Button|`Checkbox|`Color|`Date|`Datetime|`Datetime_local|`Email|`File
    |`Hidden|`Image|`Month|`Number|`Password|`Radio|`Range|`Reset|`Search
    |`Submit|`Tel|`Text|`Time|`Url|`Week] Lwd.t ->
    [>`Input_Type] attrib
  val a_text_value : string Lwd.t -> [>`Text_Value] attrib
  val a_int_value : int Lwd.t -> [>`Int_Value] attrib
  val a_value : string Lwd.t -> [>`Value] attrib
  val a_float_value : float Lwd.t -> [>`Float_Value] attrib
  val a_disabled : unit -> [>`Disabled] attrib
  val a_readonly : unit -> [>`ReadOnly] attrib
  val a_button_type : [<`Button|`Reset|`Submit] Lwd.t -> [>`Button_Type] attrib
  val a_command_type : [<`Checkbox|`Command|`Radio] Lwd.t -> [>`Command_Type] attrib
  val a_menu_type : [<`Context|`Toolbar] Lwd.t -> [>`Menu_Type] attrib
  val a_label : string Lwd.t -> [>`Label] attrib
  val a_colspan : int Lwd.t -> [>`Colspan] attrib
  val a_headers : idrefs Lwd.t -> [>`Headers] attrib
  val a_rowspan : int Lwd.t -> [>`Rowspan] attrib
  val a_alt : string Lwd.t -> [>`Alt] attrib
  val a_height : int Lwd.t -> [>`Height] attrib
  val a_width : int Lwd.t -> [>`Width] attrib

  type shape = [ `Circle | `Default | `Poly | `Rect]
  val a_shape : shape Lwd.t -> [>`Shape] attrib
  val a_coords : numbers Lwd.t -> [>`Coords] attrib
  val a_usemap : string Lwd.t -> [>`Usemap] attrib
  val a_data : Xml.uri Lwd.t -> [>`Data] attrib
  val a_scrolling : [<`Auto | `No | `Yes] Lwd.t -> [>`Scrolling] attrib
  val a_target : string Lwd.t -> [>`Target] attrib
  val a_content : string Lwd.t -> [>`Content] attrib
  val a_http_equiv : string Lwd.t -> [>`Http_equiv] attrib
  val a_defer : unit -> [>`Defer] attrib
  val a_media : mediadesc Lwd.t -> [>`Media] attrib
  val a_style : string Lwd.t -> [>`Style_Attr] attrib
  val a_property : string Lwd.t -> [>`Property] attrib
  val a_role : string list Lwd.t -> [>`Role] attrib
  val a_aria : string -> string list Lwd.t -> [>`Aria] attrib
  val txt : string Lwd.t -> [>txt] elt
  val html : ?a:html_attrib attrib list -> [<head] elt ->
    [<body] elt -> [>html] elt
  val head : ?a:head_attrib attrib list -> [<title] elt ->
    head_content_fun elt list -> [>head] elt
  val base : ([<base_attrib], [>base]) nullary
  val title : (noattrib, [<title_content_fun], [>title]) unary
  val body : ([<body_attrib], [<flow5], [>body]) star
  val svg : ?a:[<svg_attr] Svg.attrib list ->
    [<svg_content] Svg.elt list -> [>svg] elt
  val footer : ([<footer_attrib], [<footer_content_fun], [>footer]) star
  val header : ([<header_attrib], [<header_content_fun], [>header]) star
  val section : ([<section_attrib], [<section_content_fun], [>section]) star
  val nav : ([<nav_attrib], [<nav_content_fun], [>nav]) star
  val h1 : ([<h1_attrib], [<h1_content_fun], [>h1]) star
  val h2 : ([<h2_attrib], [<h2_content_fun], [>h2]) star
  val h3 : ([<h3_attrib], [<h3_content_fun], [>h3]) star
  val h4 : ([<h4_attrib], [<h4_content_fun], [>h4]) star
  val h5 : ([<h5_attrib], [<h5_content_fun], [>h5]) star
  val h6 : ([<h6_attrib], [<h6_content_fun], [>h6]) star
  val hgroup : ([<hgroup_attrib], [<hgroup_content_fun], [>hgroup]) star
  val address : ([<address_attrib], [<address_content_fun], [>address]) star
  val article : ([<article_attrib], [<article_content_fun], [>article]) star
  val aside : ([<aside_attrib], [<aside_content_fun], [>aside]) star
  val main : ([<main_attrib], [<main_content_fun], [>main]) star
  val p : ([<p_attrib], [<p_content_fun], [>p]) star
  val pre : ([<pre_attrib], [<pre_content_fun], [>pre]) star
  val blockquote :
    ([<blockquote_attrib], [<blockquote_content_fun], [>blockquote]) star
  val div : ([<div_attrib], [<div_content_fun], [>div]) star
  val dl : ([<dl_attrib], [<dl_content_fun], [>dl]) star
  val ol : ([<ol_attrib], [<ol_content_fun], [>ol]) star
  val ul : ([<ul_attrib], [<ul_content_fun], [>ul]) star
  val dd : ([<dd_attrib], [<dd_content_fun], [>dd]) star
  val dt : ([<dt_attrib], [<dt_content_fun], [>dt]) star
  val li : ([<li_attrib], [<li_content_fun], [>li]) star
  val figcaption :
    ([<figcaption_attrib], [<figcaption_content_fun], [>figcaption]) star
  val figure :
    ?figcaption:[`Bottom of [<figcaption] elt |`Top of [<figcaption] elt] ->
    ([<figure_attrib], [<figure_content_fun], [>figure]) star
  val hr : ([<hr_attrib], [>hr]) nullary
  val b : ([<b_attrib], [<b_content_fun], [>b]) star
  val i : ([<i_attrib], [<i_content_fun], [>i]) star
  val u : ([<u_attrib], [<u_content_fun], [>u]) star
  val small : ([<small_attrib], [<small_content_fun], [>small]) star
  val sub : ([<sub_attrib], [<sub_content_fun], [>sub]) star
  val sup : ([<sup_attrib], [<sup_content_fun], [>sup]) star
  val mark : ([<mark_attrib], [<mark_content_fun], [>mark]) star
  val wbr : ([<wbr_attrib], [>wbr]) nullary
  val bdo : dir:[<`Ltr | `Rtl] Lwd.t ->
    ([<bdo_attrib], [<bdo_content_fun], [>bdo]) star
  val abbr : ([<abbr_attrib], [<abbr_content_fun], [>abbr]) star
  val br : ([<br_attrib], [>br]) nullary
  val cite : ([<cite_attrib], [<cite_content_fun], [>cite]) star
  val code : ([<code_attrib], [<code_content_fun], [>code]) star
  val dfn : ([<dfn_attrib], [<dfn_content_fun], [>dfn]) star
  val em : ([<em_attrib], [<em_content_fun], [>em]) star
  val kbd : ([<kbd_attrib], [<kbd_content_fun], [>kbd]) star
  val q : ([<q_attrib], [<q_content_fun], [>q]) star
  val samp : ([<samp_attrib], [<samp_content_fun], [>samp]) star
  val span : ([<span_attrib], [<span_content_fun], [>span]) star
  val strong : ([<strong_attrib], [<strong_content_fun], [>strong]) star
  val time : ([<time_attrib], [<time_content_fun], [>time]) star
  val var : ([<var_attrib], [<var_content_fun], [>var]) star
  val a : ([<a_attrib], 'a, [>'a a]) star
  val del : ([<del_attrib], 'a, [>'a del]) star
  val ins : ([<ins_attrib], 'a, [>'a ins]) star
  val img : src:Xml.uri Lwd.t -> alt:string Lwd.t ->
    ([<img_attrib], [>img]) nullary
  val iframe : ([<iframe_attrib], [<iframe_content_fun], [>iframe]) star
  val object_ : ?params:[<param] elt list ->
    ([<object__attrib], 'a, [>`Object of 'a]) star
  val param : ([<param_attrib], [>param]) nullary
  val embed : ([<embed_attrib], [>embed]) nullary
  val audio : ?src:Xml.uri Lwd.t -> ?srcs:[<source] elt list ->
    ([<audio_attrib], 'a, [>'a audio]) star
  val video : ?src:Xml.uri Lwd.t -> ?srcs:[<source] elt list ->
    ([<video_attrib], 'a, [>'a video]) star
  val canvas : ([<canvas_attrib], 'a, [>'a canvas]) star
  val source : ([<source_attrib], [>source]) nullary
  val area : alt:string Lwd.t ->
    ([<`Accesskey|`Alt|`Aria|`Class|`Contenteditable|`Contextmenu|`Coords
     |`Dir|`Draggable|`Hidden|`Hreflang|`Id|`Lang |`Media|`Mime_type
     |`OnAbort|`OnBlur|`OnCanPlay|`OnCanPlayThrough|`OnChange|`OnClick
     |`OnContextMenu|`OnDblClick|`OnDrag|`OnDragEnd|`OnDragEnter
     |`OnDragLeave|`OnDragOver|`OnDragStart|`OnDrop|`OnDurationChange
     |`OnEmptied|`OnEnded|`OnError|`OnFocus|`OnFormChange|`OnFormInput
     |`OnInput|`OnInvalid|`OnKeyDown|`OnKeyPress|`OnKeyUp|`OnLoad
     |`OnLoadStart|`OnLoadedData|`OnLoadedMetaData|`OnMouseDown
     |`OnMouseMove|`OnMouseOut|`OnMouseOver|`OnMouseUp|`OnMouseWheel
     |`OnPause|`OnPlay|`OnPlaying|`OnProgress|`OnRateChange
     |`OnReadyStateChange|`OnScroll|`OnSeeked|`OnSeeking|`OnSelect
     |`OnShow|`OnStalled|`OnSubmit|`OnSuspend|`OnTimeUpdate|`OnTouchCancel
     |`OnTouchEnd|`OnTouchMove|`OnTouchStart|`OnVolumeChange|`OnWaiting
     |`Rel|`Role|`Shape|`Spellcheck|`Style_Attr|`Tabindex|`Target
     |`Title|`User_data|`XML_lang|`XMLns], [>area]) nullary
  val map : ([<map_attrib], 'a, [>'a map]) star
  val caption : ([<caption_attrib], [<caption_content_fun], [>caption]) star
  val table :
    ?caption:[<caption] elt -> ?columns:[<colgroup] elt list ->
    ?thead:[<thead] elt -> ?tfoot:[<tfoot] elt ->
    ([<table_attrib], [<table_content_fun], [>table]) star
  val tablex :
    ?caption:[<caption] elt -> ?columns:[<colgroup] elt list ->
    ?thead:[<thead] elt -> ?tfoot:[<tfoot] elt ->
    ([<tablex_attrib], [<tablex_content_fun], [>tablex]) star
  val colgroup :
    ([<colgroup_attrib], [<colgroup_content_fun], [>colgroup]) star
  val col : ([<col_attrib], [>col]) nullary
  val thead : ([<thead_attrib], [<thead_content_fun], [>thead]) star
  val tbody : ([<tbody_attrib], [<tbody_content_fun], [>tbody]) star
  val tfoot : ([<tfoot_attrib], [<tfoot_content_fun], [>tfoot]) star
  val td : ([<td_attrib], [<td_content_fun], [>td]) star
  val th : ([<th_attrib], [<th_content_fun], [>th]) star
  val tr : ([<tr_attrib], [<tr_content_fun], [>tr]) star
  val form : ([<form_attrib], [<form_content_fun], [>form]) star
  val fieldset : ?legend:[<legend] elt ->
    ([<fieldset_attrib], [<fieldset_content_fun], [>fieldset]) star
  val legend : ([<legend_attrib], [<legend_content_fun], [>legend]) star
  val label : ([<label_attrib], [<label_content_fun], [>label]) star
  val input : ([<input_attrib], [>input]) nullary
  val button : ([<button_attrib], [<button_content_fun], [>button]) star
  val select : ([<select_attrib], [<select_content_fun], [>select]) star
  val datalist : ?children:[<`Options of [<selectoption] elt list
                           | `Phras of [<phrasing] elt list] ->
    ([<datalist_attrib], [>datalist]) nullary
  val optgroup : label:string Lwd.t ->
    ([<optgroup_attrib], [<optgroup_content_fun], [>optgroup]) star
  val option :
    ([<option_attrib], [<option_content_fun], [>selectoption]) unary
  val textarea : ?a:[<textarea_attrib] attrib list -> string Lwd.t -> [>textarea] elt
  (* Textarea syntactically looks like it takes its content from its children
     nodes, but dynamic semantics use the value attribute :-( *)
  val keygen :
    ([<keygen_attrib], [>keygen]) nullary
  val progress :
    ([<progress_attrib], [<progress_content_fun], [>progress]) star
  val meter :
    ([<meter_attrib], [<meter_content_fun], [>meter]) star
  val output_elt :
    ([<output_elt_attrib], [<output_elt_content_fun], [>output_elt]) star
  val entity : string -> [>txt] elt
  val space : unit -> [>txt] elt
  val cdata : string -> [>txt] elt
  val cdata_script : string -> [>txt] elt
  val cdata_style : string -> [>txt] elt
  val details : [<summary] elt ->
    ([<details_attrib], [<details_content_fun], [>details]) star
  val summary : ([<summary_attrib], [<summary_content_fun], [>summary]) star
  val command : label:string Lwd.t -> ([<command_attrib], [>command]) nullary
  val menu : ?children:[<`Flows of [<flow5] elt list
                       | `Lis of [<`Li of [<common]] elt list] ->
    ([<menu_attrib], [>menu]) nullary
  val script :
    ([<script_attrib], [<script_content_fun], [>script]) unary
  val noscript :
    ([<noscript_attrib], [<flow5_without_noscript], [>noscript]) star
  val template :
    ([<template_attrib], [<template_content_fun], [>template]) star
  val meta : ([<meta_attrib], [>meta]) nullary
  val style : ([<style_attrib], [<style_content_fun], [>style]) star
  val link : rel:linktypes Lwd.t -> href:Xml.uri Lwd.t ->
    ([<link_attrib], [>link]) nullary
  val rt : ([<rt_attrib], [<rt_content_fun], [>rt]) star
  val rp : ([<rp_attrib], [<rp_content_fun], [>rp]) star
  val ruby : ([<ruby_attrib], [<ruby_content_fun], [>ruby]) star

  (* val pcdata : string Lwd.t -> [>pcdata] elt *)
  (* val of_seq : Xml_stream.signal Seq.t -> 'a elt list *)
  val tot : Xml.elt -> 'a elt
  (* val totl : Xml.elt list -> 'a elt list *)
  val toelt : 'a elt -> Xml.elt
  (* val toeltl : 'a elt list -> Xml.elt list *)
  val doc_toelt : doc -> Xml.elt
  val to_xmlattribs : 'a attrib list -> Xml.attrib list
  val to_attrib : Xml.attrib -> 'a attrib
end

(** {1 Running an Lwd-driven DOM in the browser} *)

module Lwdom : sig
  type 'a elt = 'a Lwd_seq.t Lwd.t

  val elt : 'a -> 'a elt
  (** Create an element from a value *)

  val children : 'a elt list -> 'a elt
  (** Flatten a list of elements *)

  val children_array : 'a elt array -> 'a elt
  (** Flatten an array of elements *)

  val attr : 'a -> 'a attr
  (** Make a constant attribute *)

  val rattr : 'a Lwd.t -> 'a attr
  (** Make a reactive attribute *)

  val to_node : _ node -> raw_node
end

