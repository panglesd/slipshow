(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr
open Brr_canvas

let ( let* ) = Result.bind

(* Shaders *)

let vertex_shader = Jstr.v "\
  #version 300 es
  in vec3 vertex;
  in vec3 color;
  out vec4 v_color;
  void main()
  {
    v_color = vec4(color, 1.0);
    gl_Position = vec4(vertex, 1.0);
  }"

let fragment_shader = Jstr.v "\
  #version 300 es
  precision highp float;
  in vec4 v_color;
  out vec4 color;
  void main() { color = v_color; }"

(* Geometry *)

let vertices =
  Tarray.of_float_array Float32 @@
  [| -0.8; -0.8; 0.0;
      0.8; -0.8; 0.0;
      0.0;  0.8; 0.0; |]

let colors =
  Tarray.of_float_array Float32 @@
  [| 1.0; 0.0; 0.0;
     0.0; 1.0; 0.0;
     0.0; 0.0; 1.0; |]

let indices = Tarray.of_int_array Uint8 @@ [| 0; 1; 2 |]

(* WebGL setup *)

let create_geometry c =
  let create_buffer c target data =
    let buf = Gl.create_buffer c in
    Gl.bind_buffer c target (Some buf);
    Gl.buffer_data c target data Gl.static_draw;
    buf
  in
  let bind_attrib id ~loc ~dim typ =
    Gl.bind_buffer c Gl.array_buffer (Some id);
    Gl.enable_vertex_attrib_array c loc;
    Gl.vertex_attrib_pointer c loc dim typ false 0 0;
  in
  let va = Gl.create_vertex_array c in
  let indices = create_buffer c Gl.element_array_buffer indices in
  let verts = create_buffer c Gl.array_buffer vertices in
  let colors = create_buffer c Gl.array_buffer colors in
  Gl.bind_vertex_array c (Some va);
  Gl.bind_buffer c Gl.element_array_buffer (Some indices);
  bind_attrib verts ~loc:0 ~dim:3 Gl.float;
  bind_attrib colors ~loc:1 ~dim:3 Gl.float;
  Gl.bind_vertex_array c None;
  Gl.bind_buffer c Gl.array_buffer None;
  Gl.bind_buffer c Gl.element_array_buffer None;
  Ok (va, [indices; verts; colors])

let delete_geometry c va bufs =
  Gl.delete_vertex_array c va; List.iter (Gl.delete_buffer c) bufs

let compile_shader c src typ =
  let s = Gl.create_shader c typ in
  Gl.shader_source c s src;
  Gl.compile_shader c s;
  match Jv.to_bool (Gl.get_shader_parameter c s Gl.compile_status) with
  | true -> Ok s
  | false ->
      let log = Gl.get_shader_info_log c s in
      (Gl.delete_shader c s; Error log)

let create_program c =
  let* vs = compile_shader c vertex_shader Gl.vertex_shader in
  let* fs = compile_shader c fragment_shader Gl.fragment_shader in
  let p = Gl.create_program c in
  Gl.attach_shader c p vs; Gl.delete_shader c vs;
  Gl.attach_shader c p fs; Gl.delete_shader c fs;
  Gl.bind_attrib_location c p 0 (Jstr.v "vertex");
  Gl.bind_attrib_location c p 1 (Jstr.v "color");
  Gl.link_program c p;
  match Jv.to_bool (Gl.get_program_parameter c p Gl.link_status) with
  | true -> Ok p
  | false ->
      let log = Gl.get_program_info_log c p in
      (Gl.delete_program c p; Error log)

let delete_program c pid = Gl.delete_program c pid

let draw c p va =
  Gl.viewport c 0 0 (Gl.drawing_buffer_width c) (Gl.drawing_buffer_height c);
  Gl.clear_color c 0. 0. 0. 1.;
  Gl.clear c Gl.color_buffer_bit;
  Gl.use_program c p;
  Gl.bind_vertex_array c (Some va);
  Gl.draw_elements c Gl.triangles 3 Gl.unsigned_byte 0;
  Gl.bind_vertex_array c None

let render c =
  let* p = create_program c in
  let* va, bufs = create_geometry c in
  draw c p va;
  delete_program c p; delete_geometry c va bufs;
  Ok ()

let render cnv = match Gl.get_context cnv with
| None ->
    let err = El.p [El.txt' "Could not get a WebGL2 context." ] in
    El.append_children (Document.body G.document) [err]
| Some c ->
    let cnv_el = Canvas.to_el cnv in
    let w = El.inner_w cnv_el in
    let h = Jstr.(of_int (truncate ((w *. 3.) /. 4.)) + v "px") (* 4:3 *) in
    El.set_inline_style El.Style.height h cnv_el;
    Canvas.set_size_to_layout_size cnv;
    Console.log [Gl.attrs c];
    Console.log_if_error ~use:() (render c)

let main ()  =
  let h1 = El.h1 [El.txt' "WebGL2 canvas"] in
  let info = [El.txt' "Draws THE triangle."] in
  let cnv = Canvas.create [] in
  let children = [h1; El.p info; Canvas.to_el cnv] in
  El.set_children (Document.body G.document) children;
  (* Wait for layout! *)
  Fut.bind (Ev.next Ev.load (Window.as_target G.window)) @@ fun _ev ->
  render cnv; Fut.return ()

let () = ignore (main ())
