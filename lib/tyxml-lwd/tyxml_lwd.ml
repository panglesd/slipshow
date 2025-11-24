open Js_of_ocaml

type raw_node = Dom.node Js.t
type 'a live = 'a Lwd_seq.t Lwd.t
type 'a attr = 'a option Lwd.t

let some x = Some x
let empty = Lwd.pure Lwd_seq.empty

module W : Xml_wrap.T
  with type 'a t = 'a Lwd.t
  with type ('a, 'b) ft = 'a -> 'b
  with type 'a tlist = 'a Lwd.t list
=
struct
  type 'a t = 'a Lwd.t
  type (-'a, 'b) ft = 'a -> 'b
  type 'a tlist = 'a Lwd.t list

  let return = Lwd.pure
  let fmap f x = Lwd.map ~f x
  let nil () = []
  let singleton x = [x]
  let append = (@)
  let cons x xs = x :: xs
  let map f xs = List.map (fun x -> Lwd.map ~f x) xs
end

type child_tree =
  | Leaf of raw_node
  | Inner of { mutable bound: raw_node Js.opt;
               left: child_tree; right: child_tree; }

let child_node node = Leaf node

let child_join left right = Inner { bound = Js.null; left; right }

let js_lwd_to_remove =
  Js.string "lwd-to-remove" (* HACK Could be turned into a Javascript symbol *)

let contains_focus node =
  Js.to_bool (Js.Unsafe.meth_call (node : raw_node) "contains"
                [|Js.Unsafe.inject Dom_html.document##.activeElement|])

let update_children (self : raw_node) (children : raw_node live) : unit Lwd.t =
  let reducer =
    ref (Lwd_seq.Reducer.make ~map:child_node ~reduce:child_join)
  in
  Lwd.map children ~f:begin fun children ->
    let dropped, reducer' =
      Lwd_seq.Reducer.update_and_get_dropped !reducer children in
    reducer := reducer';
    let schedule_for_removal child () = match child with
      | Leaf node -> Js.Unsafe.set node js_lwd_to_remove Js._true
      | Inner _ -> ()
    in
    Lwd_seq.Reducer.fold_dropped `Map schedule_for_removal dropped ();
    let preserve_focus = contains_focus self in
    begin match Lwd_seq.Reducer.reduce reducer' with
      | None -> ()
      | Some tree ->
        let rec update acc = function
          | Leaf x ->
            Js.Unsafe.delete x js_lwd_to_remove;
            if x##.parentNode != Js.some self then
              ignore (self##insertBefore x acc)
            else if x##.nextSibling != acc then begin
              (* Parent is correct but sibling is not: swap nodes, but be
                 cautious with focus *)
              if preserve_focus && contains_focus x then (
                let rec shift_siblings () =
                  let sibling = x##.nextSibling in
                  if sibling == acc then
                    true
                  else match Js.Opt.to_option sibling with
                    | None -> false
                    | Some sibling ->
                      ignore (self##insertBefore sibling (Js.some x));
                      shift_siblings ()
                in
                if not (shift_siblings ()) then
                  ignore (self##insertBefore x acc)
              )
              else
                ignore (self##insertBefore x acc)
            end;
            Js.some x
          | Inner t ->
            if Js.Opt.test t.bound then t.bound else (
              let acc = update acc t.right in
              let acc = update acc t.left in
              t.bound <- acc;
              acc
            )
        in
        ignore (update Js.null tree)
    end;
    let remove_child child () = match child with
      | Leaf node ->
        if Js.Opt.test (Js.Unsafe.get node js_lwd_to_remove) then
          ignore (self##removeChild node)
      | Inner _ -> ()
    in
    Lwd_seq.Reducer.fold_dropped `Map remove_child dropped ();
  end

let update_children_list self children =
  update_children self (Lwd.join (Lwd_utils.pack Lwd_seq.lwd_monoid children))

module Attrib = struct
  type t =
    | Event of
        { name: string; value: (Dom_html.event Js.t -> bool) attr }
    | Event_mouse of
        { name: string; value: (Dom_html.mouseEvent Js.t -> bool) attr }
    | Event_keyboard of
        { name: string; value: (Dom_html.keyboardEvent Js.t -> bool) attr }
    | Event_touch of
        { name: string; value: (Dom_html.touchEvent Js.t -> bool) attr }
    | Attrib of
        { name: string; value: Js.js_string Js.t attr }
end

module Xml :
sig
  include Xml_sigs.T
    with module W = W
     and type uri = string
     and type elt = raw_node live
     and type attrib = Attrib.t
     and type event_handler          = (Dom_html.event Js.t -> bool) attr
     and type mouse_event_handler    = (Dom_html.mouseEvent Js.t -> bool) attr
     and type keyboard_event_handler = (Dom_html.keyboardEvent Js.t -> bool) attr
     and type touch_event_handler    = (Dom_html.touchEvent Js.t -> bool) attr

end
= struct

  module W = W

  type elt = raw_node live
  type 'a wrap = 'a W.t
  type 'a list_wrap = 'a W.tlist

  type uri = string
  let uri_of_string s = s
  let string_of_uri s = s

  type aname = string

  type event_handler          = (Dom_html.event Js.t -> bool) attr
  type mouse_event_handler    = (Dom_html.mouseEvent Js.t -> bool) attr
  type keyboard_event_handler = (Dom_html.keyboardEvent Js.t -> bool) attr
  type touch_event_handler    = (Dom_html.touchEvent Js.t -> bool) attr

  type attrib = Attrib.t

  let attrib name value f = Attrib.Attrib {name; value = Lwd.map ~f value}

  let js_string_of_float f = (Js.number_of_float f)##toString
  let js_string_of_int i = (Js.number_of_float (float_of_int i))##toString

  let float_attrib n v = attrib n v
      (fun v -> Some (js_string_of_float v))
  let int_attrib n v = attrib n v
      (fun v -> Some (js_string_of_int v))
  let string_attrib n v = attrib n v
      (fun v -> Some (Js.string v))
  let space_sep_attrib n v = attrib n v
      (fun v -> Some (Js.string (String.concat " " v)))
  let comma_sep_attrib n v = attrib n v
      (fun v -> Some (Js.string (String.concat "," v)))

  let event_handler_attrib n v =
    Attrib.Event {name = n; value = v}

  let mouse_event_handler_attrib n v =
    Attrib.Event_mouse {name = n; value = v}

  let keyboard_event_handler_attrib n v =
    Attrib.Event_keyboard {name = n; value = v}

  let touch_event_handler_attrib n v =
    Attrib.Event_touch {name = n; value = v}

  let uri_attrib n v = attrib n v
      (fun v -> Some (Js.string v))

  let uris_attrib n v = attrib n v
      (fun v -> Some (Js.string (String.concat " " v)))

  let attach_attrib (node: #Dom.element Js.t) name value =
    let f = match name with
      | "style" -> (function
          | None -> node##.style##.cssText := Js.string ""
          | Some v -> node##.style##.cssText := v
        )
      | "value" -> (function
          | None -> (Obj.magic node : _ Js.t)##.value := Js.string ""
          | Some v -> (Obj.magic node : _ Js.t)##.value := v
        )
      | name -> let name = Js.string name in (function
          | None -> node##removeAttribute name
          | Some v -> node##setAttribute name v
        )
    in
    Lwd.map ~f value

  let attach_event (node: #Dom.element Js.t) name value =
    let name = Js.string name in
    Lwd.map ~f:(function
        | None -> Js.Unsafe.set node name Js.null
        | Some v -> Js.Unsafe.set node name (fun ev -> Js.bool (v ev))
      ) value

  (** Element *)

  type data = raw_node

  type ename = string

  let pure x = Lwd.pure (Lwd_seq.element x)
  let as_node (x : #Dom.node Js.t) = (x :> Dom.node Js.t)
  let pure_node x = pure (as_node x)

  let empty () = empty

  let comment c = pure_node (Dom_html.document##createComment (Js.string c))

  let pcdata (text : string Lwd.t) : elt =
    let node =
      Lwd_seq.element (Dom_html.document##createTextNode (Js.string ""))
    in
    Lwd.map text ~f:(fun text ->
        begin match Lwd_seq.view node with
          | Lwd_seq.Element elt -> elt##.data := Js.string text;
          | _ -> assert false
        end;
        (node : Dom.text Js.t Lwd_seq.t :> raw_node Lwd_seq.t)
      )

  let encodedpcdata = pcdata

  let entity =
    let string_fold s ~pos ~init ~f =
      let r = ref init in
      for i = pos to String.length s - 1 do
        let c = s.[i] in
        r := f !r c
      done;
      !r
    in
    let invalid_entity e = failwith (Printf.sprintf "Invalid entity %S" e) in
    let int_of_char = function
      | '0' .. '9' as x -> Some (Char.code x - Char.code '0')
      | 'a' .. 'f' as x -> Some (Char.code x - Char.code 'a' + 10)
      | 'A' .. 'F' as x -> Some (Char.code x - Char.code 'A' + 10)
      | _ -> None
    in
    let parse_int ~pos ~base e =
      string_fold e ~pos ~init:0 ~f:(fun acc x ->
          match int_of_char x with
          | Some d when d < base -> (acc * base) + d
          | Some _ | None -> invalid_entity e)
    in
    let is_alpha_num = function
      | '0' .. '9' | 'a' .. 'z' | 'A' .. 'Z' -> true
      | _ -> false
    in
    fun e ->
      let len = String.length e in
      let str =
        if len >= 1 && Char.equal e.[0] '#'
        then
          let i =
            if len >= 2 && (Char.equal e.[1] 'x' || Char.equal e.[1] 'X')
            then parse_int ~pos:2 ~base:16 e
            else parse_int ~pos:1 ~base:10 e
          in
          Js.string_constr##fromCharCode i
        else if string_fold e ~pos:0 ~init:true ~f:(fun acc x ->
                    (* This is not quite right according to
                       https://www.xml.com/axml/target.html#NT-Name.
                       but it seems to cover all html5 entities
                       https://dev.w3.org/html5/html-author/charref *)
                    acc && is_alpha_num x)
        then
          match e with
          | "quot" -> Js.string "\""
          | "amp" -> Js.string "&"
          | "apos" -> Js.string "'"
          | "lt" -> Js.string "<"
          | "gt" -> Js.string ">"
          | "" -> invalid_entity e
          | _ -> Dom_html.decode_html_entities (Js.string ("&" ^ e ^ ";"))
        else invalid_entity e
      in
      pure_node (Dom_html.document##createTextNode str)

  let attach_attribs node l =
    Lwd_utils.pack ((), fun () () -> ())
      (List.map (function
           | Attrib.Attrib  {name; value} -> attach_attrib node name value
           | Event          {name; value} -> attach_event node name value
           | Event_mouse    {name; value} -> attach_event node name value
           | Event_keyboard {name; value} -> attach_event node name value
           | Event_touch    {name; value} -> attach_event node name value
         ) l)

  let rec find_ns : attrib list -> Js.js_string Js.t option = function
    | [] -> None
    | Attrib {name = "xmlns"; value} :: _ ->
      begin
        (* The semantics should not differ whether an Lwd value is pure or not,
           but let's do an exception for xml namespaces (those are managed
           differently from other and can't be changed at runtime). *)
        match Lwd.is_pure value with
        | None ->
          prerr_endline "xmlns attribute should be static";
          None
        | Some x -> x
      end
    | _ :: rest -> find_ns rest

  let createElement ~ns name =
    let name = Js.string name in
    match ns with
    | None -> Dom_html.document##createElement name
    | Some ns -> Dom_html.document##createElementNS ns name

  let leaf ?(a = []) name : elt =
    let e = createElement ~ns:(find_ns a) name in
    let e' = Lwd_seq.element (e : Dom_html.element Js.t :> data) in
    Lwd.map (attach_attribs e a) ~f:(fun () -> e')

  let node ?(a = []) name (children : elt list_wrap) : elt =
    let e = createElement ~ns:(find_ns a) name in
    let e' = Lwd_seq.element e in
    Lwd.map2
      (update_children_list (e :> data) children)
      (attach_attribs e a)
      ~f:(fun () () -> (e' :> data Lwd_seq.t))

  let cdata s = pure_node (Dom_html.document##createTextNode (Js.string s))

  let cdata_script s = cdata s

  let cdata_style s = cdata s
end

type +'a node = raw_node
type +'a attrib = Xml.attrib

module Raw_svg = Svg_f.Make(struct
    include Xml

    let svg_xmlns = Attrib.Attrib {
        name = "xmlns";
        value = Lwd.pure (Some (Js.string "http://www.w3.org/2000/svg"));
      }

    let leaf ?(a = []) name =
      leaf ~a:(svg_xmlns :: a) name

    let node ?(a = []) name (children : elt list_wrap) =
      node ~a:(svg_xmlns :: a) name children
  end)

open Svg_types
module Svg : sig
  type +'a elt = 'a node live
  type doc = [`Svg] elt
  type nonrec +'a attrib = 'a attrib

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
  val animation : ([<animation_attr], [<descriptive_element], [>animation]) star
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

  (*module Unsafe : sig
    val data : string Lwd.t -> 'a elt
    val node : string -> ?a:'a attrib list -> 'b elt list -> 'c elt
    val leaf : string -> ?a:'a attrib list -> unit -> 'b elt
    val coerce_elt : 'a elt -> 'b elt
    val string_attrib : string -> string Lwd.t -> 'a attrib
    val float_attrib : string -> float Lwd.t -> 'a attrib
    val int_attrib : string -> int Lwd.t -> 'a attrib
    val uri_attrib : string -> Xml.uri Lwd.t -> 'a attrib
    val space_sep_attrib : string -> string list Lwd.t -> 'a attrib
    val comma_sep_attrib : string -> string list Lwd.t -> 'a attrib
  end*)
end = struct
  type +'a elt = 'a node live
  type doc = [`Svg] elt
  type nonrec +'a attrib = 'a attrib

  module Xml = Xml
  type ('a, 'b) nullary = ?a:'a attrib list -> unit -> 'b elt
  type ('a, 'b, 'c) unary = ?a:'a attrib list -> 'b elt -> 'c elt
  type ('a, 'b, 'c) star = ?a:'a attrib list -> 'b elt list -> 'c elt

  module Info = Raw_svg.Info

  type uri = string

  let string_of_uri                = Raw_svg.string_of_uri
  let uri_of_string                = Raw_svg.uri_of_string
  let a_x                          = Raw_svg.a_x
  let a_y                          = Raw_svg.a_y
  let a_width                      = Raw_svg.a_width
  let a_height                     = Raw_svg.a_height
  let a_preserveAspectRatio        = Raw_svg.a_preserveAspectRatio
  let a_zoomAndPan                 = Raw_svg.a_zoomAndPan
  let a_href                       = Raw_svg.a_href
  let a_requiredExtensions         = Raw_svg.a_requiredExtensions
  let a_systemLanguage             = Raw_svg.a_systemLanguage
  let a_externalRessourcesRequired = Raw_svg.a_externalRessourcesRequired
  let a_id                         = Raw_svg.a_id
  let a_user_data                  = Raw_svg.a_user_data
  let a_xml_lang                   = Raw_svg.a_xml_lang
  let a_type                       = Raw_svg.a_type
  let a_media                      = Raw_svg.a_media
  let a_class                      = Raw_svg.a_class
  let a_style                      = Raw_svg.a_style
  let a_transform                  = Raw_svg.a_transform
  let a_viewBox                    = Raw_svg.a_viewBox
  let a_d                          = Raw_svg.a_d
  let a_pathLength                 = Raw_svg.a_pathLength
  let a_rx                         = Raw_svg.a_rx
  let a_ry                         = Raw_svg.a_ry
  let a_cx                         = Raw_svg.a_cx
  let a_cy                         = Raw_svg.a_cy
  let a_r                          = Raw_svg.a_r
  let a_x1                         = Raw_svg.a_x1
  let a_y1                         = Raw_svg.a_y1
  let a_x2                         = Raw_svg.a_x2
  let a_y2                         = Raw_svg.a_y2
  let a_points                     = Raw_svg.a_points
  let a_x_list                     = Raw_svg.a_x_list
  let a_y_list                     = Raw_svg.a_y_list
  let a_dx                         = Raw_svg.a_dx
  let a_dy                         = Raw_svg.a_dy
  let a_dx_list                    = Raw_svg.a_dx_list
  let a_dy_list                    = Raw_svg.a_dy_list
  let a_lengthAdjust               = Raw_svg.a_lengthAdjust
  let a_textLength                 = Raw_svg.a_textLength
  let a_text_anchor                = Raw_svg.a_text_anchor
  let a_text_decoration            = Raw_svg.a_text_decoration
  let a_text_rendering             = Raw_svg.a_text_rendering
  let a_rotate                     = Raw_svg.a_rotate
  let a_startOffset                = Raw_svg.a_startOffset
  let a_method                     = Raw_svg.a_method
  let a_spacing                    = Raw_svg.a_spacing
  let a_glyphRef                   = Raw_svg.a_glyphRef
  let a_format                     = Raw_svg.a_format
  let a_markerUnits                = Raw_svg.a_markerUnits
  let a_refX                       = Raw_svg.a_refX
  let a_refY                       = Raw_svg.a_refY
  let a_markerWidth                = Raw_svg.a_markerWidth
  let a_markerHeight               = Raw_svg.a_markerHeight
  let a_orient                     = Raw_svg.a_orient
  let a_local                      = Raw_svg.a_local
  let a_rendering_intent           = Raw_svg.a_rendering_intent
  let a_gradientUnits              = Raw_svg.a_gradientUnits
  let a_gradientTransform          = Raw_svg.a_gradientTransform
  let a_spreadMethod               = Raw_svg.a_spreadMethod
  let a_fx                         = Raw_svg.a_fx
  let a_fy                         = Raw_svg.a_fy
  let a_offset                     = Raw_svg.a_offset
  let a_patternUnits               = Raw_svg.a_patternUnits
  let a_patternContentUnits        = Raw_svg.a_patternContentUnits
  let a_patternTransform           = Raw_svg.a_patternTransform
  let a_clipPathUnits              = Raw_svg.a_clipPathUnits
  let a_maskUnits                  = Raw_svg.a_maskUnits
  let a_maskContentUnits           = Raw_svg.a_maskContentUnits
  let a_primitiveUnits             = Raw_svg.a_primitiveUnits
  let a_filterRes                  = Raw_svg.a_filterRes
  let a_result                     = Raw_svg.a_result
  let a_in                         = Raw_svg.a_in
  let a_in2                        = Raw_svg.a_in2
  let a_azimuth                    = Raw_svg.a_azimuth
  let a_elevation                  = Raw_svg.a_elevation
  let a_pointsAtX                  = Raw_svg.a_pointsAtX
  let a_pointsAtY                  = Raw_svg.a_pointsAtY
  let a_pointsAtZ                  = Raw_svg.a_pointsAtZ
  let a_specularExponent           = Raw_svg.a_specularExponent
  let a_specularConstant           = Raw_svg.a_specularConstant
  let a_limitingConeAngle          = Raw_svg.a_limitingConeAngle
  let a_mode                       = Raw_svg.a_mode
  let a_feColorMatrix_type         = Raw_svg.a_feColorMatrix_type
  let a_values                     = Raw_svg.a_values
  let a_transfer_type              = Raw_svg.a_transfer_type
  let a_tableValues                = Raw_svg.a_tableValues
  let a_intercept                  = Raw_svg.a_intercept
  let a_amplitude                  = Raw_svg.a_amplitude
  let a_exponent                   = Raw_svg.a_exponent
  let a_transfer_offset            = Raw_svg.a_transfer_offset
  let a_feComposite_operator       = Raw_svg.a_feComposite_operator
  let a_k1                         = Raw_svg.a_k1
  let a_k2                         = Raw_svg.a_k2
  let a_k3                         = Raw_svg.a_k3
  let a_k4                         = Raw_svg.a_k4
  let a_order                      = Raw_svg.a_order
  let a_kernelMatrix               = Raw_svg.a_kernelMatrix
  let a_divisor                    = Raw_svg.a_divisor
  let a_bias                       = Raw_svg.a_bias
  let a_kernelUnitLength           = Raw_svg.a_kernelUnitLength
  let a_targetX                    = Raw_svg.a_targetX
  let a_targetY                    = Raw_svg.a_targetY
  let a_edgeMode                   = Raw_svg.a_edgeMode
  let a_preserveAlpha              = Raw_svg.a_preserveAlpha
  let a_surfaceScale               = Raw_svg.a_surfaceScale
  let a_diffuseConstant            = Raw_svg.a_diffuseConstant
  let a_scale                      = Raw_svg.a_scale
  let a_xChannelSelector           = Raw_svg.a_xChannelSelector
  let a_yChannelSelector           = Raw_svg.a_yChannelSelector
  let a_stdDeviation               = Raw_svg.a_stdDeviation
  let a_feMorphology_operator      = Raw_svg.a_feMorphology_operator
  let a_radius                     = Raw_svg.a_radius
  let a_baseFrenquency             = Raw_svg.a_baseFrenquency
  let a_numOctaves                 = Raw_svg.a_numOctaves
  let a_seed                       = Raw_svg.a_seed
  let a_stitchTiles                = Raw_svg.a_stitchTiles
  let a_feTurbulence_type          = Raw_svg.a_feTurbulence_type
  let a_target                     = Raw_svg.a_target
  let a_attributeName              = Raw_svg.a_attributeName
  let a_attributeType              = Raw_svg.a_attributeType
  let a_begin                      = Raw_svg.a_begin
  let a_dur                        = Raw_svg.a_dur
  let a_min                        = Raw_svg.a_min
  let a_max                        = Raw_svg.a_max
  let a_restart                    = Raw_svg.a_restart
  let a_repeatCount                = Raw_svg.a_repeatCount
  let a_repeatDur                  = Raw_svg.a_repeatDur
  let a_fill                       = Raw_svg.a_fill
  let a_animation_fill             = Raw_svg.a_animation_fill
  let a_calcMode                   = Raw_svg.a_calcMode
  let a_animation_values           = Raw_svg.a_animation_values
  let a_keyTimes                   = Raw_svg.a_keyTimes
  let a_keySplines                 = Raw_svg.a_keySplines
  let a_from                       = Raw_svg.a_from
  let a_to                         = Raw_svg.a_to
  let a_by                         = Raw_svg.a_by
  let a_additive                   = Raw_svg.a_additive
  let a_accumulate                 = Raw_svg.a_accumulate
  let a_keyPoints                  = Raw_svg.a_keyPoints
  let a_path                       = Raw_svg.a_path
  let a_animateTransform_type      = Raw_svg.a_animateTransform_type
  let a_horiz_origin_x             = Raw_svg.a_horiz_origin_x
  let a_horiz_origin_y             = Raw_svg.a_horiz_origin_y
  let a_horiz_adv_x                = Raw_svg.a_horiz_adv_x
  let a_vert_origin_x              = Raw_svg.a_vert_origin_x
  let a_vert_origin_y              = Raw_svg.a_vert_origin_y
  let a_vert_adv_y                 = Raw_svg.a_vert_adv_y
  let a_unicode                    = Raw_svg.a_unicode
  let a_glyph_name                 = Raw_svg.a_glyph_name
  let a_orientation                = Raw_svg.a_orientation
  let a_arabic_form                = Raw_svg.a_arabic_form
  let a_lang                       = Raw_svg.a_lang
  let a_u1                         = Raw_svg.a_u1
  let a_u2                         = Raw_svg.a_u2
  let a_g1                         = Raw_svg.a_g1
  let a_g2                         = Raw_svg.a_g2
  let a_k                          = Raw_svg.a_k
  let a_font_family                = Raw_svg.a_font_family
  let a_font_style                 = Raw_svg.a_font_style
  let a_font_variant               = Raw_svg.a_font_variant
  let a_font_weight                = Raw_svg.a_font_weight
  let a_font_stretch               = Raw_svg.a_font_stretch
  let a_font_size                  = Raw_svg.a_font_size
  let a_unicode_range              = Raw_svg.a_unicode_range
  let a_units_per_em               = Raw_svg.a_units_per_em
  let a_stemv                      = Raw_svg.a_stemv
  let a_stemh                      = Raw_svg.a_stemh
  let a_slope                      = Raw_svg.a_slope
  let a_cap_height                 = Raw_svg.a_cap_height
  let a_x_height                   = Raw_svg.a_x_height
  let a_accent_height              = Raw_svg.a_accent_height
  let a_ascent                     = Raw_svg.a_ascent
  let a_widths                     = Raw_svg.a_widths
  let a_bbox                       = Raw_svg.a_bbox
  let a_ideographic                = Raw_svg.a_ideographic
  let a_alphabetic                 = Raw_svg.a_alphabetic
  let a_mathematical               = Raw_svg.a_mathematical
  let a_hanging                    = Raw_svg.a_hanging
  let a_videographic               = Raw_svg.a_videographic
  let a_v_alphabetic               = Raw_svg.a_v_alphabetic
  let a_v_mathematical             = Raw_svg.a_v_mathematical
  let a_v_hanging                  = Raw_svg.a_v_hanging
  let a_underline_position         = Raw_svg.a_underline_position
  let a_underline_thickness        = Raw_svg.a_underline_thickness
  let a_strikethrough_position     = Raw_svg.a_strikethrough_position
  let a_strikethrough_thickness    = Raw_svg.a_strikethrough_thickness
  let a_overline_position          = Raw_svg.a_overline_position
  let a_overline_thickness         = Raw_svg.a_overline_thickness
  let a_string                     = Raw_svg.a_string
  let a_name                       = Raw_svg.a_name
  let a_alignment_baseline         = Raw_svg.a_alignment_baseline
  let a_dominant_baseline          = Raw_svg.a_dominant_baseline
  let a_stop_color                 = Raw_svg.a_stop_color
  let a_stop_opacity               = Raw_svg.a_stop_opacity
  let a_stroke                     = Raw_svg.a_stroke
  let a_stroke_width               = Raw_svg.a_stroke_width
  let a_stroke_linecap             = Raw_svg.a_stroke_linecap
  let a_stroke_linejoin            = Raw_svg.a_stroke_linejoin
  let a_stroke_miterlimit          = Raw_svg.a_stroke_miterlimit
  let a_stroke_dasharray           = Raw_svg.a_stroke_dasharray
  let a_stroke_dashoffset          = Raw_svg.a_stroke_dashoffset
  let a_stroke_opacity             = Raw_svg.a_stroke_opacity
  let a_onabort                    = Raw_svg.a_onabort
  let a_onactivate                 = Raw_svg.a_onactivate
  let a_onbegin                    = Raw_svg.a_onbegin
  let a_onend                      = Raw_svg.a_onend
  let a_onerror                    = Raw_svg.a_onerror
  let a_onfocusin                  = Raw_svg.a_onfocusin
  let a_onfocusout                 = Raw_svg.a_onfocusout
  let a_onrepeat                   = Raw_svg.a_onrepeat
  let a_onresize                   = Raw_svg.a_onresize
  let a_onscroll                   = Raw_svg.a_onscroll
  let a_onunload                   = Raw_svg.a_onunload
  let a_onzoom                     = Raw_svg.a_onzoom
  let a_onclick                    = Raw_svg.a_onclick
  let a_onmousedown                = Raw_svg.a_onmousedown
  let a_onmouseup                  = Raw_svg.a_onmouseup
  let a_onmouseover                = Raw_svg.a_onmouseover
  let a_onmouseout                 = Raw_svg.a_onmouseout
  let a_onmousemove                = Raw_svg.a_onmousemove
  let a_ontouchstart               = Raw_svg.a_ontouchstart
  let a_ontouchend                 = Raw_svg.a_ontouchend
  let a_ontouchmove                = Raw_svg.a_ontouchmove
  let a_ontouchcancel              = Raw_svg.a_ontouchcancel

  let unary (f: ('a, 'b, 'c) Raw_svg.unary) : ('a, 'b, 'c) unary =
    fun ?a elt -> f ?a (Lwd.pure elt)

  let star (f: ('a, 'b, 'c) Raw_svg.star) : ('a, 'b, 'c) star =
    fun ?a elts -> f ?a (List.map Lwd.pure elts)

  let txt                          = Raw_svg.txt
  let svg                          = star Raw_svg.svg
  let g                            = star Raw_svg.g
  let defs                         = star Raw_svg.defs
  let desc                         = unary Raw_svg.desc
  let title                        = unary Raw_svg.title
  let symbol                       = star Raw_svg.symbol
  let use                          = star Raw_svg.use
  let image                        = star Raw_svg.image
  let switch                       = star Raw_svg.switch
  let style                        = unary Raw_svg.style
  let path                         = star Raw_svg.path
  let rect                         = star Raw_svg.rect
  let circle                       = star Raw_svg.circle
  let ellipse                      = star Raw_svg.ellipse
  let line                         = star Raw_svg.line
  let polyline                     = star Raw_svg.polyline
  let polygon                      = star Raw_svg.polygon
  let text                         = star Raw_svg.text
  let tspan                        = star Raw_svg.tspan
  let textPath                     = star Raw_svg.textPath
  let marker                       = star Raw_svg.marker
  let linearGradient               = star Raw_svg.linearGradient
  let radialGradient               = star Raw_svg.radialGradient
  let stop                         = star Raw_svg.stop
  let pattern                      = star Raw_svg.pattern
  let clipPath                     = star Raw_svg.clipPath
  let filter                       = star Raw_svg.filter
  let feDistantLight               = star Raw_svg.feDistantLight
  let fePointLight                 = star Raw_svg.fePointLight
  let feSpotLight                  = star Raw_svg.feSpotLight
  let feBlend                      = star Raw_svg.feBlend
  let feColorMatrix                = star Raw_svg.feColorMatrix
  let feComponentTransfer          = star Raw_svg.feComponentTransfer
  let feFuncA                      = star Raw_svg.feFuncA
  let feFuncG                      = star Raw_svg.feFuncG
  let feFuncB                      = star Raw_svg.feFuncB
  let feFuncR                      = star Raw_svg.feFuncR
  let feComposite                  = star Raw_svg.feComposite
  let feConvolveMatrix             = star Raw_svg.feConvolveMatrix
  let feDiffuseLighting            = star Raw_svg.feDiffuseLighting
  let feDisplacementMap            = star Raw_svg.feDisplacementMap
  let feFlood                      = star Raw_svg.feFlood
  let feGaussianBlur               = star Raw_svg.feGaussianBlur
  let feImage                      = star Raw_svg.feImage
  let feMerge                      = star Raw_svg.feMerge
  let feMorphology                 = star Raw_svg.feMorphology
  let feOffset                     = star Raw_svg.feOffset
  let feSpecularLighting           = star Raw_svg.feSpecularLighting
  let feTile                       = star Raw_svg.feTile
  let feTurbulence                 = star Raw_svg.feTurbulence
  let cursor                       = star Raw_svg.cursor
  let a                            = star Raw_svg.a
  let view                         = star Raw_svg.view
  let script                       = unary Raw_svg.script
  let animate                      = star Raw_svg.animate
  let animation                    = star Raw_svg.animation
  [@@ocaml.warning "-3"]
  let set                          = star Raw_svg.set
  let animateMotion                = star Raw_svg.animateMotion
  let mpath                        = star Raw_svg.mpath
  let animateColor                 = star Raw_svg.animateColor
  let animateTransform             = star Raw_svg.animateTransform
  let metadata                     = star Raw_svg.metadata
  let foreignObject                = star Raw_svg.foreignObject
  (* let of_seq = Raw_svg.of_seq *)
  let tot = Raw_svg.tot
  (* let totl = Raw_svg.totl *)
  let toelt = Raw_svg.toelt
  (* let toeltl = Raw_svg.toeltl *)
  let doc_toelt = Raw_svg.doc_toelt
  let to_xmlattribs = Raw_svg.to_xmlattribs
  let to_attrib = Raw_svg.to_attrib
end

module Raw_html = Html_f.Make(Xml)(Raw_svg)

open Html_types
module Html : sig
  type 'a elt = 'a node live
  type doc = html elt
  type nonrec +'a attrib = 'a attrib
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
  val svg : ?a:[<Svg_types.svg_attr] Svg.attrib list ->
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

  (* module Unsafe : sig
    val data : string Lwd.t -> 'a elt
    val node : string -> ?a:'a attrib list -> 'b elt list -> 'c elt
    val leaf : string -> ?a:'a attrib list -> unit -> 'b elt
    val coerce_elt : 'a elt -> 'b elt
    val string_attrib : string -> string Lwd.t -> 'a attrib
    val float_attrib : string -> float Lwd.t -> 'a attrib
    val int_attrib : string -> int Lwd.t -> 'a attrib
    val uri_attrib : string -> Xml.uri Lwd.t -> 'a attrib
    val space_sep_attrib : string -> string list Lwd.t -> 'a attrib
    val comma_sep_attrib : string -> string list Lwd.t -> 'a attrib
  end *)
end = struct
  type 'a elt = 'a Raw_html.elt
  type doc = Raw_html.doc
  type nonrec +'a attrib = 'a attrib
  type ('a, 'b) nullary = ?a:'a attrib list -> unit -> 'b elt
  type ('a, 'b, 'c) unary = ?a:'a attrib list -> 'b elt -> 'c elt
  type ('a, 'b, 'c) star = ?a:'a attrib list -> 'b elt list -> 'c elt
  module Info = Raw_html.Info

  let string_of_uri         = Raw_html.string_of_uri
  let uri_of_string         = Raw_html.uri_of_string
  let a_class               = Raw_html.a_class
  let a_user_data           = Raw_html.a_user_data
  let a_id                  = Raw_html.a_id
  let a_title               = Raw_html.a_title
  let a_xml_lang            = Raw_html.a_xml_lang
  let a_lang                = Raw_html.a_lang
  let a_onabort             = Raw_html.a_onabort
  let a_onafterprint        = Raw_html.a_onafterprint
  let a_onbeforeprint       = Raw_html.a_onbeforeprint
  let a_onbeforeunload      = Raw_html.a_onbeforeunload
  let a_onblur              = Raw_html.a_onblur
  let a_oncanplay           = Raw_html.a_oncanplay
  let a_oncanplaythrough    = Raw_html.a_oncanplaythrough
  let a_onchange            = Raw_html.a_onchange
  let a_ondurationchange    = Raw_html.a_ondurationchange
  let a_onemptied           = Raw_html.a_onemptied
  let a_onended             = Raw_html.a_onended
  let a_onerror             = Raw_html.a_onerror
  let a_onfocus             = Raw_html.a_onfocus
  let a_onformchange        = Raw_html.a_onformchange
  let a_onforminput         = Raw_html.a_onforminput
  let a_onhashchange        = Raw_html.a_onhashchange
  let a_oninput             = Raw_html.a_oninput
  let a_oninvalid           = Raw_html.a_oninvalid
  let a_onmousewheel        = Raw_html.a_onmousewheel
  let a_onoffline           = Raw_html.a_onoffline
  let a_ononline            = Raw_html.a_ononline
  let a_onpause             = Raw_html.a_onpause
  let a_onplay              = Raw_html.a_onplay
  let a_onplaying           = Raw_html.a_onplaying
  let a_onpagehide          = Raw_html.a_onpagehide
  let a_onpageshow          = Raw_html.a_onpageshow
  let a_onpopstate          = Raw_html.a_onpopstate
  let a_onprogress          = Raw_html.a_onprogress
  let a_onratechange        = Raw_html.a_onratechange
  let a_onreadystatechange  = Raw_html.a_onreadystatechange
  let a_onredo              = Raw_html.a_onredo
  let a_onresize            = Raw_html.a_onresize
  let a_onscroll            = Raw_html.a_onscroll
  let a_onseeked            = Raw_html.a_onseeked
  let a_onseeking           = Raw_html.a_onseeking
  let a_onselect            = Raw_html.a_onselect
  let a_onshow              = Raw_html.a_onshow
  let a_onstalled           = Raw_html.a_onstalled
  let a_onstorage           = Raw_html.a_onstorage
  let a_onsubmit            = Raw_html.a_onsubmit
  let a_onsuspend           = Raw_html.a_onsuspend
  let a_ontimeupdate        = Raw_html.a_ontimeupdate
  let a_onundo              = Raw_html.a_onundo
  let a_onunload            = Raw_html.a_onunload
  let a_onvolumechange      = Raw_html.a_onvolumechange
  let a_onwaiting           = Raw_html.a_onwaiting
  let a_onload              = Raw_html.a_onload
  let a_onloadeddata        = Raw_html.a_onloadeddata
  let a_onloadedmetadata    = Raw_html.a_onloadedmetadata
  let a_onloadstart         = Raw_html.a_onloadstart
  let a_onmessage           = Raw_html.a_onmessage
  let a_onclick             = Raw_html.a_onclick
  let a_oncontextmenu       = Raw_html.a_oncontextmenu
  let a_ondblclick          = Raw_html.a_ondblclick
  let a_ondrag              = Raw_html.a_ondrag
  let a_ondragend           = Raw_html.a_ondragend
  let a_ondragenter         = Raw_html.a_ondragenter
  let a_ondragleave         = Raw_html.a_ondragleave
  let a_ondragover          = Raw_html.a_ondragover
  let a_ondragstart         = Raw_html.a_ondragstart
  let a_ondrop              = Raw_html.a_ondrop
  let a_onmousedown         = Raw_html.a_onmousedown
  let a_onmouseup           = Raw_html.a_onmouseup
  let a_onmouseover         = Raw_html.a_onmouseover
  let a_onmousemove         = Raw_html.a_onmousemove
  let a_onmouseout          = Raw_html.a_onmouseout
  let a_ontouchstart        = Raw_html.a_ontouchstart
  let a_ontouchend          = Raw_html.a_ontouchend
  let a_ontouchmove         = Raw_html.a_ontouchmove
  let a_ontouchcancel       = Raw_html.a_ontouchcancel
  let a_onkeypress          = Raw_html.a_onkeypress
  let a_onkeydown           = Raw_html.a_onkeydown
  let a_onkeyup             = Raw_html.a_onkeyup
  let a_allowfullscreen     = Raw_html.a_allowfullscreen
  let a_allowpaymentrequest = Raw_html.a_allowpaymentrequest
  let a_autocomplete        = Raw_html.a_autocomplete
  let a_async               = Raw_html.a_async
  let a_autofocus           = Raw_html.a_autofocus
  let a_autoplay            = Raw_html.a_autoplay
  let a_muted               = Raw_html.a_muted
  let a_crossorigin         = Raw_html.a_crossorigin
  let a_integrity           = Raw_html.a_integrity
  let a_mediagroup          = Raw_html.a_mediagroup
  let a_challenge           = Raw_html.a_challenge
  let a_contenteditable     = Raw_html.a_contenteditable
  let a_contextmenu         = Raw_html.a_contextmenu
  let a_controls            = Raw_html.a_controls
  let a_dir                 = Raw_html.a_dir
  let a_draggable           = Raw_html.a_draggable
  let a_form                = Raw_html.a_form
  let a_formaction          = Raw_html.a_formaction
  let a_formenctype         = Raw_html.a_formenctype
  let a_formnovalidate      = Raw_html.a_formnovalidate
  let a_formtarget          = Raw_html.a_formtarget
  let a_hidden              = Raw_html.a_hidden
  let a_high                = Raw_html.a_high
  let a_icon                = Raw_html.a_icon
  let a_ismap               = Raw_html.a_ismap
  let a_keytype             = Raw_html.a_keytype
  let a_list                = Raw_html.a_list
  let a_loop                = Raw_html.a_loop
  let a_low                 = Raw_html.a_low
  let a_max                 = Raw_html.a_max
  let a_input_max           = Raw_html.a_input_max
  let a_min                 = Raw_html.a_min
  let a_input_min           = Raw_html.a_input_min
  let a_inputmode           = Raw_html.a_inputmode
  let a_novalidate          = Raw_html.a_novalidate
  let a_open                = Raw_html.a_open
  let a_optimum             = Raw_html.a_optimum
  let a_pattern             = Raw_html.a_pattern
  let a_placeholder         = Raw_html.a_placeholder
  let a_poster              = Raw_html.a_poster
  let a_preload             = Raw_html.a_preload
  let a_pubdate             = Raw_html.a_pubdate
  let a_radiogroup          = Raw_html.a_radiogroup
  let a_referrerpolicy      = Raw_html.a_referrerpolicy
  let a_required            = Raw_html.a_required
  let a_reversed            = Raw_html.a_reversed
  let a_sandbox             = Raw_html.a_sandbox
  let a_spellcheck          = Raw_html.a_spellcheck
  let a_scoped              = Raw_html.a_scoped
  let a_seamless            = Raw_html.a_seamless
  let a_sizes               = Raw_html.a_sizes
  let a_span                = Raw_html.a_span
  type image_candidate = [
    | `Url of Xml.uri
    | `Url_pixel of Xml.uri * float
    | `Url_width of Xml.uri * int
  ]
  let a_srcset              = Raw_html.a_srcset
  let a_img_sizes           = Raw_html.a_img_sizes
  let a_start               = Raw_html.a_start
  let a_step                = Raw_html.a_step
  let a_wrap                = Raw_html.a_wrap
  let a_version             = Raw_html.a_version
  let a_xmlns               = Raw_html.a_xmlns
  let a_manifest            = Raw_html.a_manifest
  let a_cite                = Raw_html.a_cite
  let a_xml_space           = Raw_html.a_xml_space
  let a_accesskey           = Raw_html.a_accesskey
  let a_charset             = Raw_html.a_charset
  let a_accept_charset      = Raw_html.a_accept_charset
  let a_accept              = Raw_html.a_accept
  let a_href                = Raw_html.a_href
  let a_hreflang            = Raw_html.a_hreflang
  let a_download            = Raw_html.a_download
  let a_rel                 = Raw_html.a_rel
  let a_tabindex            = Raw_html.a_tabindex
  let a_mime_type           = Raw_html.a_mime_type
  let a_datetime            = Raw_html.a_datetime
  let a_action              = Raw_html.a_action
  let a_checked             = Raw_html.a_checked
  let a_cols                = Raw_html.a_cols
  let a_enctype             = Raw_html.a_enctype
  let a_label_for           = Raw_html.a_label_for
  let a_output_for          = Raw_html.a_output_for
  let a_maxlength           = Raw_html.a_maxlength
  let a_minlength           = Raw_html.a_minlength
  let a_method              = Raw_html.a_method
  let a_multiple            = Raw_html.a_multiple
  let a_name                = Raw_html.a_name
  let a_rows                = Raw_html.a_rows
  let a_selected            = Raw_html.a_selected
  let a_size                = Raw_html.a_size
  let a_src                 = Raw_html.a_src
  let a_input_type          = Raw_html.a_input_type
  let a_text_value          = Raw_html.a_text_value
  let a_int_value           = Raw_html.a_int_value
  let a_value               = Raw_html.a_value
  let a_float_value         = Raw_html.a_float_value
  let a_disabled            = Raw_html.a_disabled
  let a_readonly            = Raw_html.a_readonly
  let a_button_type         = Raw_html.a_button_type
  let a_command_type        = Raw_html.a_command_type
  let a_menu_type           = Raw_html.a_menu_type
  let a_label               = Raw_html.a_label
  let a_colspan             = Raw_html.a_colspan
  let a_headers             = Raw_html.a_headers
  let a_rowspan             = Raw_html.a_rowspan
  let a_alt                 = Raw_html.a_alt
  let a_height              = Raw_html.a_height
  let a_width               = Raw_html.a_width
  type shape = [ `Circle | `Default | `Poly | `Rect]
  let a_shape               = Raw_html.a_shape
  let a_coords              = Raw_html.a_coords
  let a_usemap              = Raw_html.a_usemap
  let a_data                = Raw_html.a_data
  let a_scrolling           = Raw_html.a_scrolling
  let a_target              = Raw_html.a_target
  let a_content             = Raw_html.a_content
  let a_http_equiv          = Raw_html.a_http_equiv
  let a_defer               = Raw_html.a_defer
  let a_media               = Raw_html.a_media
  let a_style               = Raw_html.a_style
  let a_property            = Raw_html.a_property
  let a_role                = Raw_html.a_role
  let a_aria                = Raw_html.a_aria

  let unary (f: ('a, 'b, 'c) Raw_html.unary) : ('a, 'b, 'c) unary =
    fun ?a elt -> f ?a (Lwd.pure elt)

  let star (f: ('a, 'b, 'c) Raw_html.star) : ('a, 'b, 'c) star =
    fun ?a elts -> f ?a (List.map Lwd.pure elts)

  let pure_opt = function None -> None | Some x -> Some (Lwd.pure x)
  let pures xs = List.map Lwd.pure xs
  let pures_opt = function None -> None | Some xs -> Some (pures xs)

  let txt                   = Raw_html.txt
  let html ?a e1 e2         = Raw_html.html ?a (Lwd.pure e1) (Lwd.pure e2)
  let head ?a e1 elts       = Raw_html.head ?a (Lwd.pure e1) (pures elts)
  let base                  = Raw_html.base
  let title                 = unary Raw_html.title
  let body                  = star Raw_html.body
  let svg                   = star Raw_html.svg
  let footer                = star Raw_html.footer
  let header                = star Raw_html.header
  let section               = star Raw_html.section
  let nav                   = star Raw_html.nav
  let h1                    = star Raw_html.h1
  let h2                    = star Raw_html.h2
  let h3                    = star Raw_html.h3
  let h4                    = star Raw_html.h4
  let h5                    = star Raw_html.h5
  let h6                    = star Raw_html.h6
  let hgroup                = star Raw_html.hgroup
  let address               = star Raw_html.address
  let article               = star Raw_html.article
  let aside                 = star Raw_html.aside
  let main                  = star Raw_html.main
  let p                     = star Raw_html.p
  let pre                   = star Raw_html.pre
  let blockquote            = star Raw_html.blockquote
  let div                   = star Raw_html.div
  let dl                    = star Raw_html.dl
  let ol                    = star Raw_html.ol
  let ul                    = star Raw_html.ul
  let dd                    = star Raw_html.dd
  let dt                    = star Raw_html.dt
  let li                    = star Raw_html.li
  let figcaption            = star Raw_html.figcaption
  let figure ?figcaption ?a elts =
    let figcaption = match figcaption with
      | None -> None
      | Some (`Bottom elt) -> Some (`Bottom (Lwd.pure elt))
      | Some (`Top elt) -> Some (`Top (Lwd.pure elt))
    in
    Raw_html.figure ?figcaption ?a (pures elts)
  let hr                    = Raw_html.hr
  let b                     = star Raw_html.b
  let i                     = star Raw_html.i
  let u                     = star Raw_html.u
  let small                 = star Raw_html.small
  let sub                   = star Raw_html.sub
  let sup                   = star Raw_html.sup
  let mark                  = star Raw_html.mark
  let wbr                   = Raw_html.wbr
  let bdo ~dir              = star (Raw_html.bdo ~dir)
  let abbr                  = star Raw_html.abbr
  let br                    = Raw_html.br
  let cite                  = star Raw_html.cite
  let code                  = star Raw_html.code
  let dfn                   = star Raw_html.dfn
  let em                    = star Raw_html.em
  let kbd                   = star Raw_html.kbd
  let q                     = star Raw_html.q
  let samp                  = star Raw_html.samp
  let span                  = star Raw_html.span
  let strong                = star Raw_html.strong
  let time                  = star Raw_html.time
  let var                   = star Raw_html.var
  let a                     = star Raw_html.a
  let del                   = star Raw_html.del
  let ins                   = star Raw_html.ins
  let img                   = Raw_html.img
  let iframe                = star Raw_html.iframe
  let object_ ?params ?a elts =
    Raw_html.object_ ?params:(pures_opt params) ?a (pures elts)
  let param                 = Raw_html.param
  let embed                 = Raw_html.embed
  let audio ?src ?srcs ?a elts =
    Raw_html.audio ?src ?srcs:(pures_opt srcs) ?a (pures elts)
  let video ?src ?srcs ?a elts =
    Raw_html.video ?src ?srcs:(pures_opt srcs) ?a (pures elts)
  let canvas                = star Raw_html.canvas
  let source                = Raw_html.source
  let area                  = Raw_html.area
  let map                   = star Raw_html.map
  let caption               = star Raw_html.caption
  let table ?caption ?columns ?thead ?tfoot ?a elts =
    Raw_html.table ?caption:(pure_opt caption) ?columns:(pures_opt columns)
      ?thead:(pure_opt thead) ?tfoot:(pure_opt tfoot) ?a (pures elts)
  let tablex ?caption ?columns ?thead ?tfoot ?a elts =
    Raw_html.tablex ?caption:(pure_opt caption) ?columns:(pures_opt columns)
      ?thead:(pure_opt thead) ?tfoot:(pure_opt tfoot) ?a (pures elts)
  let colgroup              = star Raw_html.colgroup
  let col                   = Raw_html.col
  let thead                 = star Raw_html.thead
  let tbody                 = star Raw_html.tbody
  let tfoot                 = star Raw_html.tfoot
  let td                    = star Raw_html.td
  let th                    = star Raw_html.th
  let tr                    = star Raw_html.tr
  let form                  = star Raw_html.form
  let fieldset ?legend ?a elts =
    Raw_html.fieldset ?legend:(pure_opt legend) ?a (pures elts)
  let legend                = star Raw_html.legend
  let label                 = star Raw_html.label
  let input                 = Raw_html.input
  let button                = star Raw_html.button
  let select                = star Raw_html.select
  let datalist ?children ?a () =
    let children = match children with
      | None -> None
      | Some (`Options elts) -> Some (`Options (pures elts))
      | Some (`Phras elts) -> Some (`Phras (pures elts))
    in
    Raw_html.datalist ?children ?a ()
  let optgroup ~label ?a elts = Raw_html.optgroup ~label ?a (pures elts)
  let option                = unary Raw_html.option
  let textarea ?(a=[]) txt =
    let value = Lwd.map ~f:(fun txt -> Some (Js.string txt)) txt in
    let attrib = Attrib.Attrib {name="value"; value} in
    Raw_html.textarea ~a:(attrib :: a)
      (Lwd.pure (Lwd.pure Lwd_seq.empty))
  (*(Lwd.pure (Xml.pcdata txt))*)
  let keygen                = Raw_html.keygen
  let progress              = star Raw_html.progress
  let meter                 = star Raw_html.meter
  let output_elt            = star Raw_html.output_elt
  let entity                = Raw_html.entity
  let space                 = Raw_html.space
  let cdata                 = Raw_html.cdata
  let cdata_script          = Raw_html.cdata_script
  let cdata_style           = Raw_html.cdata_style
  let details elt ?a elts   = Raw_html.details (Lwd.pure elt) ?a (pures elts)
  let summary               = star Raw_html.summary
  let command               = Raw_html.command
  let menu ?children ?a () =
    let children = match children with
      | None -> None
      | Some (`Flows elts) -> Some (`Flows (pures elts))
      | Some (`Lis elts) -> Some (`Lis (pures elts))
    in
    Raw_html.menu ?children ?a ()
  let script                = unary Raw_html.script
  let noscript              = star Raw_html.noscript
  let template              = star Raw_html.template
  let meta                  = Raw_html.meta
  let style                 = star Raw_html.style
  let link                  = Raw_html.link
  let rt                    = star Raw_html.rt
  let rp                    = star Raw_html.rp
  let ruby                  = star Raw_html.ruby
  (* let of_seq = Raw_html.of_seq *)
  let tot = Raw_html.tot
  (* let totl = Raw_html.totl *)
  let toelt = Raw_html.toelt
  (* let toeltl = Raw_html.toeltl *)
  let doc_toelt = Raw_html.doc_toelt
  let to_xmlattribs = Raw_html.to_xmlattribs
  let to_attrib = Raw_html.to_attrib
end

module Lwdom = struct
  type 'a elt = 'a Lwd_seq.t Lwd.t

  let elt x = Lwd.pure (Lwd_seq.element x)
  let attr x : _ attr = Lwd.pure (Some x)
  let rattr x : _ attr = Lwd.map ~f:some x

  (*let to_fragment (elts : _ node elt) =
    let fragment = Dom_html.document##createDocumentFragment in
    Lwd.map' (update_children fragment elts) (fun () -> fragment)*)

  let children : _ elt list -> _ elt = function
    | [] -> empty
    | [x] -> x
    | [x; y] -> Lwd.map2 ~f:Lwd_seq.concat x y
    | xs -> Lwd_utils.reduce Lwd_seq.lwd_monoid xs

  let children_array : _ elt array -> _ elt = function
    | [||] -> empty
    | [|x|] -> x
    | [|x; y|] -> Lwd.map2 ~f:Lwd_seq.concat x y
    | xs -> Lwd_seq.bind (Lwd.pure (Lwd_seq.of_array xs)) (fun x -> x)

  let to_node x = x
end
