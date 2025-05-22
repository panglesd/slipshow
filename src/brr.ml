(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* DOM events.

   We need that underneath some of the APIs below, so
   that comes first. *)

module Ev = struct
  type 'a type' = Jstr.t
  module Type = struct
    type void
    type 'a t = 'a type'
    external create : Jstr.t -> 'a t = "%identity"
    external name : 'a t -> Jstr.t = "%identity"
    external void : Jstr.t -> 'a t = "%identity"
  end
  type void = Type.void type'

  (* Events *)

  type init = Jv.t
  let init ?bubbles ?cancelable ?composed () =
    let o = Jv.obj [||] in
    Jv.Bool.set_if_some o "bubbles" bubbles;
    Jv.Bool.set_if_some o "cancelable" cancelable;
    Jv.Bool.set_if_some o "composed" composed;
    o

  type target = Jv.t
  external target_to_jv : target -> 'a = "%identity"
  external target_of_jv : 'a -> target = "%identity"

  type 'a t = Jv.t
  type 'a event = 'a t
  external to_jv : 'a t -> Jv.t = "%identity"
  external of_jv : Jv.t -> 'a t = "%identity"
  let event = Jv.get Jv.global "Event"
  let create ?(init = Jv.obj [||]) t = Jv.new' event Jv.[| of_jstr t; init|]
  external as_type : 'a t -> 'a = "%identity"
  let type' e = Jv.Jstr.get e "type"
  let target e = Jv.get e "target"
  let current_target e = Jv.get e "currentTarget"
  let composed_path e = Jv.to_list target_of_jv (Jv.call e "composedPath" [||])
  let event_phase e =
    match Jv.Int.get e "eventPhase" with
    | 1 -> `Capturing | 2 -> `At_target | 3 -> `Bubbling | _ -> `None

  let bubbles e = Jv.Bool.get e "bubbles"
  let stop_propagation e = ignore @@ Jv.call e "stopPropagation" [||]
  let stop_immediate_propagation e =
    ignore @@ Jv.call e "stopImmediatePropagation" [||]

  let cancelable e = Jv.Bool.get e "cancelable"
  let prevent_default e = ignore @@ Jv.call e "preventDefault" [||]
  let default_prevented e = Jv.Bool.get e "defaultPrevented"
  let composed e = Jv.Bool.get e "composed"
  let is_trusted e = Jv.Bool.get e "isTrusted"
  let timestamp_ms e = Jv.Float.get e "timeStamp"
  let dispatch e t = Jv.to_bool @@ Jv.call t "dispatchEvent" [| e |]

  (* Listening *)

  type listen_opts = Jv.t
  let listen_opts ?capture ?once ?passive () =
    let o = Jv.obj [||] in
    Jv.Bool.set_if_some o "capture" capture;
    Jv.Bool.set_if_some o "once" once;
    Jv.Bool.set_if_some o "passive" passive;
    o

  type listener = unit -> unit

  let listen ?(opts = Jv.obj [||]) type' f t =
    let type' = Jv.of_jstr type' in
    let f = Jv.callback ~arity:1 f in
    let unlisten () =
      ignore @@ Jv.call t "removeEventListener" [|type'; f; opts |]
    in
    ignore @@ Jv.call t "addEventListener" [|type'; f; opts |];
    unlisten

  let unlisten unlisten = unlisten ()

  let next ?capture type' t =
    let fut, set = Fut.create () in
    let opts = listen_opts ?capture ~once:true () in
    ignore (listen ~opts type' set t : listener);
    fut

  (* Event objects *)

  module Data_transfer = struct
    module Effect = struct
      type t = Jstr.t
      let none = Jstr.v "none"
      let copy = Jstr.v "copy"
      let copy_link = Jstr.v "copyLink"
      let copy_move = Jstr.v "copyMove"
      let link = Jstr.v "link"
      let link_move = Jstr.v "linkMove"
      let move = Jstr.v "move"
      let all = Jstr.v "all"
      let uninitialized = Jstr.v "uninitialized"
    end
    module Item = struct
      module Kind = struct
        type t = Jstr.t
        let file = Jstr.v "file"
        let string = Jstr.v "string"
      end
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let kind i = Jv.Jstr.get i "kind"
      let type' i = Jv.Jstr.get i "type"
      let get_file i = Jv.to_option Fun.id (Jv.call i "getAsFile" [||])
      let get_jstr i =
        let str, set_str = Fut.create () in
        let set_str = Jv.callback ~arity:1 set_str in
        ignore (Jv.call i "getAsString" [| set_str |]);
        str
    end
    module Item_list = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)

      let length l = Jv.Int.get l "length"

      let add_jstr l ~type' str =
        Jv.to_option Item.of_jv @@
        Jv.call l "add" Jv.[| of_jstr str; of_jstr type' |]

      let add_file t file =
        Jv.to_option Item.of_jv @@
        Jv.call t "add" [| file |]

      let remove l i = ignore (Jv.call l "remove" Jv.[|of_int i|])
      let clear l = ignore (Jv.call l "clear" [||])
      external item : t -> int -> Item.t = "caml_js_get"

      let items l =
        let acc = ref [] in
        for i = length l - 1 downto 0 do acc := item l i :: !acc done;
        !acc
    end

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let drop_effect d = Jv.Jstr.get d "dropEffect"
    let set_drop_effect d e = Jv.Jstr.set d "dropEffect" e
    let effect_allowed d = Jv.Jstr.get d "effectAllowed"
    let set_effect_allowed d e = Jv.Jstr.set d "effectAllowed" e
    let items d = Item_list.of_jv @@ Jv.get d "items"
  end
  module Clipboard = struct
    type t = Jv.t
    let data c = Jv.find_map Data_transfer.of_jv c "clipboardData"
  end
  module Composition = struct
    type t = Jv.t
    let data i = Jv.Jstr.get i "data"
  end
  module Error = struct
    type t = Jv.t
    let message e = Jv.Jstr.get e "message"
    let filename e = Jv.Jstr.get e "filename"
    let lineno e = Jv.Int.get e "lineno"
    let colno e = Jv.Int.get e "colno"
    let error e = Jv.get e "error"
  end
  module Extendable = struct
    type t = Jv.t
    let wait_until e fut =
      ignore @@ Jv.call e "waitUntil" [| Fut.to_promise ~ok:Jv.repr fut |]
  end
  module Focus = struct
    type t = Jv.t
    let related_target m = Jv.find_map target_of_jv m "relatedTarget"
  end
  module Hash_change = struct
    type t = Jv.t
    let old_url e = Jv.Jstr.get e "oldURL"
    let new_url e = Jv.Jstr.get e "newURL"
  end
  module Input = struct
    type t = Jv.t
    let data i = Jv.Jstr.get i "data"
    let data_transfer i = Jv.find i "dataTransfer"
    let input_type i = Jv.Jstr.get i "inputType"
    let is_composing i = Jv.Bool.get i "isComposing"
  end
  module Keyboard = struct
    module Location = struct
      type t = int
      let standard = 0x00
      let left = 0x01
      let right = 0x02
      let numpad = 0x03
    end
    type t = Jv.t
    let key k = Jv.Jstr.get k "key"
    let code k = Jv.Jstr.get k "code"
    let location k = Jv.Int.get k "location"
    let repeat k = Jv.Bool.get k "repeat"
    let is_composing k = Jv.Bool.get k "isComposing"
    let alt_key k = Jv.Bool.get k "altKey"
    let ctrl_key k = Jv.Bool.get k "ctrlKey"
    let shift_key k = Jv.Bool.get k "shiftKey"
    let meta_key k = Jv.Bool.get k "metaKey"
    let get_modifier_state k key =
      Jv.to_bool @@ Jv.call k "getModifierState" Jv.[| of_jstr key |]
  end
  module Mouse = struct
    type t = Jv.t
    let related_target m = Jv.find_map target_of_jv m "relatedTarget"
    let offset_x m = Jv.Float.get m "offsetX"
    let offset_y m = Jv.Float.get m "offsetY"
    let client_x m = Jv.Float.get m "clientX"
    let client_y m = Jv.Float.get m "clientY"
    let page_x m = Jv.Float.get m "pageX"
    let page_y m = Jv.Float.get m "pageY"
    let screen_x m = Jv.Float.get m "screenX"
    let screen_y m = Jv.Float.get m "screenY"
    let movement_x m = Jv.Float.get m "movementX"
    let movement_y m = Jv.Float.get m "movementY"
    let button m = Jv.Int.get m "button"
    let buttons m = Jv.Int.get m "buttons"
    let alt_key m = Jv.Bool.get m "altKey"
    let ctrl_key m = Jv.Bool.get m "ctrlKey"
    let shift_key m = Jv.Bool.get m "shiftKey"
    let meta_key m = Jv.Bool.get m "metaKey"
    let get_modifier_state m key =
      Jv.to_bool @@ Jv.call m "getModifierState" Jv.[| of_jstr key |]
  end
  module Drag = struct
    type t = Jv.t
    external as_mouse : t -> Mouse.t = "%identity"
    let data_transfer d = Jv.find_map Fun.id d "dataTransfer"
  end
  module Pointer = struct
    type t = Jv.t
    external as_mouse : t -> Mouse.t = "%identity"
    let id p = Jv.Int.get p "pointerId"
    let width p = Jv.Float.get p "width"
    let height p = Jv.Float.get p "height"
    let pressure p = Jv.Float.get p "pressure"
    let tangential_pressure p = Jv.Float.get p "tangentialPressure"
    let tilt_x p = Jv.Int.get p "tiltX"
    let tilt_y p = Jv.Int.get p "tiltY"
    let twist p = Jv.Int.get p "twist"
    let altitude_angle p = Jv.Float.get p "altitudeAngle"
    let azimuth_angle p = Jv.Float.get p "azimuthAngle"
    let type' p = Jv.Jstr.get p "pointerType"
    let is_primary p = Jv.Bool.get p "isPrimary"
    let get_coalesced_events p =
      Jv.to_list Fun.id (Jv.call p "getCoalescedEvents" [||])

    let get_predicted_events p =
      Jv.to_list Fun.id (Jv.call p "getPredictedEvents" [||])
  end
  module Wheel = struct
    module Delta_mode = struct
      type t = int
      let pixel = 0x00
      let line = 0x01
      let page = 0x02
    end
    type t = Jv.t
    external as_mouse : t -> Mouse.t = "%identity"
    let delta_x w = Jv.Float.get w "deltaX"
    let delta_y w = Jv.Float.get w "deltaY"
    let delta_z w = Jv.Float.get w "deltaZ"
    let delta_mode w = Jv.Int.get w "deltaMode"
  end

  (* Event types *)

  let abort = Type.void (Jstr.v "abort")
  let activate = Type.create (Jstr.v "activate")
  let auxclick = Type.create (Jstr.v "dblclick")
  let beforeinput = Type.create (Jstr.v "beforeinput")
  let beforeunload = Type.create (Jstr.v "beforeunload")
  let blur = Type.create (Jstr.v "blur")
  let canplay = Type.void (Jstr.v "canplay")
  let canplaythrough = Type.void (Jstr.v "canplaythrough")
  let change = Type.void (Jstr.v "change")
  let click = Type.create (Jstr.v "click")
  let clipboardchange = Type.create (Jstr.v "clipboardchange")
  let close = Type.void (Jstr.v "close")
  let compositionend = Type.create (Jstr.v "compositionend")
  let compositionstart = Type.create (Jstr.v "compositionstart")
  let compositionudpate = Type.create (Jstr.v "compositionupdate")
  let controllerchange = Type.create (Jstr.v "controllerchange")
  let copy = Type.create (Jstr.v "copy")
  let cut = Type.create (Jstr.v "cut")
  let dblclick = Type.create (Jstr.v "dblclick")
  let dom_content_loaded = Type.void (Jstr.v "DOMContentLoaded")
  let drag = Type.create (Jstr.v "drag")
  let dragend = Type.create (Jstr.v "dragend")
  let dragenter = Type.create (Jstr.v "dragenter")
  let dragexit = Type.create (Jstr.v "dragexit")
  let dragleave = Type.create (Jstr.v "dragleave")
  let dragover = Type.create (Jstr.v "dragover")
  let dragstart = Type.create (Jstr.v "dragstart")
  let drop = Type.create (Jstr.v "drop")
  let durationchange = Type.void (Jstr.v "durationchange")
  let emptied = Type.void (Jstr.v "emptied")
  let ended = Type.void (Jstr.v "ended")
  let error = Type.create (Jstr.v "error")
  let focus = Type.create (Jstr.v "focus")
  let focusin = Type.create (Jstr.v "focusin")
  let focusout = Type.create (Jstr.v "focusout")
  let fullscreenchange = Type.create (Jstr.v "fullscreenchange")
  let fullscreenerror = Type.create (Jstr.v "fullscreenerror")
  let gotpointercapture = Type.create (Jstr.v "gotpointercapture")
  let hashchange = Type.create (Jstr.v "hashchange")
  let input = Type.create (Jstr.v "input")
  let install = Type.create (Jstr.v "install")
  let keydown = Type.create (Jstr.v "keydown")
  let keyup = Type.create (Jstr.v "keyup")
  let languagechange = Type.void (Jstr.v "languagechange")
  let load = Type.void (Jstr.v "load")
  let loadeddata = Type.void (Jstr.v "loadeddata")
  let loadedmetadata = Type.void (Jstr.v "loadedmetadata")
  let loadstart = Type.void (Jstr.v "loadstart")
  let lostpointercapture = Type.create (Jstr.v "lostpointercapture")
  let mousedown = Type.create (Jstr.v "mousedown")
  let mouseenter = Type.create (Jstr.v "mouseenter")
  let mouseleave = Type.create (Jstr.v "mouseleave")
  let mousemove = Type.create (Jstr.v "mousemove")
  let mouseout = Type.create (Jstr.v "mouseout")
  let mouseover = Type.create (Jstr.v "mouseover")
  let mouseup = Type.create (Jstr.v "mouseup")
  let open' = Type.void (Jstr.v "open")
  let paste = Type.create (Jstr.v "paste")
  let pause = Type.void (Jstr.v "pause")
  let play = Type.void (Jstr.v "play")
  let playing = Type.void (Jstr.v "playing")
  let pointercancel = Type.create (Jstr.v "pointercancel")
  let pointerdown = Type.create (Jstr.v "pointerdown")
  let pointerenter = Type.create (Jstr.v "pointerenter")
  let pointerleave = Type.create (Jstr.v "pointerleave")
  let pointerlockchange = Type.create (Jstr.v "pointerlockchange")
  let pointerlockerror = Type.create (Jstr.v "pointerlockerror")
  let pointermove = Type.create (Jstr.v "pointermove")
  let pointerout = Type.create (Jstr.v "pointerout")
  let pointerover = Type.create (Jstr.v "pointerover")
  let pointerrawupdate = Type.create (Jstr.v "pointerrawupdate")
  let pointerup = Type.create (Jstr.v "pointerup")
  let progress = Type.void (Jstr.v "progress")
  let ratechange = Type.void (Jstr.v "ratechange")
  let reset = Type.void (Jstr.v "reset")
  let resize = Type.void (Jstr.v "resize")
  let scroll = Type.create (Jstr.v "scroll")
  let seeked = Type.void (Jstr.v "seeked")
  let seeking = Type.void (Jstr.v "seeking")
  let select = Type.void (Jstr.v "select")
  let stalled = Type.void (Jstr.v "stalled")
  let statechange = Type.void (Jstr.v "statechange")
  let suspend = Type.void (Jstr.v "suspend")
  let timeupdate = Type.void (Jstr.v "timeupdate")
  let unload = Type.void (Jstr.v "unload")
  let updatefound = Type.void (Jstr.v "updatefound")
  let visibilitychange = Type.void (Jstr.v "visibilitychange")
  let volumechange = Type.void (Jstr.v "volumechange")
  let waiting = Type.void (Jstr.v "waiting")
  let wheel = Type.create (Jstr.v "wheel")
end

(* Data containers and encodings *)

module Tarray = struct

  (* Array buffers *)

  module Buffer = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let array_buffer = Jv.get Jv.global "ArrayBuffer"
    let create n = Jv.new' array_buffer Jv.[| of_int n |]
    let byte_length a = Jv.Int.get a "byteLength"
    let slice ?(start = 0) ?stop  a =
      let stop = match stop with None -> byte_length a | Some stop -> stop in
      Jv.call a "slice" Jv.[| of_int start; of_int stop |]
  end

  (* Common to typed arrays and DataViews *)

  let buffer o = Buffer.of_jv @@ Jv.get o "buffer"
  let byte_offset o = Jv.Int.get o "byteOffset"
  let byte_length o = Jv.Int.get o "byteLength"

  (* Byte-level data access *)

  module Data_view = struct
    type t = Jv.t (* DataView object *)
    include (Jv.Id : Jv.CONV with type t := t)

    let dataview = Jv.get Jv.global "DataView"
    let of_buffer ?(byte_offset = 0) ?byte_length b =
      let byte_length = match byte_length with
      | None -> Buffer.byte_length b
      | Some l -> l
      in
      Jv.new' dataview
        Jv.[|Buffer.to_jv b; of_int byte_offset; of_int byte_length|]

    let buffer = buffer
    let byte_offset = byte_offset
    let byte_length = byte_length

    let get_int8 b i =
      Jv.to_int @@ Jv.call b "getInt8" Jv.[| of_int i |]

    let get_int16_be b i =
      Jv.to_int @@ Jv.call b "getInt16" Jv.[| of_int i |]

    let get_int16_le b i =
      Jv.to_int @@ Jv.call b "getInt16" Jv.[| of_int i; Jv.true' |]

    let get_int32_be b i =
      Jv.to_int32 @@ Jv.call b "getInt32" Jv.[| of_int i |]

    let get_int32_le b i =
      Jv.to_int32 @@ Jv.call b "getInt32" Jv.[| of_int i; Jv.true' |]

    let get_uint8 b i =
      Jv.to_int @@ Jv.call b "getUint8" Jv.[| of_int i |]

    let get_uint16_be b i =
      Jv.to_int @@ Jv.call b "getUint16" Jv.[| of_int i |]

    let get_uint16_le b i =
      Jv.to_int @@ Jv.call b "getUint16" Jv.[| of_int i; Jv.true' |]

    let get_uint32_be b i =
      Jv.to_int32 @@ Jv.call b "getUint32" Jv.[| of_int i |]

    let get_uint32_le b i =
      Jv.to_int32 @@ Jv.call b "getUint32" Jv.[| of_int i; Jv.true' |]

    let get_float32_be b i =
      Jv.to_float @@ Jv.call b "getFloat32" Jv.[| of_int i |]

    let get_float32_le b i =
      Jv.to_float @@ Jv.call b "getFloat32" Jv.[| of_int i; Jv.true' |]

    let get_float64_be b i =
      Jv.to_float @@ Jv.call b "getFloat64" Jv.[| of_int i |]

    let get_float64_le b i =
      Jv.to_float @@ Jv.call b "getFloat64" Jv.[| of_int i; Jv.true' |]

    let set_int8 b i v =
      ignore @@ Jv.call b "setInt8" Jv.[| of_int i; of_int v |]

    let set_int16_be b i v =
      ignore @@ Jv.call b "setInt16" Jv.[| of_int i; of_int v |]

    let set_int16_le b i v =
      ignore @@ Jv.call b "setInt16" Jv.[| of_int i; of_int v; Jv.true' |]

    let set_int32_be b i v =
      ignore @@ Jv.call b "setInt32" Jv.[| of_int i; of_int32 v |]

    let set_int32_le b i v =
      ignore @@ Jv.call b "setInt32" Jv.[| of_int i; of_int32 v; Jv.true' |]

    let set_uint8 b i v =
      ignore @@ Jv.call b "setUint8" Jv.[| of_int i; of_int v |]

    let set_uint16_be b i v =
      ignore @@ Jv.call b "setUint16" Jv.[| of_int i; of_int v |]

    let set_uint16_le b i v =
      ignore @@ Jv.call b "setUint16" Jv.[| of_int i; of_int v; Jv.true' |]

    let set_uint32_be b i v =
      ignore @@ Jv.call b "setUint32" Jv.[| of_int i; of_int32 v |]

    let set_uint32_le b i v =
      ignore @@ Jv.call b "setUint32" Jv.[| of_int i; of_int32 v; Jv.true' |]

    let set_float32_be b i v =
      ignore @@ Jv.call b "setFloat32" Jv.[| of_int i; of_float v |]

    let set_float32_le b i v =
      ignore @@ Jv.call b "setFloat32" Jv.[| of_int i; of_float v; Jv.true' |]

    let set_float64_be b i v =
      ignore @@ Jv.call b "setFloat64" Jv.[| of_int i; of_float v |]

    let set_float64_le b i v =
      ignore @@ Jv.call b "setFloat64" Jv.[| of_int i; of_float v; Jv.true' |]
  end

  (* Array types *)

  type ('a, 'b) type' =
  | Int8 : (int, Bigarray.int8_signed_elt) type'
  | Int16 : (int, Bigarray.int16_signed_elt) type'
  | Int32 : (int32, Bigarray.int32_elt) type'
  | Uint8 : (int, Bigarray.int8_unsigned_elt) type'
  | Uint8_clamped : (int, Bigarray.int8_unsigned_elt) type'
  | Uint16 : (int, Bigarray.int16_unsigned_elt) type'
  | Uint32 : (int32, Bigarray.int32_elt) type'
  | Float32 : (float, Bigarray.float32_elt) type'
  | Float64 : (float, Bigarray.float64_elt) type'

  let type_size_in_bytes : type a b. (a, b) type' -> int = function
  | Int8 | Uint8 | Uint8_clamped -> 1 | Int16 | Uint16 -> 2
  | Int32 | Uint32 | Float32 -> 4 | Float64  -> 8

  (* Typed arrays *)

  type ('a, 'b) t = Jv.t
  external to_jv : ('a, 'b) t -> Jv.t = "%identity"
  external of_jv : Jv.t -> ('a, 'b) t = "%identity"

  let cons_of_type : type a b. (a, b) type' -> Jv.t = function
  | Int8 -> Jv.get Jv.global "Int8Array"
  | Int16 -> Jv.get Jv.global "Int16Array"
  | Int32 -> Jv.get Jv.global "Int32Array"
  | Uint8 -> Jv.get Jv.global "Uint8Array"
  | Uint8_clamped -> Jv.get Jv.global "Uint8ClampedArray"
  | Uint16 -> Jv.get Jv.global "Uint16Array"
  | Uint32 -> Jv.get Jv.global "Uint32Array"
  | Float32 -> Jv.get Jv.global "Float32Array"
  | Float64 -> Jv.get Jv.global "Float64Array"

  let create t n = Jv.new' (cons_of_type t) Jv.[| of_int n |]
  let of_buffer t ?(byte_offset = 0) ?length b =
    let args = match length with
    | None -> Jv.[| b; of_int byte_offset |]
    | Some l -> Jv.[| b; of_int byte_offset; of_int l |]
    in
    Jv.new' (cons_of_type t) args

  let length a = Jv.Int.get a "length"
  let type' : type a b. (a, b) t -> (a, b) type' = fun a ->
    let m = Obj.magic in
    match Jstr.to_string (Jv.Jstr.get (Jv.get a "constructor") "name") with
    | "Int8Array" -> m Int8
    | "Int16Array" -> m Int16
    | "Int32Array" -> m Int32
    | "Uint8Array" -> m Uint8
    | "Uint8ClampedArray" -> m Uint8_clamped
    | "Uint16Array" -> m Uint16
    | "Uint32Array" -> m Uint32
    | "Float32Array" -> m Float32
    | "Float64Array" -> m Float64
    | s ->
        let t = Jstr.of_string s in
        Jv.throw (Jstr.append (Jstr.v "Unknown typed array: ") t)

  let to_jv_of_type : type a b. (a, b) type' -> a -> Jv.t = function
  | Int8 -> Jv.of_int
  | Int16 -> Jv.of_int
  | Int32 -> Jv.of_int32
  | Uint8 -> Jv.of_int
  | Uint8_clamped -> Jv.of_int
  | Uint16 -> Jv.of_int
  | Uint32 -> Jv.of_int32
  | Float32 -> Jv.of_float
  | Float64 -> Jv.of_float

  let of_jv_of_type : type a b. (a, b) type' -> Jv.t -> a = function
  | Int8 -> Jv.to_int
  | Int16 -> Jv.to_int
  | Int32 -> Jv.to_int32
  | Uint8 -> Jv.to_int
  | Uint8_clamped -> Jv.to_int
  | Uint16 -> Jv.to_int
  | Uint32 -> Jv.to_int32
  | Float32 -> Jv.to_float
  | Float64 -> Jv.to_float

  let elt_to_jv a = to_jv_of_type (type' a)
  let elt_of_jv a = of_jv_of_type (type' a)

  (* Setting, copying and slicing *)

  let compiled_to_wasm = match Sys.backend_type with
  | Other "wasm_of_ocaml" -> true
  | _ -> false

  external get : ('a, 'b) t -> int -> 'a = "caml_js_get"
  external set : ('a, 'b) t -> int -> 'a -> unit = "caml_js_set"

  let get =
    if compiled_to_wasm
    then fun a i -> elt_of_jv a (Jv.Jarray.get (Jv.repr a) i)
    else get

  let set =
    if compiled_to_wasm
    then fun a i v -> Jv.Jarray.set (Jv.repr a) i (elt_to_jv a v)
    else set

  let set_tarray a ~dst b = ignore @@ Jv.call a "set" Jv.[| b; of_int dst |]

  let fill ?(start = 0) ?stop v a =
    let stop = match stop with None -> length a | Some stop -> stop in
    ignore @@ Jv.call a "fill" Jv.[| elt_to_jv a v; of_int start; of_int stop |]

  let copy_within ?(start = 0) ?stop ~dst a =
    let stop = match stop with None -> length a | Some stop -> stop in
    ignore @@
    Jv.call a "copyWithin" Jv.[| of_int dst; of_int start; of_int stop |]

  let slice ?(start = 0) ?stop  a =
    let stop = match stop with None -> byte_length a | Some stop -> stop in
    Jv.call a "slice" Jv.[| of_int start; of_int stop |]

  let sub ?(start = 0) ?stop  a =
    let stop = match stop with None -> byte_length a | Some stop -> stop in
    Jv.call a "subarray" Jv.[| of_int start; of_int stop |]

  (* Predicates *)

  let find sat a =
    let of_jv = elt_of_jv a in
    let sat v i = Jv.of_bool (sat i (of_jv v)) in
    Jv.to_option of_jv (Jv.call a "find" Jv.[| callback ~arity:2 sat |])

  let find_index sat a =
    let of_jv = elt_of_jv a in
    let sat v i = Jv.of_bool (sat i (of_jv v)) in
    let i = Jv.to_int (Jv.call a "findIndex" Jv.[| callback ~arity:2 sat |]) in
    if i = -1 then None else Some i

  let for_all sat a =
    let of_jv = elt_of_jv a in
    let sat v i = Jv.of_bool (sat i (of_jv v)) in
    Jv.to_bool @@ Jv.call a "every" Jv.[| callback ~arity:2 sat |]

  let exists sat a =
    let of_jv = elt_of_jv a in
    let sat v i = Jv.of_bool (sat i (of_jv v)) in
    Jv.to_bool @@ Jv.call a "every" Jv.[| callback ~arity:2 sat |]

  (* Traversals *)

  let filter sat a =
    let of_jv = elt_of_jv a in
    let sat v i = Jv.of_bool (sat i (of_jv v)) in
    Jv.call a "filter" Jv.[| callback ~arity:2 sat |]

  let iter f a =
    let of_jv = elt_of_jv a in
    let f v i = f i (of_jv v) in
    ignore @@ Jv.call a "forEach" Jv.[| callback ~arity:2 f |]

  let map f a =
    let of_jv = elt_of_jv a in
    let f v = f (of_jv v) in
    Jv.call a "map" Jv.[| callback ~arity:1 f |]

  let fold_left f acc a =
    let of_jv = elt_of_jv a in
    let f acc v = f acc (of_jv v) in
    Obj.magic @@ Jv.call a "reduce" [|Jv.callback ~arity:2 f; Jv.repr acc|]

  let fold_right f a acc =
    let of_jv = elt_of_jv a in
    let f acc v = f (of_jv v) acc in
    Obj.magic @@ Jv.call a "reduceRight" [|Jv.callback ~arity:2 f; Jv.repr acc|]

  let reverse a = Jv.call a "reverse" [||]

  (* Type aliases *)

  type int8 = (int, Bigarray.int8_signed_elt) t
  type int16 = (int, Bigarray.int16_signed_elt) t
  type int32 = (int32, Bigarray.int32_elt) t
  type uint8 = (int, Bigarray.int8_unsigned_elt) t
  type uint8_clamped = (int, Bigarray.int8_unsigned_elt) t
  type uint16 = (int, Bigarray.int16_unsigned_elt) t
  type uint32 = (int32, Bigarray.int32_elt) t
  type float32 = (float, Bigarray.float32_elt) t
  type float64 = (float, Bigarray.float64_elt) t

  (* Converting *)

  let of_tarray t a = Jv.new' (cons_of_type t) [| a |]
  let of_int_array t a = Jv.new' (cons_of_type t) Jv.[| of_array Jv.of_int a |]
  let of_float_array t a = Jv.new' (cons_of_type t) Jv.[| of_array of_float a|]
  let to_int_jstr ?(sep = Jstr.sp) b =
    Jv.to_jstr @@ Jv.call b "join" Jv.[| of_jstr sep |]

  let to_hex_jstr ?(sep = Jstr.empty) a =
    let hex = Jstr.v "0123456789abcdef" in
    let d = Data_view.of_buffer (buffer a) in
    let s = ref Jstr.empty in
    for i = 0 to Data_view.byte_length d - 1 do
      let b = Data_view.get_uint8 d i in
      let sep = if i = 0 then Jstr.empty else sep in
      s := Jstr.(!s + sep + get_jstr hex (b lsr 4) + get_jstr hex (b land 0xF))
    done;
    !s

  let uint8_of_buffer b = of_buffer Uint8 b

  external to_string : uint8 -> string = "caml_string_of_array"

  let of_jstr s =
    let enc = Jv.new' (Jv.get Jv.global "TextEncoder") [||] in
    Jv.call enc "encode" [| Jv.of_jstr s |]

  let to_jstr a =
    let args = [| Jv.of_string "utf-8"; Jv.obj [| "fatal", Jv.true' |]|] in
    let dec = Jv.new' (Jv.get Jv.global "TextDecoder") args in
    match Jv.call dec "decode" [| a |] with
    | exception Jv.Error e -> Error e | s -> Ok (Jv.to_jstr s)

  let of_binary_jstr s =
    let code s i =
      let c = Jv.to_int @@ Jv.call (Jv.of_jstr s) "charCodeAt" [|Jv.of_int i|]in
      if c <= 255 then c else
      Jv.throw Jstr.(of_int i + v ": char code " + of_int c + v "exceeds 255")
    in
    try
      let b = Buffer.create (Jstr.length s) in
      let d = Data_view.of_buffer b in
      for i = 0 to Jstr.length s - 1 do Data_view.set_int8 d i (code s i) done;
      Ok (of_buffer Int8 b)
    with
    | Jv.Error e -> Error e

  let to_binary_jstr a =
    let chr b =
      Jv.to_jstr @@
      Jv.call (Jv.get Jv.global "String") "fromCharCode" [| Jv.of_int b |]
    in
    let d = Data_view.of_buffer (buffer a) in
    let s = ref Jstr.empty in
    for i = 0 to Data_view.byte_length d - 1 do
      let b = Data_view.get_uint8 d i in
      s := Jstr.(!s + chr b);
    done;
    !s

  (* Bigarray *)

  let type_to_bigarray_kind : type a b. (a, b) type' -> (a, b) Bigarray.kind =
    function
    | Int8 -> Bigarray.int8_signed
    | Int16 -> Bigarray.int16_signed
    | Int32 -> Bigarray.int32
    | Uint8 -> Bigarray.int8_unsigned
    | Uint8_clamped -> Bigarray.int8_unsigned
    | Uint16 -> Bigarray.int16_unsigned
    | Uint32 -> Bigarray.int32
    | Float32 -> Bigarray.float32
    | Float64 -> Bigarray.float64

  let type_of_bigarray_kind :
    type a b. (a, b) Bigarray.kind -> (a, b) type' option =
    function
    | Bigarray.Int8_signed -> Some Int8
    | Bigarray.Int16_signed -> Some Int16
    | Bigarray.Int32 -> Some Int32
    | Bigarray.Int8_unsigned -> Some Uint8
    | Bigarray.Int16_unsigned -> Some Uint16
    | Bigarray.Float32 -> Some Float32
    | Bigarray.Float64 -> Some Float64
    | _ -> None

  external bigarray_kind : ('a, 'b) t -> ('a,'b) Bigarray.kind =
    "caml_ba_kind_of_typed_array"

  external of_bigarray1 :
    ('a, 'b, Bigarray.c_layout) Bigarray.Array1.t -> ('a, 'b) t =
    "caml_ba_to_typed_array"

  external to_bigarray1 :
    ('a, 'b) t -> ('a, 'b, Bigarray.c_layout) Bigarray.Array1.t =
    "caml_ba_from_typed_array"

  external of_bigarray :
    ('a, 'b, Bigarray.c_layout) Bigarray.Genarray.t -> ('a, 'b) t =
    "caml_ba_to_typed_array"
end

module Blob = struct

  (* Enumerations *)

  module Ending_type = struct
    type t = Jstr.t
    let transparent = Jstr.v "transparent"
    let native = Jstr.v "native"
  end

  (* Initialisation objects *)

  type init = Jv.t
  let init ?type' ?endings () =
    let o = Jv.obj [||] in
    Jv.Jstr.set_if_some o "type" type';
    Jv.Jstr.set_if_some o "endings" endings;
    o

  (* Blobs *)

  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
  let blob = Jv.get Jv.global "Blob"
  let of_jstr ?(init = Jv.undefined) s =
    let a = Jv.Jarray.create 1 in
    Jv.Jarray.set a 0 (Jv.of_jstr s);
    Jv.new' blob [| a; init |]

  let _of_jarray ?(init = Jv.undefined) a = Jv.new' blob [| a; init |]
  let of_array_buffer ?(init = Jv.undefined) b =
    Jv.new' blob [| Jv.of_jv_array [| Tarray.Buffer.to_jv b |]; init |]

  let byte_length b = Jv.Int.get b "size"
  let type' b = Jv.Jstr.get b "type"
  let slice ?(start = 0) ?stop ?(type' = Jstr.empty) b =
    let stop = match stop with None -> byte_length b | Some stop -> stop in
    Jv.call b "slice" Jv.[| of_int start; of_int stop; of_jstr type' |]

  let stream b = Jv.get b "stream"

  (* Loading *)

  type progress = (float * float) option -> unit

  (* If we want progress we need a FileReader *)

  let file_reader ?progress conv =
    let progress_data e =
      let e = Ev.to_jv e in
      if not (Jv.Bool.get e "lengthComputable") then None else
      let loaded = Jv.Float.get e "loaded" in
      let total = Jv.Float.get e "total" in
      Some (loaded, total)
    in
    let reader = Jv.new' (Jv.get Jv.global "FileReader") [||] in
    let fut, set_fut = Fut.create () in
    let ok e =
      begin match progress with
      | None -> ()
      | Some progress -> progress (progress_data e)
      end;
      set_fut (Ok (conv (Jv.get reader "result")))
    in
    let error _e = set_fut (Error (Jv.to_error (Jv.get reader "error"))) in
    let t = Ev.target_of_jv reader in
    let opts = Ev.listen_opts ~once:true () in
    ignore (Ev.listen ~opts Ev.load ok t : Ev.listener);
    ignore (Ev.listen ~opts Ev.error error t : Ev.listener);
    begin match progress with
    | None -> ()
    | Some progress ->
        let progress e = progress (progress_data e) in
        ignore (Ev.listen Ev.progress progress t : Ev.listener);
    end;
    fut, reader

  let array_buffer ?progress b = match progress with
  | None ->
      Fut.of_promise ~ok:Tarray.Buffer.of_jv (Jv.call b "arrayBuffer" [||])
  | Some _ ->
      let fut, reader = file_reader ?progress Tarray.Buffer.of_jv in
      ignore (Jv.call reader "readAsArrayBuffer" [| b |]);
      fut

  let text ?progress b = match progress with
  | None -> Fut.of_promise ~ok:Jv.to_jstr (Jv.call b "text" [||])
  | Some _ ->
      let fut, reader = file_reader ?progress Jv.to_jstr in
      ignore (Jv.call reader "readAsText" [| b |]);
      fut

  let data_uri ?progress b =
    (* There's no direct support for data urls in blob objects.
       We do this via the FileReader API. *)
    let fut, reader = file_reader ?progress Jv.to_jstr in
    ignore (Jv.call reader "readAsDataURL" [| b |]);
    fut
end

module File = struct
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)

  (* Initialisation objects *)

  type init = Jv.t
  let init ?blob_init ?last_modified_ms () =
    let o = match blob_init with None -> Jv.obj [||] | Some b -> Jv.repr b in
    Jv.Int.set_if_some o "lastModified" last_modified_ms;
    o

  let file = Jv.get Jv.global "File"
  let of_blob ?(init = Jv.obj [||]) name b =
    Jv.new' file [|Blob.to_jv b; Jv.of_jstr name; init|]

  let name f = Jv.Jstr.get f "name"
  let relative_path f =
    let p = Jv.find_map Jv.to_jstr f "webkitRelativePath" in
    Option.value ~default:Jstr.empty p

  let last_modified_ms f = Jv.Int.get f "lastModified"
  external as_blob : t -> Blob.t = "%identity"
end

module Base64 = struct

  type data = Jstr.t

  let data_utf_8_of_jstr s = Tarray.to_binary_jstr (Tarray.of_jstr s)
  let data_utf_8_to_jstr d = match Tarray.of_binary_jstr d with
  | Error _ as e -> e | Ok t -> Tarray.to_jstr t

  let data_of_binary_jstr = Fun.id
  let data_to_binary_jstr = Fun.id

  let encode bs =
    match Jv.apply (Jv.get Jv.global "btoa") Jv.[| of_jstr bs |] with
    | exception Jv.Error e -> Error e
    | v -> Ok (Jv.to_jstr v)

  let decode s =
    match Jv.apply (Jv.get Jv.global "atob") Jv.[| of_jstr s |] with
    | exception Jv.Error e -> Error e
    | v -> Ok (Jv.to_jstr v)
end

module Json = struct
  type t = Jv.t
  let json = Jv.get Jv.global "JSON"
  let encode v = Jv.to_jstr (Jv.call json "stringify" [| v |])
  let decode s = match Jv.call json "parse" [|Jv.of_jstr s|] with
  | exception Jv.Error e -> Error e | v -> Ok v
end

module Uri = struct
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)

  let encode = Jv.get Jv.global "encodeURI"
  let decode = Jv.get Jv.global "decodeURI"
  let encode_component = Jv.get Jv.global "encodeURIComponent"
  let decode_component = Jv.get Jv.global "decodeURIComponent"

  let url = Jv.get Jv.global "URL"

  let v ?base s = match base with
  | None -> Jv.new' url [| Jv.of_jstr s |]
  | Some b -> Jv.new' url [| Jv.of_jstr s; Jv.of_jstr b |]

  let with_uri ?scheme ?host ?port ?path ?query ?fragment u =
    let u = Jv.new' url [| u |] in
    try
      Jv.Jstr.set_if_some u "protocol" scheme;
      Jv.Jstr.set_if_some u "hostname" host;
      begin match port with
      | None -> ()
      | Some p -> Jv.Jstr.set_if_some u "port" (Option.map Jstr.of_int p)
      end;
      Jv.Jstr.set_if_some u "pathname" path;
      Jv.Jstr.set_if_some u "search" query;
      Jv.Jstr.set_if_some u "hash" fragment;
      Ok u
    with Jv.Error e -> Error e

  let scheme u =
    let p = Jv.Jstr.get u "protocol" in
    if Jstr.length p <> 0 then Jstr.slice p ~stop:(-1) (* remove ':' *) else p

  let host u = Jv.Jstr.get u "hostname"
  let port u =
    let p = Jv.Jstr.get u "port" in
    if Jstr.is_empty p then None else Jstr.to_int p

  let slash = Jstr.v "/"

  let path u = Jv.Jstr.get u "pathname"

  let query u =
    let q = Jv.Jstr.get u "search" in
    if Jstr.is_empty q then q else Jstr.slice q ~start:1 (* remove '?' *)

  let fragment u =
    let f = Jv.Jstr.get u "hash" in
    if Jstr.is_empty f then f else Jstr.slice f ~start:1 (* remove '#' *)

  (* Path *)

  type path = Jstr.t list

  let path_segments u =
    let decode_seg s = Jv.(to_jstr (apply decode_component [| of_jstr s |])) in
    try
      let p = path u and prefix = slash in
      let p = if Jstr.starts_with ~prefix p then Jstr.slice p ~start:1 else p in
      Ok (List.map decode_seg (Jstr.cuts ~sep:slash p))
    with Jv.Error e -> Error e

  let with_path_segments u segs =
    let encode_seg s =
      Jstr.append slash Jv.(to_jstr (apply encode_component [| of_jstr s |]))
    in
    try
      let u = Jv.new' url [| u |] in
      let path = Jstr.concat (List.map encode_seg segs) in
      Jv.set u "pathname" (Jv.of_jstr path);
      Ok u
    with Jv.Error e -> Error e

  (* Params *)

  module Params = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let usp = Jv.get Jv.global "URLSearchParams"
    let is_empty p = Jv.It.result_done (Jv.It.next (Jv.call p "entries" [||]))
    let mem k p = Jv.to_bool (Jv.call p "has" [|Jv.of_jstr k|])
    let find k p = Jv.to_option Jv.to_jstr (Jv.call p "get" [|Jv.of_jstr k|])
    let find_all k p = Jv.to_jstr_list (Jv.call p "getAll" [|Jv.of_jstr k|])
    let fold f p acc =
      let key = Jv.to_jstr in
      let value = Jv.to_jstr in
      Jv.It.fold_bindings ~key ~value f (Jv.call p "entries" [||]) acc

    let of_jstr s =
      (* Note that it seems that this never errors. At least decoding
         errors seem to be replaced by U+FFFD. *)
      Jv.new' usp [| Jv.of_jstr s|]

    let to_jstr p = Jv.to_jstr (Jv.call p "toString" [||])
    let of_assoc l =
      let p = of_jstr Jstr.empty in
      let app p (k, v) =
        ignore (Jv.call p "append" Jv.[|of_jstr k; of_jstr v|])
      in
      List.iter (app p) l; p

    let to_assoc p = List.rev (fold (fun k v acc -> (k, v) :: acc) p [])
    let of_obj o = Jv.new' usp [| o |]
  end

  let query_params u = Params.of_jstr (query u)
  let with_query_params u ps =
    let u = Jv.new' url [| u |] in
    Jv.Jstr.set u "search" (Params.to_jstr ps);
    u

  let fragment_params u = Params.of_jstr (fragment u)
  let with_fragment_params u ps =
    let u = Jv.new' url [| u |] in
    Jv.Jstr.set u "hash" (Params.to_jstr ps);
    u

  (* Converting *)

  let to_jstr u = Jv.to_jstr (Jv.call u "toString" [||])
  let of_jstr ?base s = match v ?base s with
  | exception Jv.Error e -> Error e | v -> Ok v

  (* Percent-encoding *)

  let code f s = match Jv.apply f [|Jv.of_jstr s|] with
  | exception Jv.Error e -> Error e
  | v -> Ok (Jv.to_jstr v)

  let encode s = code encode s
  let decode s = code decode s
  let encode_component s = code encode_component s
  let decode_component s = code decode_component s
end

(* DOM interaction *)

module At = struct
  type name = Jstr.t
  type t = name * Jstr.t
  let[@inline] v n v = (n, v)
  let void = (Jstr.empty, Jstr.empty)
  let is_void (n, v) = Jstr.is_empty n && Jstr.is_empty v
  let if' b at = if b then at else void
  let if_some = function None -> void | Some at -> at
  let true' n = (n, Jstr.empty)
  let int n i = (n, Jstr.of_int i)
  let float n f = (n, Jstr.of_float f)
  let to_pair = Fun.id
  let add_if b at l = if b then at :: l else l
  let add_if_some name o l = match o with None -> l | Some a -> (name, a) :: l
  module Name = struct
    let accesskey = Jstr.v "accesskey"
    let action = Jstr.v "action"
    let autocomplete = Jstr.v "autocomplete"
    let autofocus = Jstr.v "autofocus"
    let charset = Jstr.v "charset"
    let checked = Jstr.v "checked"
    let class' = Jstr.v "class"
    let cols = Jstr.v "cols"
    let content = Jstr.v "content"
    let contenteditable = Jstr.v "contenteditable"
    let defer = Jstr.v "defer"
    let dir = Jstr.v "dir"
    let disabled = Jstr.v "disabled"
    let download = Jstr.v "download"
    let draggable = Jstr.v "draggable"
    let for' = Jstr.v "for"
    let height = Jstr.v "height"
    let hidden = Jstr.v "hidden"
    let href = Jstr.v "href"
    let id = Jstr.v "id"
    let lang = Jstr.v "lang"
    let list = Jstr.v "list"
    let media = Jstr.v "media"
    let method' = Jstr.v "method"
    let name = Jstr.v "name"
    let placeholder = Jstr.v "placeholder"
    let rel = Jstr.v "rel"
    let required = Jstr.v "required"
    let rows = Jstr.v "rows"
    let selected = Jstr.v "selected"
    let spellcheck = Jstr.v "spellcheck"
    let src = Jstr.v "src"
    let style = Jstr.v "style"
    let tabindex = Jstr.v "tabindex"
    let title = Jstr.v "title"
    let type' = Jstr.v "type"
    let value = Jstr.v "value"
    let width = Jstr.v "width"
    let wrap = Jstr.v "wrap"
  end
  type 'a cons = 'a -> t
  let accesskey s = v Name.accesskey s
  let action s = v Name.action s
  let autocomplete s = v Name.autocomplete s
  let autofocus = true' Name.autofocus
  let charset = v Name.charset
  let checked = true' Name.checked
  let class' s = v Name.class' s
  let cols i = int Name.cols i
  let content s = v Name.content s
  let contenteditable _s = true' Name.contenteditable
  let defer = true' Name.defer
  let dir s = v Name.dir s
  let disabled = true' Name.disabled
  let download s = v Name.download s
  let draggable s = v Name.draggable s
  let for' s = v Name.for' s
  let height i = int Name.height i
  let hidden = true' Name.hidden
  let href s = v Name.href s
  let id s = v Name.id s
  let lang s = v Name.lang s
  let list s = v Name.list s
  let media s = v Name.media s
  let method' s = v Name.method' s
  let name s = v Name.name s
  let placeholder s = v Name.placeholder s
  let rel s = v Name.rel s
  let required = true' Name.required
  let rows i = int Name.rows i
  let selected = true' Name.selected
  let spellcheck = v Name.spellcheck
  let src s = v Name.src s
  let style s = v Name.style s
  let tabindex i = int Name.tabindex i
  let title s = v Name.title s
  let type' s = v Name.type' s
  let value s = v Name.value s
  let width i = int Name.width i
  let wrap s = v Name.wrap s
end

module El = struct
  type document = Jv.t
  type window = Jv.t
  type tag_name = Jstr.t
  type el = Jv.t
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)

  let global_document = Jv.get Jv.global "document"
  let document e = Jv.get e "ownerDocument"
  let global_root =
    if Jv.is_none global_document then (* e.g. web worker *) Jv.undefined else
    Jv.get global_document "documentElement"

  let el_list_of_node_list nl =
    let acc = ref [] in
    let len = Jv.Int.get nl "length" in
    for i = len - 1 downto 0 do acc := Jv.Jarray.get nl i :: !acc done;
    !acc

  let append_child e n = ignore (Jv.call e "appendChild" [| n |])

  let rec set_atts e ss clss = function
  | (a, v) :: at ->
      if Jstr.is_empty a then set_atts e ss clss at else
      if Jstr.equal a At.Name.style then set_atts e (v :: ss) clss at else
      if Jstr.equal a At.Name.class' then
        set_atts e ss (if Jstr.is_empty v then clss else v :: clss) at
      else begin
        ignore (Jv.call e "setAttribute" Jv.[|of_jstr a; of_jstr v|]);
        set_atts e ss clss at
      end
  | [] ->
      if ss <> [] then begin
        let a = At.Name.style in
        let v = Jstr.concat ~sep:(Jstr.v ";") (List.rev ss) in
        ignore (Jv.call e "setAttribute" Jv.[|of_jstr a; of_jstr v|]);
      end;
      if clss <> [] then begin
        let a = At.Name.class' in
        let v = Jstr.concat ~sep:(Jstr.v " ") (List.rev clss) in
        ignore (Jv.call e "setAttribute" Jv.[|of_jstr a; of_jstr v|])
      end

  let v ?ns ?(d = global_document) ?(at = []) name cs =
    let e =
      match ns with
      | None -> Jv.call d "createElement" [| Jv.of_jstr name |]
      | Some ns ->
         let ns = match ns with
           | `HTML -> "http://www.w3.org/1999/xhtml"
           | `SVG -> "http://www.w3.org/2000/svg"
           | `MathML -> "http://www.w3.org/1998/Math/MathML"
         in
         Jv.call d "createElementNS" [| Jv.of_string ns ; Jv.of_jstr name |]
    in
    set_atts e [] [] at;
    List.iter (append_child e) cs;
    e

  let txt ?(d = global_document) s =
    Jv.call d "createTextNode" [|Jv.of_jstr s|]

  let txt' ?(d = global_document) s =
    Jv.call d "createTextNode" [| Jv.of_string s |]

  let sp ?(d = global_document) () = ignore d ; txt (Jstr.v " ")
  let nbsp ?(d = global_document) () = ignore d ; txt (Jstr.v "\u{00A0}")

  let is_txt e = Jv.Int.get e "nodeType" = 3
  let is_el e = Jv.Int.get e "nodeType" = 1
  let tag_name e = Jstr.lowercased @@ Jv.Jstr.get e "nodeName"
  let has_tag_name n e = Jstr.equal n (tag_name e)
  let txt_text txt = match is_txt txt with
  | true -> Jv.Jstr.get txt "nodeValue"
  | false -> Jstr.empty

  external as_target : t -> Ev.target = "%identity"

  (* Element lookups *)

  let find_by_class ?(root = global_root) c =
    el_list_of_node_list @@
    Jv.call root "getElementsByClassName" [| Jv.of_jstr c |]

  let find_by_tag_name ?(root = global_root) n =
    el_list_of_node_list @@
    Jv.call root "getElementsByTagName" [| Jv.of_jstr n |]

  let find_first_by_selector ?(root = global_root) sel =
    Jv.to_option of_jv @@ Jv.call root "querySelector" [| Jv.of_jstr sel |]

  let fold_find_by_selector ?(root = global_root) f sel acc =
    let nl = Jv.call root "querySelectorAll" [| Jv.of_jstr sel |] in
    let acc = ref acc in
    for i = 0 to (Jv.Int.get nl "length") - 1 do
      acc := f (of_jv (Jv.Jarray.get nl i)) !acc
    done;
    !acc

  (* Parent and children *)

  let parent e = match Jv.find e "parentNode" with
  | Some e when is_el e -> Some e
  | _ -> None

  let delete_children e =
    while not (Jv.is_null (Jv.get e "firstChild")) do
      ignore @@ Jv.call e "removeChild" [| Jv.get e "firstChild" |];
    done

  let children ?(only_els = false) e = match only_els with
  | true -> el_list_of_node_list (Jv.get e "children")
  | false -> el_list_of_node_list (Jv.get e "childNodes")

  let contains parent ~child =
    Jv.call parent "contains" [|child|] |> Jv.to_bool

  let set_children e l = delete_children e; List.iter (append_child e) l
  let _append_child e c = ignore @@ Jv.call e "appendChild" [| c |]

  let prepend_children e l = ignore @@ Jv.call e "prepend" (Array.of_list l)
  let append_children e l = ignore @@ Jv.call e "append" (Array.of_list l)
  let previous_sibling e = Jv.find e "previousElementSibling"
  let next_sibling e = Jv.find e "nextElementSibling"
  let insert_siblings loc e l = ignore @@ match loc with
  | `Before -> Jv.call e "before" (Array.of_list l)
  | `After ->  Jv.call e "after" (Array.of_list l)
  | `Replace -> Jv.call e "replaceWith" (Array.of_list l)

  let remove e = ignore @@ Jv.call e "remove" [| e |]

  (* Attributes *)

  let at a e =
    Jv.to_option Jv.to_jstr (Jv.call e "getAttribute" [|Jv.of_jstr a|])

  let set_at a v e =
    if Jstr.is_empty a then () else
    match v with
    | None -> ignore (Jv.call e "removeAttribute" Jv.[|of_jstr a|])
    | Some v -> ignore (Jv.call e "setAttribute" Jv.[|of_jstr a; of_jstr v|])

  (* Properties *)

  module Prop = struct
    type 'a t =
      { n : Jstr.t;
        jv_to : Jv.t -> 'a;
        jv_of : 'a -> Jv.t; }

    let jv_to_bool b = if Jv.is_undefined b then false else Jv.to_bool b
    let jv_to_int i = if Jv.is_undefined i then 0 else Jv.to_int i
    let jv_to_float f = if Jv.is_undefined f then 0. else Jv.to_float f
    let jv_to_jstr s = if Jv.is_undefined s then Jstr.empty else Jv.to_jstr s

    let bool n = { n; jv_to = jv_to_bool ; jv_of = Jv.of_bool }
    let int n = { n; jv_to = jv_to_int ; jv_of = Jv.of_int }
    let float n = { n; jv_to = jv_to_float ; jv_of = Jv.of_float }
    let jstr n = { n; jv_to = jv_to_jstr ; jv_of = Jv.of_jstr }

    let checked = bool (Jstr.v "checked")
    let height = int (Jstr.v "height")
    let id = jstr (Jstr.v "id")
    let name = jstr (Jstr.v "name")
    let title = jstr (Jstr.v "title")
    let value = jstr (Jstr.v "value")
    let width = int (Jstr.v "width")
  end

  let prop p e = p.Prop.jv_to @@ Jv.get' e p.Prop.n
  let set_prop p v e = ignore @@ Jv.set' e p.Prop.n (p.Prop.jv_of v)

  (* Class *)

  let class' c e =
    Jv.to_bool (Jv.call (Jv.get e "classList") "contains" [|Jv.of_jstr c|])

  let set_class c b e = match b with
  | true -> ignore (Jv.call (Jv.get e "classList") "add" [|Jv.of_jstr c|])
  | false -> ignore (Jv.call (Jv.get e "classList") "remove" [|Jv.of_jstr c|])

  (* Style *)

  module Style = struct
    type prop = Jstr.t
    let background_color = Jstr.v "background-color"
    let bottom = Jstr.v "bottom"
    let color = Jstr.v "color"
    let cursor = Jstr.v "cursor"
    let display = Jstr.v "display"
    let height = Jstr.v "height"
    let left = Jstr.v "left"
    let position = Jstr.v "position"
    let right = Jstr.v "right"
    let top = Jstr.v "top"
    let visibility = Jstr.v "visibility"
    let width = Jstr.v "width"
    let z_index = Jstr.v "z-index"
    let zoom = Jstr.v "zoom"
  end

  let computed_style ?(w = Jv.get Jv.global "window") p e =
    let style = Jv.call w "getComputedStyle" [|e|] in
    let v = Jv.get' style p in
    if Jv.is_none v then Jstr.empty else Jv.to_jstr v

  let inline_style p e =
    let style = Jv.get e "style" in
    if Jv.is_none style then Jstr.empty else
    let v = Jv.get' style p in
    if Jv.is_none v then Jstr.empty else Jv.to_jstr v

  let set_inline_style ?(important = false) p v e =
    let priority = if important then Jstr.v "important" else Jstr.empty in
    let style = Jv.get e "style" in
    if Jv.is_none style then () else
    (ignore @@
     Jv.call style "setProperty" Jv.[|of_jstr p; of_jstr v; of_jstr priority|])

  let remove_inline_style p e =
    let style = Jv.get e "style" in
    if Jv.is_none style then () else
    (ignore @@ Jv.call style "removeProperty" Jv.[|of_jstr p|])

  (* Layout *)

  let inner_x e = Jv.Float.get e "clientLeft"
  let inner_y e = Jv.Float.get e "clientTop"
  let inner_w e = Jv.Float.get e "clientWidth"
  let inner_h e = Jv.Float.get e "clientHeight"
  let bound_x e = Jv.Float.get (Jv.call e "getBoundingClientRect" [||]) "x"
  let bound_y e = Jv.Float.get (Jv.call e "getBoundingClientRect" [||]) "y"
  let bound_w e = Jv.Float.get (Jv.call e "getBoundingClientRect" [||]) "width"
  let bound_h e = Jv.Float.get (Jv.call e "getBoundingClientRect" [||]) "height"

  (* Offset *)

  let offset_w e = Jv.Int.get e "offsetWidth"
  let offset_h e = Jv.Int.get e "offsetHeight"

  let offset_left e = Jv.Int.get e "offsetLeft"
  let offset_top e = Jv.Int.get e "offsetTop"

  let offset_parent e = Jv.get e "offsetParent" |> Jv.to_option of_jv

  (* Scrolling *)

  let scroll_x e = Jv.Float.get e "scrollLeft"
  let scroll_y e = Jv.Float.get e "scrollTop"
  let scroll_w e = Jv.Float.get e "scrollWidth"
  let scroll_h e = Jv.Float.get e "scrollHeight"

  let scroll_into_view ?(align_v = `Start) ?behavior e =
    let align = match align_v with
      | `Start -> "start"
      | `Center -> "center"
      | `Nearest -> "nearest"
      | `End -> "end"
    in
    let behavior =
      Jv.of_option ~none:Jv.null Jv.of_string @@
        Option.map (function
            | `Smooth -> "smooth"
            | `Instant -> "instant"
            | `Auto -> "auto")
          behavior
    in
    let options = Jv.obj [|"block", Jv.of_string align; "behavior" , behavior |] in
    ignore @@ Jv.call e "scrollIntoView" [| options |]

  (* Focus *)

  let has_focus e =
    match Jv.to_option Fun.id (Jv.get (document e) "activeElement") with
    | None -> false | Some e' -> e == e'

  let set_has_focus b e =
    ignore (if b then Jv.call e "focus" [||] else Jv.call e "blur" [||])

  (* Pointer locking *)

  let is_locking_pointer e =
    match Jv.to_option Fun.id (Jv.get (document e) "pointerLockElement") with
    | None -> false | Some e' -> e == e'

  let request_pointer_lock e =
    let fut, set = Fut.create () in
    let d = (Obj.magic document e : Ev.target) in
    let opts = Ev.listen_opts ~once:true () in
    let unlisten = ref (fun () -> ()) in
    let locked _ev = set (Ok ()); !unlisten ()
    and error _ev =
      let err = Jv.Error.v (Jstr.v "Could not lock pointer") in
      set (Error err); !unlisten ()
    in
    let k = Ev.listen ~opts Ev.pointerlockchange locked d in
    let k' = Ev.listen ~opts Ev.pointerlockerror error d in
    unlisten := (fun () -> Ev.unlisten k; Ev.unlisten k');
    ignore @@ Jv.call e "requestPointerLock" [||];
    fut

  (* Click simluation *)

  let click e = ignore (Jv.call e "click" [||])
  let select_text e = ignore (Jv.call e "select" [||])

  (* Fullscreen *)

  module Navigation_ui = struct
    type t = Jstr.t
    let auto = Jstr.v "auto"
    let hide = Jstr.v "hide"
    let show = Jstr.v "show"
  end

  type fullscreen_opts = Jv.t
  let fullscreen_opts ?navigation_ui () =
    let o = Jv.obj [||] in
    Jv.Jstr.set_if_some o "navigationUI" navigation_ui;
    o

  let request_fullscreen ?(opts = Jv.obj [||]) e =
    Fut.of_promise ~ok:ignore @@ Jv.call e "requestFullscreen" [| opts |]

  (* Input *)

  module Input = struct
    let files e = match Jv.find e "files" with
    | None -> [] | Some files -> Jv.to_list File.of_jv files
  end

  (* Element tag names *)

  module Name = struct
    let a = Jstr.v "a"
    let abbr = Jstr.v "abbr"
    let address = Jstr.v "address"
    let area = Jstr.v "area"
    let article = Jstr.v "article"
    let aside = Jstr.v "aside"
    let audio = Jstr.v "audio"
    let b = Jstr.v "b"
    let base = Jstr.v "base"
    let bdi = Jstr.v "bdi"
    let bdo = Jstr.v "bdo"
    let blockquote = Jstr.v "blockquote"
    let body = Jstr.v "body"
    let br = Jstr.v "br"
    let button = Jstr.v "button"
    let canvas = Jstr.v "canvas"
    let caption = Jstr.v "caption"
    let cite = Jstr.v "cite"
    let code = Jstr.v "code"
    let col = Jstr.v "col"
    let colgroup = Jstr.v "colgroup"
    let command = Jstr.v "command"
    let datalist = Jstr.v "datalist"
    let dd = Jstr.v "dd"
    let del = Jstr.v "del"
    let details = Jstr.v "details"
    let dfn = Jstr.v "dfn"
    let div = Jstr.v "div"
    let dl = Jstr.v "dl"
    let dt = Jstr.v "dt"
    let em = Jstr.v "em"
    let embed = Jstr.v "embed"
    let fieldset = Jstr.v "fieldset"
    let figcaption = Jstr.v "figcaption"
    let figure = Jstr.v "figure"
    let footer = Jstr.v "footer"
    let form = Jstr.v "form"
    let h1 = Jstr.v "h1"
    let h2 = Jstr.v "h2"
    let h3 = Jstr.v "h3"
    let h4 = Jstr.v "h4"
    let h5 = Jstr.v "h5"
    let h6 = Jstr.v "h6"
    let head = Jstr.v "head"
    let header = Jstr.v "header"
    let hgroup = Jstr.v "hgroup"
    let hr = Jstr.v "hr"
    let html = Jstr.v "html"
    let i = Jstr.v "i"
    let iframe = Jstr.v "iframe"
    let img = Jstr.v "img"
    let input = Jstr.v "input"
    let ins = Jstr.v "ins"
    let kbd = Jstr.v "kbd"
    let keygen = Jstr.v "keygen"
    let label = Jstr.v "label"
    let legend = Jstr.v "legend"
    let li = Jstr.v "li"
    let link = Jstr.v "link"
    let map = Jstr.v "map"
    let mark = Jstr.v "mark"
    let menu = Jstr.v "menu"
    let meta = Jstr.v "meta"
    let meter = Jstr.v "meter"
    let nav = Jstr.v "nav"
    let noscript = Jstr.v "noscript"
    let object' = Jstr.v "object"
    let ol = Jstr.v "ol"
    let optgroup = Jstr.v "optgroup"
    let option = Jstr.v "option"
    let output = Jstr.v "output"
    let p = Jstr.v "p"
    let param = Jstr.v "param"
    let pre = Jstr.v "pre"
    let progress = Jstr.v "progress"
    let q = Jstr.v "q"
    let rp = Jstr.v "rp"
    let rt = Jstr.v "rt"
    let ruby = Jstr.v "ruby"
    let s = Jstr.v "s"
    let samp = Jstr.v "samp"
    let script = Jstr.v "script"
    let section = Jstr.v "section"
    let select = Jstr.v "select"
    let small = Jstr.v "small"
    let source = Jstr.v "source"
    let span = Jstr.v "span"
    let strong = Jstr.v "strong"
    let style = Jstr.v "style"
    let sub = Jstr.v "sub"
    let summary = Jstr.v "summary"
    let sup = Jstr.v "sup"
    let table = Jstr.v "table"
    let tbody = Jstr.v "tbody"
    let td = Jstr.v "td"
    let textarea = Jstr.v "textarea"
    let tfoot = Jstr.v "tfoot"
    let th = Jstr.v "th"
    let thead = Jstr.v "thead"
    let time = Jstr.v "time"
    let title = Jstr.v "title"
    let tr = Jstr.v "tr"
    let track = Jstr.v "track"
    let u = Jstr.v "u"
    let ul = Jstr.v "ul"
    let var = Jstr.v "var"
    let video = Jstr.v "video"
    let wbr = Jstr.v "wbr"
  end

  type cons =  ?d:document -> ?at:At.t list -> t list -> t
  type void_cons = ?d:document -> ?at:At.t list -> unit -> t
  let cons name ?d ?at cs = v ?d ?at name cs
  let void_cons name ?d ?at () = v ?d ?at name []

  let a = cons Name.a
  let abbr = cons Name.abbr
  let address = cons Name.address
  let area = void_cons Name.area
  let article = cons Name.article
  let aside = cons Name.aside
  let audio = cons Name.audio
  let b = cons Name.b
  let base = void_cons Name.base
  let bdi = cons Name.bdi
  let bdo = cons Name.bdo
  let blockquote = cons Name.blockquote
  let body = cons Name.body
  let br = void_cons Name.br
  let button = cons Name.button
  let canvas = cons Name.canvas
  let caption = cons Name.caption
  let cite = cons Name.cite
  let code = cons Name.code
  let col = void_cons Name.col
  let colgroup = cons Name.colgroup
  let command = cons Name.command
  let datalist = cons Name.datalist
  let dd = cons Name.dd
  let del = cons Name.del
  let details = cons Name.details
  let dfn = cons Name.dfn
  let div = cons Name.div
  let dl = cons Name.dl
  let dt = cons Name.dt
  let em = cons Name.em
  let embed = void_cons Name.embed
  let fieldset = cons Name.fieldset
  let figcaption = cons Name.figcaption
  let figure = cons Name.figure
  let footer = cons Name.footer
  let form = cons Name.form
  let h1 = cons Name.h1
  let h2 = cons Name.h2
  let h3 = cons Name.h3
  let h4 = cons Name.h4
  let h5 = cons Name.h5
  let h6 = cons Name.h6
  let head = cons Name.head
  let header = cons Name.header
  let hgroup = cons Name.hgroup
  let hr = void_cons Name.hr
  let html = cons Name.html
  let i = cons Name.i
  let iframe = cons Name.iframe
  let img = void_cons Name.img
  let input = void_cons Name.input
  let ins = cons Name.ins
  let kbd = cons Name.kbd
  let keygen = cons Name.keygen
  let label = cons Name.label
  let legend = cons Name.legend
  let li = cons Name.li
  let link = void_cons Name.link
  let map = cons Name.map
  let mark = cons Name.mark
  let menu = cons Name.menu
  let meta = void_cons Name.meta
  let meter = cons Name.meter
  let nav = cons Name.nav
  let noscript = cons Name.noscript
  let object' = cons Name.object'
  let ol = cons Name.ol
  let optgroup = cons Name.optgroup
  let option = cons Name.option
  let output = cons Name.output
  let p = cons Name.p
  let param = void_cons Name.param
  let pre = cons Name.pre
  let progress = cons Name.progress
  let q = cons Name.q
  let rp = cons Name.rp
  let rt = cons Name.rt
  let ruby = cons Name.ruby
  let s = cons Name.s
  let samp = cons Name.samp
  let script = cons Name.script
  let section = cons Name.section
  let select = cons Name.select
  let small = cons Name.small
  let source = void_cons Name.source
  let span = cons Name.span
  let strong = cons Name.strong
  let style = cons Name.style
  let sub = cons Name.sub
  let summary = cons Name.summary
  let sup = cons Name.sup
  let table = cons Name.table
  let tbody = cons Name.tbody
  let td = cons Name.td
  let textarea = cons Name.textarea
  let tfoot = cons Name.tfoot
  let th = cons Name.th
  let thead = cons Name.thead
  let time = cons Name.time
  let title = cons Name.title
  let tr = cons Name.tr
  let track = void_cons Name.track
  let u = cons Name.u
  let ul = cons Name.ul
  let var = cons Name.var
  let video = cons Name.video
  let wbr = void_cons Name.wbr
end

module Document = struct
  type t = El.document
  include (Jv.Id : Jv.CONV with type t := t)

  let as_target d = d

  (* Elements *)

  let root d = El.of_jv (Jv.get d "documentElement")
  let body d =
    let b = Jv.get d "body" in
    if Jv.is_some b then El.of_jv b else
    let err = "Document body is null. Try to defer your script execution."  in
    Jv.throw (Jstr.v err)

  let head d = El.of_jv (Jv.get d "head")
  let active_el d = Jv.to_option El.of_jv (Jv.get d "activeElement")

  let find_el_by_id d id =
    Jv.to_option El.of_jv (Jv.call d "getElementById" [| Jv.of_jstr id |])

  let find_els_by_name d n =
    El.el_list_of_node_list (Jv.call d "getElementsByName" [| Jv.of_jstr n |])

  (* Properties *)

  let referrer d = Jv.Jstr.get d "referrer"
  let title d = Jv.Jstr.get d "title"
  let set_title d t = Jv.Jstr.set d "title" t

  module Visibility_state = struct
    type t = Jstr.t
    let hidden = Jstr.v "hidden"
    let visible = Jstr.v "visible"
  end

  let visibility_state d = Jv.Jstr.get d "visibilityState"

  (* Pointer lock *)

  let pointer_lock_element d =
    Jv.to_option El.of_jv @@ Jv.get d "pointerLockElement"

  let exit_pointer_lock d =
    let fut = Ev.next Ev.pointerlockchange (as_target d) in
    ignore @@ Jv.call d "exitPointerLock" [||];
    fut

  (* Fullscreen *)

  let fullscreen_available d = Jv.Bool.get d "fullscreenEnabled"
  let fullscreen_element d =
    Jv.to_option El.of_jv @@ Jv.get d "fullscreenElement"

  let exit_fullscreen d =
    Fut.of_promise ~ok:ignore @@ Jv.call d "exitFullscreen" [||]
end

(* Browser interaction *)

module Abort = struct
  module Signal = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    external as_target : t -> Ev.target = "%identity"
    let aborted s = Jv.Bool.get s "aborted"
    let abort = Ev.Type.void (Jstr.v "abort")
  end
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
  let controller () = Jv.new' (Jv.get Jv.global "AbortController") [||]
  let signal c = Signal.of_jv (Jv.get c "signal")
  let abort c = ignore @@ Jv.call c "abort" [||]
end

module Console = struct
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
  let call c meth args = ignore (Jv.call c meth args)

  let c = ref (Jv.get Jv.global "console")
  let get () = !c
  let set n = c := n
  let clear () = call !c "clear" [||]

  (* Log functions *)

  type msg = [] : msg | ( :: ) : 'a * msg -> msg
  type 'a msgr = 'a -> msg
  let msg v = [v]
  let str v =
    let v = Jv.repr v in
    if Jv.is_null v then Jstr.v "null" else
    if Jv.is_undefined v then Jstr.v "undefined" else
    Jv.to_jstr @@ Jv.call v "toString" [||]

  let msg_to_jv_array msg =
    let rec loop a i = function
    | [] -> a
    | v :: vs -> Jv.Jarray.set a i (Jv.repr v); loop a (i + 1) vs
    in
    Jv.to_jv_array @@ loop (Jv.Jarray.create 0) 0 msg

  type log = msg -> unit

  (* Levelled logging *)

  let log msg = call !c "log" (msg_to_jv_array msg)
  let trace msg = call !c "trace" (msg_to_jv_array msg)
  let error msg = call !c "error" (msg_to_jv_array msg)
  let warn msg = call !c "warn" (msg_to_jv_array msg)
  let info msg = call !c "info" (msg_to_jv_array msg)
  let debug msg = call !c "debug" (msg_to_jv_array msg)

  (* Asserting and dumping *)

  let assert' b msg = call !c "assert" (msg_to_jv_array (Jv.of_bool b :: msg))
  let dir o = call !c "dir" [|Jv.repr o|]
  let table ?cols v =
    let msg = match cols with
    | None -> [|Jv.repr v|] | Some l -> [|Jv.repr v; Jv.of_jstr_list l|]
    in
    call !c "table" msg

  (* Grouping *)

  let group_end () = call !c "groupEnd" [||]
  let group ?(closed = false) msg = match closed with
  | false -> call !c "group" (msg_to_jv_array msg)
  | true -> call !c "groupCollapsed" (msg_to_jv_array msg)

  (* Counting *)

  let count label = call !c "count" [|Jv.of_jstr label|]
  let count_reset label = call !c "countReset" [|Jv.of_jstr label|]

  (* Timing *)

  let time label = call !c "time" [| Jv.of_jstr label |]
  let time_log label msg = call !c "timeLog" (msg_to_jv_array (label :: msg))
  let time_end label = call !c "timeEnd" [| Jv.of_jstr label |]

  (* Profiling *)

  let profile label = call !c "profile" [|Jv.repr label|]
  let profile_end label = call !c "profileEnd" [|Jv.repr label|]
  let time_stamp label = call !c "timeStamp" [| Jv.of_jstr label |]

  (* Result logging *)

  let log_result ?(ok = fun v -> [v]) ?error:(err = fun e -> [str e]) r =
    (match r with Ok v -> log (ok v) | Error e -> error (err e));
    r

  let log_if_error ?(l = error) ?(error_msg = fun e -> [str e]) ~use = function
  | Ok v -> v | Error e -> l (error_msg e); use

  let log_if_error' ?l ?error_msg ~use r =
    Ok (log_if_error ?l ?error_msg ~use r)
end

module Window = struct
  type t = El.window
  include (Jv.Id : Jv.CONV with type t := t)

  let as_target w = Ev.target_of_jv w

  let closed w = Jv.Bool.get w "closed"
  let scroll_x w = Jv.Float.get w "scrollX"
  let scroll_y w = Jv.Float.get w "scrollY"

  let inner_width w = Jv.Int.get w "innerWidth"
  let inner_height w = Jv.Int.get w "innerHeight"

  let parent w =
    let p = Jv.get w "parent" in
    if p == w then None else Some p

  let post_message w ~msg =
    ignore @@ Jv.call w "postMessage" [| msg |]

  (* Media properties *)

  let device_pixel_ratio w = Jv.Float.get w "devicePixelRatio"
  let matches_media w s =
    let o = Jv.call w "matchMedia" [|Jv.of_jstr s|] in
    Jv.Bool.get o "matches"

  let prefers_dark_color_scheme w =
    matches_media w (Jstr.v "(prefers-color-scheme: dark)")

  (* Operations *)

  let open' ?(features = Jstr.empty) ?(name = Jstr.empty) w u =
    Jv.to_option of_jv @@
      Jv.call w "open" [|Jv.of_jstr u; Jv.of_jstr name; Jv.of_jstr features|]

  let close w = ignore (Jv.call w "close" [||])
  let print w = ignore (Jv.call w "print" [||])
  let reload w = ignore (Jv.call (Jv.get w "location") "reload" [||])

  (* Location and history *)

  let location w = Jv.new' Uri.url [| Jv.get w "location" |]
  let set_location w u = Jv.set w "location" (Uri.to_jv u)

  module History = struct
    module Scroll_restoration = struct
      type t = Jstr.t
      let auto = Jstr.v "auto"
      let manual = Jstr.v "manual"
    end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let length h = Jv.Int.get h "length"
    let scroll_restoration h = Jv.Jstr.get h "scrollRestoration"
    let set_scroll_restoration h r = Jv.Jstr.set h "scrollRestoration" r

    (* Moving in history *)

    let back h = ignore @@ Jv.call h "back" [||]
    let forward h = ignore @@ Jv.call h "forward" [||]
    let go h d = ignore @@ Jv.call h "go" Jv.[| of_int d |]

    (* Making history *)

    type state = Jv.t
    let state h = Jv.get h "state"
    let push_state ?(state = Jv.null) ?(title = Jstr.empty) ?(uri = Jv.null) h =
      ignore @@ Jv.call h "pushState" [|state; Jv.of_jstr title; uri|]

    let replace_state
        ?(state = Jv.null) ?(title = Jstr.empty) ?(uri = Jv.null) h
      =
      ignore @@ Jv.call h "replaceState" [|state; Jv.of_jstr title; uri|]

    (* Event *)

    module Ev = struct
      module Popstate = struct
        type t = Jv.t
        let state e = Jv.get e "state"
      end
      let popstate = Ev.Type.create (Jstr.v "popstate")
    end
  end

  let history w = History.of_jv @@ Jv.get w "history"
end

module Navigator = struct
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)

  let languages n = match Jv.find n "languages" with
  | Some a -> Jv.to_jstr_list a
  | None ->
      match Jv.Jstr.find n "language" with
      | Some v -> [v] | None -> []

  let max_touch_points n =
    let t = Jv.get n "maxTouchPoints" in
    if Jv.is_none t then 0 else Jv.to_int t

  let online n = Jv.Bool.get n "onLine"
end

module Performance = struct
  module Entry = struct
    module Type = struct
      type t = Jstr.t
      let frame = Jstr.v "frame"
      let navigation = Jstr.v "navigation"
      let resource = Jstr.v "resource"
      let mark = Jstr.v "mark"
      let measure = Jstr.v "measure"
      let paint = Jstr.v "paint"
      let longtask = Jstr.v "longtask"
    end
    type t = Jv.t
    type entry = t
    include (Jv.Id : Jv.CONV with type t := t)
    let name e = Jv.Jstr.get e "name"
    let type' e = Jv.Jstr.get e "entryType"
    let start_time e = Jv.Float.get e "startTime"
    let end_time e = Jv.Float.get e "endTime"
    let duration e = Jv.Float.get e "duration"
    let to_json e = Jv.call e "toJSON" [||]

    module Resource_timing = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let as_entry = Fun.id
      let initiator_type e = Jv.Jstr.get e "initiatorType"
      let next_hop_protocol e = Jv.Jstr.get e "nextHopProtocol"
      let worker_start e = Jv.Float.get e "workerStart"
      let redirect_start e = Jv.Float.get e "redirectStart"
      let redirect_end e = Jv.Float.get e "redirectEnd"
      let fetch_start e = Jv.Float.get e "fetchStart"
      let domain_lookup_start e = Jv.Float.get e "domainLookupStart"
      let domain_lookup_end e = Jv.Float.get e "domainLookupEnd"
      let connect_start e = Jv.Float.get e "connectStart"
      let connect_end e = Jv.Float.get e "connectEnd"
      let secure_connection_start e = Jv.Float.get e "secureConnectionStart"
      let request_start e = Jv.Float.get e "requestStart"
      let response_start e = Jv.Float.get e "responseStart"
      let response_end e = Jv.Float.get e "responseEnd"
      let transfer_size e = Jv.Int.get e "transferSize"
      let encoded_body_size e = Jv.Int.get e "encodedBodySize"
      let decoded_body_size e = Jv.Int.get e "decodedBodySize"
    end
    module Navigation_timing = struct
      module Type =  struct
        type t = Jstr.t
        let navigate = Jstr.v "navigate"
        let reload = Jstr.v "reload"
        let back_forward = Jstr.v "back_forward"
        let prerender = Jstr.v "prerender"
      end
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)

      let as_resource_timing = Fun.id
      let as_entry = Fun.id
      let unload_event_start e = Jv.Float.get e "unloadEventStart"
      let unload_event_end e = Jv.Float.get e "unloadEventEnd"
      let dom_interactive e = Jv.Float.get e "domInteractive"
      let dom_content_loaded_event_start e =
        Jv.Float.get e "domContentLoadedEventStart"

      let dom_content_loaded_event_end e =
        Jv.Float.get e "domContentLoadedEventEnd"

      let dom_complete e = Jv.Float.get e "domComplete"
      let load_event_start e = Jv.Float.get e "loadEventStart"
      let load_event_end e = Jv.Float.get e "loadEventEnd"
      let type' e = Jv.Jstr.get e "type'"
      let redirect_count e = Jv.Int.get e "redirectCount"
    end
    let as_resource_timing = Fun.id
    let as_navigation_timing = Fun.id
  end

  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)

  let time_origin_ms p = Jv.Float.get p "timeOrigin"
  let clear_marks p n =
    let args = match n with None -> [||] | Some n -> Jv.[|of_jstr n |] in
    ignore @@ Jv.call p "clearMarks" args

  let clear_measures p n =
    let args = match n with None -> [||] | Some n -> Jv.[|of_jstr n |] in
    ignore @@ Jv.call p "clearMeasures" args

  let clear_resource_timings p = ignore @@ Jv.call p "clearResourceTimings" [||]
  let get_entries ?type' ?name p = match name, type' with
  | None, None ->
      Jv.to_list Entry.of_jv @@ Jv.call p "getEntries" [||]
  | None, Some t ->
      Jv.to_list Entry.of_jv @@ Jv.call p "getEntriesByType" Jv.[| of_jstr t |]
  | Some n, None ->
      Jv.to_list Entry.of_jv @@ Jv.call p "getEntriesByName" Jv.[| of_jstr n |]
  | Some n, Some t ->
      Jv.to_list Entry.of_jv @@ Jv.call p "getEntriesByName"
        Jv.[| of_jstr n; of_jstr t |]

  let mark p n = ignore @@ Jv.call p "mark" Jv.[| of_jstr n |]
  let measure ?start ?stop p _n = match start, stop with
  | None, None -> ignore @@ Jv.call p "measure" [||]
  | Some s, None -> ignore @@ Jv.call p "measure" Jv.[| of_jstr s|]
  | Some s, Some e -> ignore @@ Jv.call p "measure" Jv.[| of_jstr s; of_jstr e|]
  | None, Some e -> ignore @@ Jv.call p "measure" Jv.[| undefined; of_jstr e|]

  let now_ms p = Jv.to_float @@ Jv.call p "now" [||]
  let to_json p = Jv.call p "toJSON" [||]
end

module G = struct

  (* Global objects *)

  let console = Jv.get Jv.global "console"
  let document = El.global_document
  let navigator = Jv.get Jv.global "navigator"
  let performance = Jv.get Jv.global "performance"
  let window = Jv.get Jv.global "window"

  (* Global properties *)

  let is_secure_context = Jv.Bool.get Jv.global "isSecureContext"

  (* Event target *)

  let target = Jv.global

  (* Timers *)

  type timer_id = int

  let set_timeout ~ms f =
    Jv.to_int @@
    Jv.call Jv.global "setTimeout" [| Jv.callback ~arity:1 f; Jv.of_int ms |]

  let set_interval ~ms f =
    Jv.to_int @@
    Jv.call Jv.global "setInterval" [| Jv.callback ~arity:1 f; Jv.of_int ms |]

  let stop_timer tid =
    (* according to spec interval and timeout share the same ints *)
    ignore @@ Jv.call Jv.global "clearTimeout" [| Jv.of_int tid |]

  (* Animation timing *)

  type animation_frame_id = int

  let request_animation_frame f =
    Jv.to_int @@ Jv.call Jv.global "requestAnimationFrame"
      [|Jv.callback ~arity:1 f|]

  let cancel_animation_frame fid =
    ignore @@ Jv.call Jv.global "cancelAnimationFrame" [| Jv.of_int fid|]
end

module ResizeObserver = struct

  module Entry = struct
    type t = Jv.t

    let target v = Jv.get v "target"

    include (Jv.Id : Jv.CONV with type t := t)
  end

  type observer = Jv.t

  let create : (Entry.t list -> observer -> unit) -> observer =
    fun callback ->
    let callback e o =
      let e = Jv.to_list Entry.of_jv e in
      callback e o
    in
    let callback = Jv.callback ~arity:2 callback in
    let constructor = Jv.get Jv.global "ResizeObserver" in
    Jv.new' constructor [| callback |]

  let observe : observer -> El.t -> unit =
    fun observer target ->
    ignore @@ Jv.call observer "observe" [| target |]

  let unobserve : observer -> El.t -> unit =
    fun observer target ->
    ignore @@ Jv.call observer "unobserve" [| target |]

  let disconnect : observer -> unit =
    fun observer ->
    ignore @@ Jv.call observer "disconnect" [| |]

  include (Jv.Id : Jv.CONV with type t := observer)
end
