(*---------------------------------------------------------------------------
   Copyright (c) 2023 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr
open Brr_canvas
open Brr_webgpu

(* Draws THE triangle. *)

(* Shaders *)

let vertex_shader = Jstr.v "\
struct vs_in {
  @location(0) pos : vec3f,
  @location(1) color : vec3f,
}

struct vs_out {
  @builtin(position) pos : vec4f,
  @location(0) color : vec3f,
};

@vertex
fn main (in : vs_in) -> vs_out {
  var out : vs_out;
  out.pos = vec4f(in.pos, 1.0);
  out.color = in.color;
  return out;
}"

let fragment_shader = Jstr.v "\
@fragment
fn main (@location(0) color : vec3f) -> @location(0) vec4f {
    return vec4f(color, 1.0);
}"

(* Geometry *)

let positions =
  Tarray.of_float_array Float32 @@
  [| -0.8; -0.8; 0.0;
      0.8; -0.8; 0.0;
      0.0;  0.8; 0.0; |]

let colors =
  Tarray.of_float_array Float32 @@
  [| 1.0; 0.0; 0.0;
     0.0; 1.0; 0.0;
     0.0; 0.0; 1.0; |]

let indices = Tarray.of_int_array Uint16 @@ [| 0; 1; 2 |]

(* WebGPU setup *)

let make_shader_module dev ~src =
  let descr = Gpu.Shader_module.Descriptor.v ~code:src () in
  Gpu.Device.create_shader_module dev descr

let make_buffer dev typ a ~usage =
  let size = Tarray.byte_length a and mapped_at_creation = true in
  let size = (size + 3) land (lnot 3) (* align to 4 *) in
  let descr = Gpu.Buffer.Descriptor.v ~size ~usage ~mapped_at_creation () in
  let buf = Gpu.Device.create_buffer dev descr in
  let b = Tarray.of_buffer typ (Gpu.Buffer.get_mapped_range buf) in
  Tarray.set_tarray b ~dst:0 a; Gpu.Buffer.unmap buf; buf

let make_positions dev =
  let buf = make_buffer dev Float32 positions ~usage:Gpu.Buffer.Usage.vertex in
  let descr =
    let format = Gpu.Vertex.Format.float32x3 in
    let offset = 0 and shader_location = 0 in
    let att = Gpu.Vertex.Attribute.v ~format ~offset ~shader_location () in
    let array_stride = 4 * 3 (* size float * 3 *) in
    let step_mode = Gpu.Vertex.Step_mode.vertex in
    Gpu.Vertex.Buffer_layout.v ~attributes:[att] ~array_stride ~step_mode ()
  in
  buf, descr

let make_colors dev =
  let buf = make_buffer dev Float32 colors ~usage:Gpu.Buffer.Usage.vertex in
  let descr =
    let format = Gpu.Vertex.Format.float32x3 in
    let offset = 0 and shader_location = 1 in
    let att = Gpu.Vertex.Attribute.v ~format ~offset ~shader_location () in
    let array_stride = 4 * 3 (* size float * 3 *) in
    let step_mode = Gpu.Vertex.Step_mode.vertex in
    Gpu.Vertex.Buffer_layout.v ~attributes:[att] ~array_stride ~step_mode ()
  in
  buf, descr

let make_indices dev =
  make_buffer dev Uint16 indices ~usage:Gpu.Buffer.Usage.index

let make_pipeline dev ~vertex_shader ~fragment_shader ~buffer_descrs:buffers =
  let layout =
    let descr = Gpu.Pipeline_layout.Descriptor.v ~bind_group_layouts:[] () in
    `Layout (Gpu.Device.create_pipeline_layout dev descr)
  in
  let vertex =
    let module' = vertex_shader in
    Gpu.Vertex.State.v ~module' ~entry_point:(Jstr.v "main") ~buffers ()
  in
  let fragment =
    let format = Gpu.Texture.Format.bgra8unorm in
    let targets = [Gpu.Color.Target_state.v ~format ()] in
    let module' = fragment_shader in
    Gpu.Fragment_state.v ~module' ~entry_point:(Jstr.v "main") ~targets ()
  in
  let primitive =
    let front_face = Gpu.Primitive.Front_face.cw in
    let cull_mode = Gpu.Primitive.Cull_mode.none in
    let topology = Gpu.Primitive.Topology.triangle_list in
    Gpu.Primitive.State.v ~topology ~front_face ~cull_mode ()
  in
  let depth_stencil =
    let depth_write_enabled = true in
    let depth_compare = Gpu.Compare_function.less in
    let format = Gpu.Texture.Format.depth24plus_stencil8 in
    Gpu.Depth_stencil_state.v ~depth_write_enabled ~depth_compare ~format ()
  in
  let descr =
    Gpu.Render_pipeline.Descriptor.v
      ~layout ~vertex ~fragment ~primitive ~depth_stencil ()
  in
  Gpu.Device.create_render_pipeline dev descr

let make_framebuffer_attachements dev ctx ~w ~h =
  let color = Gpu.Canvas_context.get_current_texture ctx in
  let color_view = Gpu.Texture.create_view color in
  let depth =
    let size = Gpu.Extent_3d.v ~w ~h () in
    let dimension = Gpu.Texture.Dimension.d2 in
    let format = Gpu.Texture.Format.depth24plus_stencil8 in
    let usage = Gpu.Texture.Usage.(render_attachment lor copy_src) in
    let descr = Gpu.Texture.Descriptor.v ~size ~dimension ~format ~usage () in
    Gpu.Device.create_texture dev descr
  in
  let depth_view = Gpu.Texture.create_view depth in
  color_view, depth_view

let make_render_pass ~encoder ~color_view ~depth_view =
  let color_attachments =
    let view = color_view in
    let clear_value = Gpu.Color.v ~r:0. ~g:0. ~b:0. ~a:1. in
    let load_op = Gpu.Render_pass.Load_op.clear in
    let store_op = Gpu.Render_pass.Store_op.store in
    [Gpu.Render_pass.Color_attachment.v
       ~view ~clear_value ~load_op ~store_op ()]
  in
  let depth_stencil_attachment =
    let view = depth_view in
    let depth_clear_value = 1. in
    let depth_load_op = Gpu.Render_pass.Load_op.clear in
    let depth_store_op = Gpu.Render_pass.Store_op.store in
    let stencil_clear_value = 1 in
    let stencil_load_op = Gpu.Render_pass.Load_op.clear in
    let stencil_store_op = Gpu.Render_pass.Store_op.store in
    Gpu.Render_pass.Depth_stencil_attachment.v
      ~view ~depth_clear_value ~depth_load_op ~depth_store_op
      ~stencil_clear_value ~stencil_load_op ~stencil_store_op ()
  in
  let descr =
    Gpu.Render_pass.Descriptor.v ~depth_stencil_attachment ~color_attachments ()
  in
  Gpu.Command.Encoder.begin_render_pass encoder descr

let render dev ctx ~w ~h =
  let color_view, depth_view = make_framebuffer_attachements dev ctx ~w ~h in
  let vertex_shader = make_shader_module dev ~src:vertex_shader in
  let fragment_shader = make_shader_module dev ~src:fragment_shader in
  let positions, positions_descr = make_positions dev in
  let colors, colors_descr = make_colors dev in
  let indices = make_indices dev in
  let buffer_descrs = [positions_descr; colors_descr] in
  let pipeline =
    make_pipeline dev ~vertex_shader ~fragment_shader ~buffer_descrs
  in
  let encoder = Gpu.Device.create_command_encoder dev in
  let pass = make_render_pass ~encoder ~color_view ~depth_view in
  Gpu.Render_pass.Encoder.set_pipeline pass pipeline;
  Gpu.Render_pass.Encoder.set_viewport
    pass ~x:0. ~y:0. ~w:(float w) ~h:(float h) ~min_depth:0. ~max_depth:1.;
  Gpu.Render_pass.Encoder.set_scissor_rect pass ~x:0 ~y:0 ~w ~h;
  Gpu.Render_pass.Encoder.set_vertex_buffer pass ~slot:0 ~buffer:positions;
  Gpu.Render_pass.Encoder.set_vertex_buffer pass ~slot:1 ~buffer:colors;
  Gpu.Render_pass.Encoder.set_index_buffer
    pass indices ~format:Gpu.Index_format.uint16;
  Gpu.Render_pass.Encoder.draw_indexed pass ~index_count:3;
  Gpu.Render_pass.Encoder.end' pass;
  Gpu.Queue.submit (Gpu.Device.queue dev) [Gpu.Command.Encoder.finish encoder];
  ()

let configure_context d ctx =
  let usage = Gpu.Texture.Usage.(render_attachment lor copy_src) in
  let alpha_mode = Gpu.Canvas_context.Alpha_mode.opaque in
  let fmt = Gpu.Texture.Format.bgra8unorm in
  let conf = Gpu.Canvas_context.conf d fmt ~usage ~alpha_mode in
  Gpu.Canvas_context.configure ctx conf

let resize_canvas cnv =
  let cnv_el = Canvas.to_el cnv in
  let w = El.inner_w cnv_el in
  let h = Jstr.(of_int (truncate ((w *. 3.) /. 4.)) + v "px") (* 4:3 *) in
  El.set_inline_style El.Style.height h cnv_el;
  Canvas.set_size_to_layout_size cnv;
  Canvas.w cnv, Canvas.h cnv

let error ~h1 e =
  let children = [h1; El.p El.[txt' e]] in
  El.set_children (Document.body G.document) children;
  Fut.ok ()

let main ()  =
  Fut.map (Console.log_if_error ~use:()) @@
  let open Fut.Syntax in
  let* _ev = Ev.next Ev.load (Window.as_target G.window) in
  let open Fut.Result_syntax in
  let h1 = El.h1 [El.txt' "WebGPU canvas"] in
  match Gpu.of_navigator G.navigator with
  | None -> error ~h1 "Sorry, WebGPU is not supported by your browser."
  | Some gpu ->
      let* a = Gpu.request_adapter gpu in
      match a with
      | None -> error ~h1 "Sorry, no GPU adapter found."
      | Some a ->
          let* info = Gpu.Adapter.request_adapter_info a ~unmask_hints:[] in
          let* dev = Gpu.Adapter.request_device a in
          Console.log [a]; Console.log [info]; Console.log [dev];
          let cnv = Canvas.create [] in
          match Gpu.Canvas_context.get cnv with
          | None -> error ~h1 "Sorry, could not get a WebGPU canvas context."
          | Some ctx ->
              Console.log [ctx];
              let info = [El.txt' "Draws THE triangle."] in
              let children = [h1; El.p info; Canvas.to_el cnv] in
              El.set_children (Document.body G.document) children;
              let w, h = resize_canvas cnv in
              let () = configure_context dev ctx in
              render dev ctx ~w ~h;
              Fut.ok ()

let () = ignore (main ())
