let get_id =
  let id_number = ref 0 in
  let window_name = Brr.Window.name Brr.G.window |> Jstr.to_string in
  let name = "__slipshow__" ^ window_name in
  fun () ->
    let i = !id_number in
    incr id_number;
    name ^ string_of_int i

let is_pressed = ( != ) 0

module Color = struct
  type t = Red | Blue | Green | Black | Yellow [@@deriving yojson]

  let to_string = function
    | Red -> "red"
    | Blue -> "blue"
    | Green -> "green"
    | Black -> "black"
    | Yellow -> "yellow"
end

module Width = struct
  type t = Small | Medium | Large [@@deriving yojson]
end

module Tool = struct
  type stroker = Pen | Highlighter [@@deriving yojson]
  type t = Stroker of stroker | Eraser | Pointer [@@deriving yojson]

  let to_string = function
    | Stroker Pen -> "pen"
    | Stroker Highlighter -> "highlighter"
    | Eraser -> "eraser"
    | Pointer -> "cursor"
end

module Button = struct
  let get suffix =
    Brr.El.find_first_by_selector (Jstr.v (".slip-toolbar-" ^ suffix))
    |> Option.get

  let tool t = get (Tool.to_string t)
  let color c = get (Color.to_string c)

  let width (w : Width.t) =
    let s = function
      | Width.Small -> "small"
      | Medium -> "medium"
      | Large -> "large"
    in
    get (s w)

  let clear () = get "clear"
end

module State : sig
  type t = { color : Color.t; width : Width.t; tool : Tool.t }

  val get_state : unit -> t
  val set_color : Color.t -> unit
  val set_width : Width.t -> unit
  val set_tool : Tool.t -> unit
  val get_tool : unit -> Tool.t
  val of_string : string -> t option
  val to_string : t -> string
end = struct
  type t = { color : Color.t; width : Width.t; tool : Tool.t }
  [@@deriving yojson]

  let of_string s =
    match Yojson.Safe.from_string s with
    | r -> of_yojson r
    | exception Yojson.Json_error e -> Error e

  let of_string s =
    match of_string s with
    | Ok s -> Some s
    | Error e ->
        Brr.Console.(log [ "Error when converting back a state:"; e ]);
        None

  let to_string v = v |> to_yojson |> Yojson.Safe.to_string
  let color = ref Color.Blue
  let width = ref Width.Medium
  let tool = ref Tool.Pointer
  let get_state () = { color = !color; width = !width; tool = !tool }

  type 'a kind =
    | Tool : Tool.t kind
    | Color : Color.t kind
    | Width : Width.t kind

  let selected_class (type a) = function
    | (Tool : a kind) -> "slip-set-tool"
    | Width -> "slip-set-width"
    | Color -> "slip-set-color"

  let button : type a. a kind -> a -> Brr.El.t = function
    | (Tool : a kind) -> Button.tool
    | Width -> Button.width
    | Color -> Button.color

  let state_ref : type a. a kind -> a ref = function
    | (Tool : a kind) -> tool
    | Width -> width
    | Color -> color

  let set_current kind e =
    let class_ = Jstr.v (selected_class kind) in
    Brr.El.find_by_class class_ |> List.iter (Brr.El.set_class class_ false);
    Brr.El.set_class class_ true (button kind e);
    state_ref kind := e

  let set_color c = set_current Color c
  let set_width w = set_current Width w

  let make_active () =
    let body = Brr.Document.body Brr.G.document in
    Brr.El.set_class (Jstr.v "slipshow-drawing-mode") true body

  let make_inactive () =
    let body = Brr.Document.body Brr.G.document in
    Brr.El.set_class (Jstr.v "slipshow-drawing-mode") false body

  let set_tool t =
    let () =
      match t with
      | Tool.Stroker _ | Eraser -> make_active ()
      | Pointer -> make_inactive ()
    in
    set_current Tool t

  let get_tool () = !tool
end

module Stroke = struct
  open Sexplib.Std

  type freehand_option = {
    size : float option;
    thinning : float option;
    smoothing : float option;
    streamline : float option;
    last : bool option;
  }
  [@@deriving yojson]

  let option_to_yojson v =
    let option =
      {
        size = Perfect_freehand.Options.size v;
        thinning = Perfect_freehand.Options.thinning v;
        smoothing = Perfect_freehand.Options.smoothing v;
        streamline = Perfect_freehand.Options.streamline v;
        last = Perfect_freehand.Options.last v;
      }
    in
    freehand_option_to_yojson option

  let option_of_yojson yojson =
    match freehand_option_of_yojson yojson with
    | Ok { size; thinning; smoothing; streamline; last } ->
        Ok
          (Perfect_freehand.Options.v ?size ?thinning ?smoothing ?streamline
             ?last ())
    | Error _ as e -> e

  type t = {
    id : string;
    path : (float * float) list;
    color : Color.t;
    opacity : float;
    options : Perfect_freehand.Options.t;
        [@to_yojson option_to_yojson] [@of_yojson option_of_yojson]
  }
  [@@deriving yojson]

  let of_string s =
    match Yojson.Safe.from_string s with
    | r -> of_yojson r
    | exception Yojson.Json_error e -> Error e

  let of_string s =
    match of_string s with
    | Ok s -> Some s
    | Error e ->
        Brr.Console.(log [ "Error when converting back a stroke:"; e ]);
        None

  let to_string v = v |> to_yojson |> Yojson.Safe.to_string

  module Db = struct
    type nonrec t = (string, Brr.El.t * t) Hashtbl.t
    (** The ID is the key. We include the element too to avoid having to query
        for it. *)

    let all : t = Hashtbl.create 10
  end
end

let remove elem =
  match Brr.El.at (Jstr.v "id") elem with
  | None -> Brr.El.remove elem
  | Some id ->
      let id = Jstr.to_string id in
      Hashtbl.remove Stroke.Db.all id;
      Brr.El.remove elem

type drawing_state =
  | Drawing of Brr.El.t * Stroke.t
  | Erasing of (float * float)
  | Pointing

let current_drawing_state = ref Pointing

let svg_path options path =
  let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
  let path =
    List.rev_map
      (fun (x, y) -> Perfect_freehand.Point.v (x *. scale) (y *. scale))
      path
  in
  let stroke = Perfect_freehand.get_stroke ~options path in
  let svg_path = Perfect_freehand.get_svg_path_from_stroke stroke in
  Jstr.to_string svg_path

let coord_of_event ev =
  let mouse = Brr.Ev.as_type ev |> Brr.Ev.Pointer.as_mouse in
  let x = Brr.Ev.Mouse.client_x mouse and y = Brr.Ev.Mouse.client_y mouse in
  (x, y) |> Normalization.translate_coords |> Universe.Window.translate_coords

let check_is_pressed ev f =
  if
    is_pressed
      (ev |> Brr.Ev.as_type |> Brr.Ev.Pointer.as_mouse |> Brr.Ev.Mouse.buttons)
  then f ()
  else ()

let do_if_drawing f =
  match State.get_state () with { tool = Pointer; _ } -> () | state -> f state

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

let close_enough_poly p coord =
  let close_enough (x1, y1) (x2, y2) =
    abs_float (x1 -. x2) < 10. && abs_float (y1 -. y2) < 10.
  in
  List.exists (fun p1 -> close_enough p1 coord) p

let continue_shape_func coord =
  match !current_drawing_state with
  | Drawing (el, stroke) ->
      let stroke = { stroke with path = coord :: stroke.path } in
      current_drawing_state := Drawing (el, stroke);
      Brr.El.set_at (Jstr.v "d")
        (Some (Jstr.v (svg_path stroke.options stroke.path)))
        el
  | Erasing last_point ->
      Hashtbl.iter
        (fun _id (elem, { Stroke.path; _ }) ->
          let intersect = intersect_poly path (coord, last_point) in
          let close_enough = close_enough_poly path coord in
          if intersect || close_enough then remove elem)
        Stroke.Db.all;
      current_drawing_state := Erasing coord;
      ()
  | Pointing -> ()

let continue_shape ev =
  check_is_pressed ev @@ fun () ->
  let coord = coord_of_event ev in
  continue_shape_func coord;
  Messaging.draw (Continue { coord })

let create_elem_of_stroke { Stroke.options; color; opacity; id; path } =
  let p = Brr.El.v ~ns:`SVG (Jstr.v "path") [] in
  let set_at at v = Brr.El.set_at (Jstr.v at) (Some (Jstr.v v)) p in
  set_at "fill" (Color.to_string color);
  set_at "id" id;
  let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
  let scale = 1. /. scale in
  Brr.El.set_inline_style (Jstr.v "transform")
    (Jstr.v @@ Format.sprintf "scale3d(%.10f,%.10f,%.10f)" scale scale scale)
    p;
  set_at "opacity" (string_of_float opacity);
  Brr.El.set_at (Jstr.v "d") (Some (Jstr.v (svg_path options path))) p;
  p

let options_of stroke width =
  let size =
    match (stroke, width) with
    | Tool.Pen, Width.Small -> 6.
    | Pen, Medium -> 10.
    | Pen, Large -> 14.
    | Highlighter, Small -> 28.
    | Highlighter, Medium -> 38.
    | Highlighter, Large -> 48.
  in
  Perfect_freehand.Options.v ~thinning:0.3 ~smoothing:0.5 ~size ~streamline:0.05
    ~last:false ()

let start_shape_func id ({ State.tool; _ } as state) coord =
  let svg =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
    |> Option.get
  in
  match tool with
  | Tool.Stroker stroker ->
      let opacity = match stroker with Tool.Highlighter -> 0.33 | Pen -> 1. in
      let path = [ coord ] in
      let options = options_of stroker state.width in
      let stroke = { Stroke.path; options; opacity; id; color = state.color } in
      let p = create_elem_of_stroke stroke in
      current_drawing_state := Drawing (p, stroke);
      Brr.El.append_children svg [ p ]
  | Eraser -> current_drawing_state := Erasing coord
  | Pointer -> ()

let start_shape _svg ev =
  do_if_drawing @@ fun state ->
  let id = get_id () in
  let coord = coord_of_event ev in
  start_shape_func id state coord;
  let state = state |> State.to_string in
  Messaging.draw (Start { state; id; coord })

let end_shape_func _attrs =
  (match !current_drawing_state with
  | Drawing (el, stroke) -> Hashtbl.add Stroke.Db.all stroke.id (el, stroke)
  | _ -> ());
  current_drawing_state := Pointing

let end_shape () =
  do_if_drawing @@ fun attrs ->
  let state = attrs |> State.to_string in
  Messaging.draw (End { state });
  end_shape_func attrs

let send_all_strokes () =
  let all_strokes =
    Hashtbl.fold
      (fun _ (_, stroke) acc -> Stroke.to_string stroke :: acc)
      Stroke.Db.all []
  in
  Messaging.send_all_strokes all_strokes

let receive_all_strokes all_strokes =
  List.iter
    (fun s ->
      match Stroke.of_string s with
      | None -> ()
      | Some stroke ->
          let el = create_elem_of_stroke stroke in
          Hashtbl.add Stroke.Db.all stroke.id (el, stroke);
          let svg =
            Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
            |> Option.get
          in
          Brr.El.append_children svg [ el ])
    all_strokes

let connect svg =
  let _mousemove =
    Brr.Ev.listen Brr.Ev.pointermove continue_shape
      (Brr.Document.as_target Brr.G.document)
  in
  let _pointerdown =
    Brr.Ev.listen Brr.Ev.pointerdown (start_shape svg)
      (Brr.Document.as_target Brr.G.document)
  in
  let _pointerup =
    Brr.Ev.listen Brr.Ev.pointerup
      (fun _x -> end_shape ())
      (Brr.Document.as_target Brr.G.document)
  in
  ()

let clear_func () = Hashtbl.iter (fun _ (elem, _) -> remove elem) Stroke.Db.all

let clear () =
  Messaging.draw Clear;
  clear_func ()

let setup el =
  let content =
    {|	  <div class="slip-writing-toolbar">
              <div class="slip-toolbar-tool no-tool">
                  <div class="slip-toolbar-pen">
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="20" height="20" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path class="clr-i-outline clr-i-outline-path-1" d="M33.87 8.32L28 2.42a2.07 2.07 0 0 0-2.92 0L4.27 23.2l-1.9 8.2a2.06 2.06 0 0 0 2 2.5a2.14 2.14 0 0 0 .43 0l8.29-1.9l20.78-20.76a2.07 2.07 0 0 0 0-2.92zM12.09 30.2l-7.77 1.63l1.77-7.62L21.66 8.7l6 6zM29 13.25l-6-6l3.48-3.46l5.9 6z" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>
                  </div>
                  <div class="slip-toolbar-highlighter">
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="25" height="25" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path d="M15.82 26.06a1 1 0 0 1-.71-.29l-6.44-6.44a1 1 0 0 1-.29-.71a1 1 0 0 1 .29-.71L23 3.54a5.55 5.55 0 1 1 7.85 7.86L16.53 25.77a1 1 0 0 1-.71.29zm-5-7.44l5 5L29.48 10a3.54 3.54 0 0 0 0-5a3.63 3.63 0 0 0-5 0z" class="clr-i-outline clr-i-outline-path-1" fill="#000000"/><path d="M10.38 28.28a1 1 0 0 1-.71-.28l-3.22-3.23a1 1 0 0 1-.22-1.09l2.22-5.44a1 1 0 0 1 1.63-.33l6.45 6.44A1 1 0 0 1 16.2 26l-5.44 2.22a1.33 1.33 0 0 1-.38.06zm-2.05-4.46l2.29 2.28l3.43-1.4l-4.31-4.31z" class="clr-i-outline clr-i-outline-path-2" fill="#000000"/><path d="M8.94 30h-5a1 1 0 0 1-.84-1.55l3.22-4.94a1 1 0 0 1 1.55-.16l3.21 3.22a1 1 0 0 1 .06 1.35L9.7 29.64a1 1 0 0 1-.76.36zm-3.16-2h2.69l.53-.66l-1.7-1.7z" class="clr-i-outline clr-i-outline-path-3" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>
</div>
                  <div class="slip-toolbar-eraser">
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="20" height="20" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path d="M35.62 12a2.82 2.82 0 0 0-.84-2l-7.29-7.35a2.9 2.9 0 0 0-4 0L2.83 23.28a2.84 2.84 0 0 0 0 4L7.53 32H3a1 1 0 0 0 0 2h25a1 1 0 0 0 0-2H16.74l18-18a2.82 2.82 0 0 0 .88-2zM13.91 32h-3.55l-6.11-6.11a.84.84 0 0 1 0-1.19l5.51-5.52l8.49 8.48zm19.46-19.46L19.66 26.25l-8.48-8.49l13.7-13.7a.86.86 0 0 1 1.19 0l7.3 7.29a.86.86 0 0 1 .25.6a.82.82 0 0 1-.25.59z" class="clr-i-outline clr-i-outline-path-1" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>
</div>
                  <div class="slip-toolbar-cursor">
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="20" height="20" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path class="clr-i-outline clr-i-outline-path-1" d="M14.58 32.31a1 1 0 0 1-.94-.65L4 5.65a1 1 0 0 1 1.25-1.28l26 9.68a1 1 0 0 1-.05 1.89l-8.36 2.57l8.3 8.3a1 1 0 0 1 0 1.41l-3.26 3.26a1 1 0 0 1-.71.29a1 1 0 0 1-.71-.29l-8.33-8.33l-2.6 8.45a1 1 0 0 1-.93.71zm3.09-12a1 1 0 0 1 .71.29l8.79 8.79L29 27.51l-8.76-8.76a1 1 0 0 1 .41-1.66l7.13-2.2L6.6 7l7.89 21.2l2.22-7.2a1 1 0 0 1 .71-.68z" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>
</div>
              </div>
              <div class="slip-toolbar-color">
                  <div class="slip-toolbar-black"></div>
                  <div class="slip-toolbar-blue"></div>
                  <div class="slip-toolbar-red"></div>
                  <div class="slip-toolbar-green"></div>
                  <div class="slip-toolbar-yellow"></div>
              </div>

              <div class="slip-toolbar-width">
                  <div class="slip-toolbar-small"><div></div></div>
                  <div class="slip-toolbar-medium"><div></div></div>
                  <div class="slip-toolbar-large"><div></div></div>
              </div>
              <div class="slip-toolbar-control">
                  <!-- <div class="slip-toolbar-stop">✓</div> -->
                  <div class="slip-toolbar-clear">✗</div>
              </div>
          </div> |}
  in
  let d = Brr.El.div ~at:[ Brr.At.id (Jstr.v "slipshow-drawing-toolbar") ] [] in
  Jv.set (Brr.El.to_jv d) "innerHTML" (Jv.of_string content);
  Brr.El.append_children el [ d ];
  let svg =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
    |> Option.get
  in
  let _ : unit Fut.t =
    let open Fut.Syntax in
    let+ () = Fut.tick ~ms:0 in
    let add_listener setter button value =
      ignore
      @@ Brr.Ev.listen Brr.Ev.click
           (fun _ -> setter value)
           (Brr.El.as_target (button value))
    in
    add_listener State.set_tool Button.tool (Stroker Pen);
    add_listener State.set_tool Button.tool (Stroker Highlighter);
    add_listener State.set_tool Button.tool Eraser;
    add_listener State.set_tool Button.tool Pointer;
    add_listener State.set_color Button.color Black;
    add_listener State.set_color Button.color Blue;
    add_listener State.set_color Button.color Red;
    add_listener State.set_color Button.color Green;
    add_listener State.set_color Button.color Yellow;
    add_listener State.set_width Button.width Small;
    add_listener State.set_width Button.width Medium;
    add_listener State.set_width Button.width Large;
    add_listener clear Button.clear ()
  in
  let () =
    State.set_width Medium;
    State.set_color Blue;
    State.set_tool Pointer
  in
  let _listeners = connect svg in
  ()
