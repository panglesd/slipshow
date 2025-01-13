let current_path = ref []
let current_el = ref None
let is_pressed = ( != ) 0

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

module State : sig
  type tool = Pen | Highlighter | Eraser | Pointer
  type t = { color : Color.t; width : Width.t; tool : tool }

  val get_state : unit -> t
  val set_color : Color.t -> unit
  val set_width : Width.t -> unit
  val set_tool : tool -> unit
end = struct
  type tool = Pen | Highlighter | Eraser | Pointer
  type t = { color : Color.t; width : Width.t; tool : tool }

  let color = ref Color.Blue
  let width = ref Width.Medium
  let tool = ref Pointer
  let get_state () = { color = !color; width = !width; tool = !tool }

  let set_color c =
    Brr.Console.(log [ "yyyyyyyyyyyyyyyyyyyyyyyyy"; Color.to_string c ]);
    color := c

  let set_width w = width := w

  let make_active () =
    let open_windows =
      Brr.El.find_first_by_selector (Jstr.v "#open-window") |> Option.get
    in
    let toolbar =
      Brr.El.find_first_by_selector (Jstr.v ".slip-writing-toolbar")
      |> Option.get
    in
    Brr.El.set_class (Jstr.v "active") true toolbar;
    Brr.El.set_inline_style (Jstr.v "pointer-events") (Jstr.v "none")
      open_windows

  let make_inactive () =
    let open_window =
      Brr.El.find_first_by_selector (Jstr.v "#open-window") |> Option.get
    in
    let toolbar =
      Brr.El.find_first_by_selector (Jstr.v ".slip-writing-toolbar")
      |> Option.get
    in
    Brr.El.set_class (Jstr.v "active") false toolbar;
    Brr.El.set_inline_style (Jstr.v "pointer-events") (Jstr.v "") open_window

  let select s =
    let tool =
      Brr.El.find_first_by_selector (Jstr.v (".slip-toolbar-" ^ s))
      |> Option.get
    in
    Brr.El.fold_find_by_selector
      (fun e () -> Brr.El.set_class (Jstr.v "slip-set-tool") false e)
      (Jstr.v ".slip-set-tool") ();
    Brr.El.set_class (Jstr.v "slip-set-tool") true tool

  let set_tool t =
    let () =
      match t with
      | Pen | Highlighter | Eraser -> make_active ()
      | Pointer -> make_inactive ()
    in
    let () =
      match t with
      | Pen -> select "pen"
      | Highlighter -> select "highlighter"
      | Eraser -> select "eraser"
      | Pointer -> select "cursor"
    in
    tool := t
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

let extend_shape x = current_path := x :: !current_path

let check_is_pressed ev f =
  if is_pressed (ev |> Brr.Ev.as_type |> Brr.Ev.Mouse.buttons) then f () else ()

let do_if_drawing f =
  match State.get_state () with { tool = Pointer; _ } -> () | state -> f state

let handle_mouse_move ev =
  do_if_drawing @@ fun _ ->
  Brr.Console.(log [ coord_of_event ev ]);
  check_is_pressed ev @@ fun () ->
  extend_shape (coord_of_event ev);
  match !current_el with
  | None -> ()
  | Some el ->
      Brr.El.set_at (Jstr.v "d") (Some (Jstr.v (svg_path !current_path))) el

type t = {
  mousemove : Brr.Ev.listener;
  mousedown : Brr.Ev.listener;
  mouseup : Brr.Ev.listener;
}

let start_shape svg =
  do_if_drawing @@ fun { color; width; tool = _ } ->
  Brr.Console.(log [ "coolor is "; Color.to_string color ]);
  let p = Brr.El.v ~ns:`SVG (Jstr.v "path") [] in
  Brr.El.set_at (Jstr.v "stroke") (Some (Jstr.v (Color.to_string color))) p;
  Brr.El.set_at (Jstr.v "stroke-width")
    (Some (Jstr.v (Width.to_string width)))
    p;
  Brr.El.set_at (Jstr.v "fill") (Some (Jstr.v "none")) p;
  current_el := Some p;
  current_path := [];
  Brr.El.append_children svg [ p ]

let end_shape () =
  do_if_drawing @@ fun _ ->
  current_el := None;
  current_path := []

let connect svg =
  let mousemove =
    Brr.Ev.listen Brr.Ev.mousemove handle_mouse_move
      (Brr.Document.as_target Brr.G.document)
  in
  let mousedown =
    Brr.Ev.listen Brr.Ev.mousedown
      (fun _x ->
        Brr.Console.(log [ "mouse down" ]);
        start_shape svg)
      (Brr.Document.as_target Brr.G.document)
  in
  let mouseup =
    Brr.Ev.listen Brr.Ev.mouseup
      (fun _x ->
        Brr.Console.(log [ "mouse up" ]);
        end_shape ())
      (Brr.Document.as_target Brr.G.document)
  in
  { mousemove; mousedown; mouseup }

let disconnect { mousemove; mousedown; mouseup } =
  Brr.Ev.unlisten mousemove;
  Brr.Ev.unlisten mousedown;
  Brr.Ev.unlisten mouseup

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
  (* let universe = *)
  (*   Brr.El.find_first_by_selector (Jstr.v "#universe") |> Option.get *)
  (* in *)
  let _ : unit Fut.t =
    let open Fut.Syntax in
    let+ () = Fut.tick ~ms:0 in
    let pen =
      Brr.El.find_first_by_selector (Jstr.v ".slip-toolbar-pen") |> Option.get
    in
    let cursor =
      Brr.El.find_first_by_selector (Jstr.v ".slip-toolbar-cursor")
      |> Option.get
    in
    let highlighter =
      Brr.El.find_first_by_selector (Jstr.v ".slip-toolbar-highlighter")
      |> Option.get
    in
    let eraser =
      Brr.El.find_first_by_selector (Jstr.v ".slip-toolbar-eraser")
      |> Option.get
    in
    let black =
      Brr.El.find_first_by_selector (Jstr.v ".slip-toolbar-black") |> Option.get
    in
    let blue =
      Brr.El.find_first_by_selector (Jstr.v ".slip-toolbar-blue") |> Option.get
    in
    let red =
      Brr.El.find_first_by_selector (Jstr.v ".slip-toolbar-red") |> Option.get
    in
    let green =
      Brr.El.find_first_by_selector (Jstr.v ".slip-toolbar-green") |> Option.get
    in
    let yellow =
      Brr.El.find_first_by_selector (Jstr.v ".slip-toolbar-yellow")
      |> Option.get
    in
    let small =
      Brr.El.find_first_by_selector (Jstr.v ".slip-toolbar-small") |> Option.get
    in
    let medium =
      Brr.El.find_first_by_selector (Jstr.v ".slip-toolbar-medium")
      |> Option.get
    in
    let large =
      Brr.El.find_first_by_selector (Jstr.v ".slip-toolbar-large") |> Option.get
    in
    let add_listener setter value elem =
      ignore
      @@ Brr.Ev.listen Brr.Ev.click
           (fun _ -> setter value)
           (Brr.El.as_target elem)
    in
    add_listener State.set_tool Pen pen;
    add_listener State.set_tool Highlighter highlighter;
    add_listener State.set_tool Eraser eraser;
    add_listener State.set_tool Pointer cursor;
    add_listener State.set_color Black black;
    add_listener State.set_color Blue blue;
    add_listener State.set_color Red red;
    add_listener State.set_color Green green;
    add_listener State.set_color Yellow yellow;
    add_listener State.set_width Small small;
    add_listener State.set_width Medium medium;
    add_listener State.set_width Large large
  in
  let _listeners = connect svg in
  ()
