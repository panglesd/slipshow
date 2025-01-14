let all_paths = ref []
let is_pressed = ( != ) 0

type drawing_state =
  | Drawing of (float * float) list * Brr.El.t
  | Erasing of float * float
  | Pointing

let current_drawing_state = ref Pointing

module Color = struct
  type t = Red | Blue | Green | Black | Yellow

  let to_string = function
    | Red -> "red"
    | Blue -> "blue"
    | Green -> "green"
    | Black -> "black"
    | Yellow -> "yellow"
end

module Width = struct
  type t = Small | Medium | Large

  let to_string = function Small -> "1" | Medium -> "3" | Large -> "5"
end

module Tool = struct
  type t = Pen | Highlighter | Eraser | Pointer

  let to_string = function
    | Pen -> "pen"
    | Highlighter -> "highlighter"
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
end

module State : sig
  type t = { color : Color.t; width : Width.t; tool : Tool.t }

  val get_state : unit -> t
  val set_color : Color.t -> unit
  val set_width : Width.t -> unit
  val set_tool : Tool.t -> unit
end = struct
  type t = { color : Color.t; width : Width.t; tool : Tool.t }

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
    Brr.El.set_class (Jstr.v "drawing") true body

  let make_inactive () =
    let body = Brr.Document.body Brr.G.document in
    Brr.El.set_class (Jstr.v "drawing") false body

  let set_tool t =
    let () =
      match t with
      | Tool.Pen | Highlighter | Eraser -> make_active ()
      | Pointer -> make_inactive ()
    in
    set_current Tool t
end

let svg_path path =
  let res =
    match path with
    | [] -> []
    | (x, y) :: rest ->
        Format.sprintf "M %f,%f" x y
        :: List.map (fun (x, y) -> Format.sprintf "L %f,%f" x y) rest
  in
  String.concat " " res

let coord_of_event ev =
  let mouse = Brr.Ev.as_type ev in
  let x = Brr.Ev.Mouse.client_x mouse and y = Brr.Ev.Mouse.client_y mouse in
  (x, y) |> Normalization.translate_coords |> Window.translate_coords

let check_is_pressed ev f =
  if is_pressed (ev |> Brr.Ev.as_type |> Brr.Ev.Mouse.buttons) then f () else ()

let do_if_drawing f =
  match State.get_state () with { tool = Pointer; _ } -> () | state -> f state

let handle_mouse_move ev =
  check_is_pressed ev @@ fun () ->
  do_if_drawing @@ fun { tool = _; _ } ->
  match !current_drawing_state with
  | Drawing (path, el) ->
      let path = coord_of_event ev :: path in
      current_drawing_state := Drawing (path, el);
      Brr.El.set_at (Jstr.v "d") (Some (Jstr.v (svg_path path))) el
  | Erasing _ -> ()
  | Pointing -> ()

let start_shape svg =
  do_if_drawing @@ fun { color; width; tool } ->
  let p = Brr.El.v ~ns:`SVG (Jstr.v "path") [] in
  let set_at at v = Brr.El.set_at (Jstr.v at) (Some (Jstr.v v)) p in
  (match tool with
  | Tool.Pen ->
      set_at "stroke" (Color.to_string color);
      set_at "stroke-width" (Width.to_string width);
      set_at "fill" "none";
      current_drawing_state := Drawing ([], p)
  | Highlighter ->
      set_at "stroke" (Color.to_string color);
      set_at "stroke-linecap" "round";
      set_at "stroke-width" (Width.to_string width ^ "0");
      set_at "opacity" (string_of_float 0.33);
      set_at "fill" "none";
      current_drawing_state := Drawing ([], p)
  | Eraser -> ()
  | Pointer -> ());
  Brr.El.append_children svg [ p ]

let end_shape () =
  do_if_drawing @@ fun _ ->
  (match !current_drawing_state with
  | Drawing (path, _) -> all_paths := path :: !all_paths
  | _ -> ());
  current_drawing_state := Pointing

let connect svg =
  let _mousemove =
    Brr.Ev.listen Brr.Ev.mousemove handle_mouse_move
      (Brr.Document.as_target Brr.G.document)
  in
  let _mousedown =
    Brr.Ev.listen Brr.Ev.mousedown
      (fun _x -> start_shape svg)
      (Brr.Document.as_target Brr.G.document)
  in
  let _mouseup =
    Brr.Ev.listen Brr.Ev.mouseup
      (fun _x -> end_shape ())
      (Brr.Document.as_target Brr.G.document)
  in
  ()

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
  let d = Brr.El.div [] in
  Jv.set (Brr.El.to_jv d) "innerHTML" (Jv.of_string content);
  Brr.El.append_children el [ d ];
  let svg =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing") |> Option.get
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
    add_listener State.set_tool Button.tool Pen;
    add_listener State.set_tool Button.tool Highlighter;
    add_listener State.set_tool Button.tool Eraser;
    add_listener State.set_tool Button.tool Pointer;
    add_listener State.set_color Button.color Black;
    add_listener State.set_color Button.color Blue;
    add_listener State.set_color Button.color Red;
    add_listener State.set_color Button.color Green;
    add_listener State.set_color Button.color Yellow;
    add_listener State.set_width Button.width Small;
    add_listener State.set_width Button.width Medium;
    add_listener State.set_width Button.width Large
  in
  let () =
    State.set_width Medium;
    State.set_color Blue;
    State.set_tool Pointer
  in
  let _listeners = connect svg in
  ()
