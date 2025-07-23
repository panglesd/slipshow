(*---------------------------------------------------------------------------
   Copyright (c) 2023 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

module Gpu = struct
  module Origin_2d = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let v ~x ~y =
      let o = Jv.obj [||] in
      Jv.Int.set o "x" x; Jv.Int.set o "y" y; o
  end

  module Origin_3d = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let v ~x ~y ~z =
      let o = Jv.obj [||] in
      Jv.Int.set o "x" x; Jv.Int.set o "y" y; Jv.Int.set o "z" z; o
  end

  module Extent_3d = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let v ?(h = 1) ?(d = 1) ~w () =
      let o = Jv.obj [||] in
      Jv.Int.set o "width" w; Jv.Int.set o "height" h;
      Jv.Int.set o "depthOrArrayLayers" d; o
  end

  module Compare_function = struct
    type t = Jstr.t
    let never = Jstr.v "never"
    let less = Jstr.v "less"
    let equal = Jstr.v "equal"
    let less_equal = Jstr.v "less-equal"
    let greater = Jstr.v "greater"
    let not_equal = Jstr.v "not-equal"
    let greater_equal = Jstr.v "greater-equal"
    let always = Jstr.v "always"
  end

  module Buffer = struct
    module Map_state = struct
      type t = Jstr.t
      let unmapped = Jstr.v "unmapped"
      let pending = Jstr.v "pending"
      let mapped = Jstr.v  "mapped"
    end
    module Map_mode = struct
      type t = int
      let read  = 0x0001
      let write = 0x0002
    end
    module Usage = struct
      type t = int
      let map_read      = 0x0001
      let map_write     = 0x0002
      let copy_src      = 0x0004
      let copy_dst      = 0x0008
      let index         = 0x0010
      let vertex        = 0x0020
      let uniform       = 0x0040
      let storage       = 0x0080
      let indirect      = 0x0100
      let query_resolve = 0x0200
    end
    module Descriptor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?label ?size ?usage ?mapped_at_creation () =
        let d = Jv.obj [||] in
        Jv.Jstr.set_if_some d "label" label;
        Jv.Int.set_if_some d "size" size;
        Jv.Int.set_if_some d "usage" usage;
        Jv.Bool.set_if_some d "mappedAtCreation" mapped_at_creation;
        d
    end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let label b = Jv.Jstr.get b "label"
    let size b = Jv.Int.get b "size"
    let usage b = Jv.Int.get b "usage"
    let map_state b = Jv.Jstr.get b "mapState"
    let map_async ?size ?offset b mode =
      let size = Jv.of_option ~none:Jv.undefined Jv.of_int size in
      let offset = Jv.of_option ~none:Jv.undefined Jv.of_int offset in
      let mode = Jv.of_int mode in
      Fut.of_promise ~ok:ignore @@ Jv.call b "mapAsync" [|mode; offset; size|]

    let get_mapped_range ?size ?offset b =
      let size = Jv.of_option ~none:Jv.undefined Jv.of_int size in
      let offset = Jv.of_option ~none:Jv.undefined Jv.of_int offset in
      Brr.Tarray.Buffer.of_jv @@ Jv.call b "getMappedRange" [|size; offset|]

    let unmap b = ignore @@ Jv.call b "unmap" [||]
    let destroy b = ignore @@ Jv.call b "destroy" [||]

    module Binding_type = struct
      type t = Jstr.t
      let uniform = Jstr.v "uniform"
      let storage = Jstr.v "storage"
      let read_only_storage = Jstr.v "read-only-storage"
    end
    module Binding_layout = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?type' ?has_dynamic_offset ?min_binding_size () =
        let l = Jv.obj [||] in
        Jv.Jstr.set_if_some l "type" type';
        Jv.Bool.set_if_some l "hasDynamicOffset" has_dynamic_offset;
        Jv.Int.set_if_some l "minBindingSize" min_binding_size;
        l
    end
    module Binding = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?offset ?size ~buffer () =
        let b = Jv.obj [||] in
        Jv.set b "buffer" buffer;
        Jv.Int.set_if_some b "offset" offset;
        Jv.Int.set_if_some b "size" size;
        b
    end
  end

  module Texture = struct
    module Format = struct
      type t = Jstr.t
      include (Jv.Id : Jv.CONV with type t := t)
      let r8unorm = Jstr.v "r8unorm"
      let r8snorm = Jstr.v "r8snorm"
      let r8uint = Jstr.v "r8uint"
      let r8sint = Jstr.v "r8sint"
      let r16uint = Jstr.v "r16uint"
      let r16sint = Jstr.v "r16sint"
      let r16float = Jstr.v "r16float"
      let rg8unorm = Jstr.v "rg8unorm"
      let rg8snorm = Jstr.v "rg8snorm"
      let rg8uint = Jstr.v "rg8uint"
      let rg8sint = Jstr.v "rg8sint"
      let r32uint = Jstr.v "r32uint"
      let r32sint = Jstr.v "r32sint"
      let r32float = Jstr.v "r32float"
      let rg16uint = Jstr.v "rg16uint"
      let rg16sint = Jstr.v "rg16sint"
      let rg16float = Jstr.v "rg16float"
      let rgba8unorm = Jstr.v "rgba8unorm"
      let rgba8unorm_srgb = Jstr.v "rgba8unorm-srgb"
      let rgba8snorm = Jstr.v "rgba8snorm"
      let rgba8uint = Jstr.v "rgba8uint"
      let rgba8sint = Jstr.v "rgba8sint"
      let bgra8unorm = Jstr.v "bgra8unorm"
      let bgra8unorm_srgb = Jstr.v "bgra8unorm-srgb"
      let rgb9e5ufloat = Jstr.v "rgb9e5ufloat"
      let rgb10a2unorm = Jstr.v "rgb10a2unorm"
      let rg11b10ufloat = Jstr.v "rg11b10ufloat"
      let rg32uint = Jstr.v "rg32uint"
      let rg32sint = Jstr.v "rg32sint"
      let rg32float = Jstr.v "rg32float"
      let rgba16uint = Jstr.v "rgba16uint"
      let rgba16sint = Jstr.v "rgba16sint"
      let rgba16float = Jstr.v "rgba16float"
      let rgba32uint = Jstr.v "rgba32uint"
      let rgba32sint = Jstr.v "rgba32sint"
      let rgba32float = Jstr.v "rgba32float"
      let stencil8 = Jstr.v "stencil8"
      let depth16unorm = Jstr.v "depth16unorm"
      let depth24plus = Jstr.v "depth24plus"
      let depth24plus_stencil8 = Jstr.v "depth24plus-stencil8"
      let depth32float = Jstr.v "depth32float"
      let depth32float_stencil8 = Jstr.v "depth32float-stencil8"
      let bc1_rgba_unorm = Jstr.v "bc1-rgba-unorm"
      let bc1_rgba_unorm_srgb = Jstr.v "bc1-rgba-unorm-srgb"
      let bc2_rgba_unorm = Jstr.v "bc2-rgba-unorm"
      let bc2_rgba_unorm_srgb = Jstr.v "bc2-rgba-unorm-srgb"
      let bc3_rgba_unorm = Jstr.v "bc3-rgba-unorm"
      let bc3_rgba_unorm_srgb = Jstr.v "bc3-rgba-unorm-srgb"
      let bc4_r_unorm = Jstr.v "bc4-r-unorm"
      let bc4_r_snorm = Jstr.v "bc4-r-snorm"
      let bc5_rg_unorm = Jstr.v "bc5-rg-unorm"
      let bc5_rg_snorm = Jstr.v "bc5-rg-snorm"
      let bc6h_rgb_ufloat = Jstr.v "bc6h-rgb-ufloat"
      let bc6h_rgb_float = Jstr.v "bc6h-rgb-float"
      let bc7_rgba_unorm = Jstr.v "bc7-rgba-unorm"
      let bc7_rgba_unorm_srgb = Jstr.v "bc7-rgba-unorm-srgb"
      let etc2_rgb8unorm = Jstr.v "etc2-rgb8unorm"
      let etc2_rgb8unorm_srgb = Jstr.v "etc2-rgb8unorm-srgb"
      let etc2_rgb8a1unorm = Jstr.v "etc2-rgb8a1unorm"
      let etc2_rgb8a1unorm_srgb = Jstr.v "etc2-rgb8a1unorm-srgb"
      let etc2_rgba8unorm = Jstr.v "etc2-rgba8unorm"
      let etc2_rgba8unorm_srgb = Jstr.v "etc2-rgba8unorm-srgb"
      let eac_r11unorm = Jstr.v "eac-r11unorm"
      let eac_r11snorm = Jstr.v "eac-r11snorm"
      let eac_rg11unorm = Jstr.v "eac-rg11unorm"
      let eac_rg11snorm = Jstr.v "eac-rg11snorm"
      let astc_4x4_unorm = Jstr.v "astc-4x4-unorm"
      let astc_4x4_unorm_srgb = Jstr.v "astc-4x4-unorm-srgb"
      let astc_5x4_unorm = Jstr.v "astc-5x4-unorm"
      let astc_5x4_unorm_srgb = Jstr.v "astc-5x4-unorm-srgb"
      let astc_5x5_unorm = Jstr.v "astc-5x5-unorm"
      let astc_5x5_unorm_srgb = Jstr.v "astc-5x5-unorm-srgb"
      let astc_6x5_unorm = Jstr.v "astc-6x5-unorm"
      let astc_6x5_unorm_srgb = Jstr.v "astc-6x5-unorm-srgb"
      let astc_6x6_unorm = Jstr.v "astc-6x6-unorm"
      let astc_6x6_unorm_srgb = Jstr.v "astc-6x6-unorm-srgb"
      let astc_8x5_unorm = Jstr.v "astc-8x5-unorm"
      let astc_8x5_unorm_srgb = Jstr.v "astc-8x5-unorm-srgb"
      let astc_8x6_unorm = Jstr.v "astc-8x6-unorm"
      let astc_8x6_unorm_srgb = Jstr.v "astc-8x6-unorm-srgb"
      let astc_8x8_unorm = Jstr.v "astc-8x8-unorm"
      let astc_8x8_unorm_srgb = Jstr.v "astc-8x8-unorm-srgb"
      let astc_10x5_unorm = Jstr.v "astc-10x5-unorm"
      let astc_10x5_unorm_srgb = Jstr.v "astc-10x5-unorm-srgb"
      let astc_10x6_unorm = Jstr.v "astc-10x6-unorm"
      let astc_10x6_unorm_srgb = Jstr.v "astc-10x6-unorm-srgb"
      let astc_10x8_unorm = Jstr.v "astc-10x8-unorm"
      let astc_10x8_unorm_srgb = Jstr.v "astc-10x8-unorm-srgb"
      let astc_10x10_unorm = Jstr.v "astc-10x10-unorm"
      let astc_10x10_unorm_srgb = Jstr.v "astc-10x10-unorm-srgb"
      let astc_12x10_unorm = Jstr.v "astc-12x10-unorm"
      let astc_12x10_unorm_srgb = Jstr.v "astc-12x10-unorm-srgb"
      let astc_12x12_unorm = Jstr.v "astc-12x12-unorm"
      let astc_12x12_unorm_srgb = Jstr.v "astc-12x12-unorm-srgb"
    end
    module Usage = struct
      type t = int
      let copy_src          = 0x01
      let copy_dst          = 0x02
      let texture_binding   = 0x04
      let storage_binding   = 0x08
      let render_attachment = 0x10
    end
    module Dimension = struct
      type t = Jstr.t
      let d1 = Jstr.v "1d"
      let d2 = Jstr.v "2d"
      let d3 = Jstr.v "3d"
    end
    module View_dimension = struct
      type t = Jstr.t
      let d1 = Jstr.v "1d"
      let d2 = Jstr.v "2d"
      let d2_array = Jstr.v "2d-array"
      let cube = Jstr.v "cube"
      let cube_array = Jstr.v "cube-array"
      let d3 = Jstr.v "3d"
    end
    module Aspect = struct
      type t = Jstr.t
      let all = Jstr.v "all"
      let stencil_only = Jstr.v "stencil-only"
      let depth_only = Jstr.v "depth-only"
    end
    module View = struct
      module Descriptor = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v
            ?label ?format ?dimension ?aspect ?base_mip_level ?mip_level_count
            ?base_array_layer ?array_layer_count ()
          =
          let d = Jv.obj [||] in
          Jv.Jstr.set_if_some d "label" label;
          Jv.Jstr.set_if_some d "format"format;
          Jv.set_if_some d "dimension" dimension;
          Jv.Jstr.set_if_some d "aspect" aspect;
          Jv.Int.set_if_some d "baseMipLevel" base_mip_level;
          Jv.Int.set_if_some d "mipLevelCount" mip_level_count;
          Jv.Int.set_if_some d "baseArrayLayer" base_array_layer;
          Jv.Int.set_if_some d "arrayLayerCount" array_layer_count;
          d
      end
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let label v = Jv.Jstr.get v "label"
    end
    module Storage = struct
      module Access = struct
        type t = Jstr.t
        let write_only = Jstr.v "write-only"
      end
      module Binding_layout = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v ?access ?format ?view_dimension () =
          let l = Jv.obj [||] in
          Jv.Jstr.set_if_some l "access" access;
          Jv.Jstr.set_if_some l "format" format;
          Jv.Jstr.set_if_some l "viewDimension" view_dimension;
          l
      end
    end
    module External = struct
      module Binding_layout = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v () =
          let d = Jv.obj [||] in
          d
      end
      module Descriptor = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v ?label ?color_space ~source () =
          let d = Jv.obj [||] in
          Jv.Jstr.set_if_some d "label" label;
          Jv.set d "source" source;
          Jv.Jstr.set_if_some d "colorSpace" color_space;
      end
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let label v = Jv.Jstr.get v "label"
    end
    module Sample_type = struct
      type t = Jstr.t
      let float = Jstr.v "float"
      let unfilterable_float = Jstr.v "unfilterable-float"
      let depth = Jstr.v "depth"
      let sint = Jstr.v "sint"
      let uint = Jstr.v "uint"
    end
    module Binding_layout = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?sample_type ?view_dimension ?multisampled () =
        let l = Jv.obj [||] in
        Jv.Jstr.set_if_some l "sampleType" sample_type;
        Jv.Jstr.set_if_some l "viewDimension" view_dimension;
        Jv.Bool.set_if_some l "multisampled" multisampled;
        l
    end
    module Descriptor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v
          ?label ?mip_level_count ?sample_count ?dimension ?(view_formats = [])
          ~size ~format ~usage ()
        =
        let view_formats = Jv.of_list Jv.of_jstr view_formats in
        let d = Jv.obj [||] in
        Jv.Jstr.set_if_some d "label" label;
        Jv.set d "size" size;
        Jv.Int.set_if_some d "mipLevelCount" mip_level_count;
        Jv.Int.set_if_some d "sampleCount" sample_count;
        Jv.Jstr.set_if_some d "dimension" dimension;
        Jv.Jstr.set d "format" format;
        Jv.Int.set d "usage" usage;
        Jv.set d "viewFormats" view_formats;
        d
    end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let label t = Jv.Jstr.get t "label"
    let create_view ?(descriptor = Jv.undefined) t =
      View.of_jv @@ Jv.call t "createView" [|descriptor|]

    let destroy t = ignore @@ Jv.call t "destroy" [||]
    let width t = Jv.Int.get t "width"
    let height t = Jv.Int.get t "height"
    let depth_or_array_layers t = Jv.Int.get t "depthOrArrayLayers"
    let mip_level_count t = Jv.Int.get t "mipLevelCount"
    let sample_count t = Jv.Int.get t "sampleCount"
    let dimension t = Jv.Jstr.get t "dimension"
    let format t = Jv.Jstr.get t "format"
    let usage t = Jv.Int.get t "usage"
  end

  module Image = struct
    module Data_layout = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?offset ?bytes_per_row ?rows_per_image () =
        let d = Jv.obj [||] in
        Jv.Int.set_if_some d "offset" offset;
        Jv.Int.set_if_some d "bytesPerRow" bytes_per_row;
        Jv.Int.set_if_some d "rowsPerImage" rows_per_image;
        d
    end
    module Copy_buffer = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?offset ?bytes_per_row ?rows_per_image ~buffer () =
        let d = Jv.obj [||] in
        Jv.set d "buffer" (Buffer.to_jv buffer);
        Jv.Int.set_if_some d "offset" offset;
        Jv.Int.set_if_some d "bytesPerRow" bytes_per_row;
        Jv.Int.set_if_some d "rowsPerImage" rows_per_image;
        d
    end
    module Copy_texture = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?mip_level ?(origin = Jv.undefined) ?aspect ~texture () =
        let d = Jv.obj [||] in
        Jv.set d "texture" (Texture.to_jv texture);
        Jv.Int.set_if_some d "mipLevel" mip_level;
        Jv.set d "origin" origin;
        Jv.Jstr.set_if_some d "aspect" aspect;
        d
    end
    module Copy_texture_tagged = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v
          ?mip_level ?(origin = Jv.undefined) ?aspect ?color_space
          ?premultiplied_alpha ~texture ()
        =
        let d = Jv.obj [||] in
        Jv.set d "texture" (Texture.to_jv texture);
        Jv.Int.set_if_some d "mipLevel" mip_level;
        Jv.set d "origin" origin;
        Jv.Jstr.set_if_some d "aspect" aspect;
        Jv.Jstr.set_if_some d "colorSpace" color_space;
        Jv.Bool.set_if_some d "premultipliedAlpha" premultiplied_alpha;
        d
    end
    module Copy_external_image = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?(origin = Jv.undefined) ?flip_y ~source () =
        let d = Jv.obj [||] in
        Jv.set d "source" source;
        Jv.set d "origin" origin;
        Jv.Bool.set_if_some d "flipY" flip_y;
        d
    end
  end

  module Sampler = struct
    module Binding_type = struct
      type t = Jstr.t
      let filtering = Jstr.v "filtering"
      let non_filtering = Jstr.v "non-filtering"
      let comparison = Jstr.v "comparison"
    end
    module Binding_layout = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?type' () =
        let l = Jv.obj [||] in
        Jv.Jstr.set_if_some l "type" type'; l
    end
    module Address_mode = struct
      type t = Jstr.t
      let clamp_to_edge = Jstr.v "clamp-to-edge"
      let repeat = Jstr.v "repeat"
      let mirror_repeat = Jstr.v "mirror-repeat"
    end
    module Filter_mode = struct
      type t = Jstr.t
      let nearest = Jstr.v "nearest"
      let linear = Jstr.v "linear"
    end
    module Mipmap_filter_mode = struct
      type t = Jstr.t
      let nearest = Jstr.v "nearest"
      let linear = Jstr.v "linear"
    end
    module Descriptor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v
          ?address_mode_u ?address_mode_v ?address_mode_w ?mag_filter
          ?min_filter ?mipmap_filter ?lod_min_clamp ?lod_max_clamp ?compare
          ?max_anisotropy ()
        =
        let d = Jv.obj [||] in
        Jv.Jstr.set_if_some d "addressModeU" address_mode_u;
        Jv.Jstr.set_if_some d "addressModeV" address_mode_v;
        Jv.Jstr.set_if_some d "addressModeW" address_mode_w;
        Jv.Jstr.set_if_some d "magFilter" mag_filter;
        Jv.Jstr.set_if_some d "minFilter" min_filter;
        Jv.Jstr.set_if_some d "mipmapFilter" mipmap_filter;
        Jv.Float.set_if_some d "lodMinClamp" lod_min_clamp;
        Jv.Float.set_if_some d "lodMaxClamp" lod_max_clamp;
        Jv.Jstr.set_if_some d "compare" compare;
        Jv.Int.set_if_some d "maxAnisotropy" max_anisotropy;
        d
    end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let label s = Jv.Jstr.get s "label"
  end

  (* Pipelines *)

  (* Shaders *)

  module Bind_group = struct
    module Layout = struct
      module Shader_stage = struct
        type t = int
        let vertex   = 0x1
        let fragment = 0x2
        let compute  = 0x4
      end
      module Entry = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v
            ?buffer ?sampler ?texture ?storage_texture ?external_texture
            ~binding ~visibility ()
          =
          let e = Jv.obj [||] in
          let m = Option.map in
          Jv.Int.set e "binding" binding;
          Jv.Int.set e "visibility" visibility;
          Jv.set_if_some e "buffer" (m Buffer.Binding_layout.to_jv buffer);
          Jv.set_if_some e "sampler" (m Sampler.Binding_layout.to_jv sampler);
          Jv.set_if_some e "texture" (m Texture.Binding_layout.to_jv texture);
          Jv.set_if_some e "storageTexture"
            (m Texture.Storage.Binding_layout.to_jv storage_texture);
          Jv.set_if_some e "externalTexture"
            (m Texture.Storage.Binding_layout.to_jv external_texture);
          e
      end
      module Descriptor = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v ~entries () =
          let d = Jv.obj [||] in
          Jv.set d "entries" (Jv.of_list Entry.to_jv entries);
          d
      end
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let label l = Jv.Jstr.get l "label"
    end
    module Entry = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)

      let of_sampler binding resource =
        let e = Jv.obj [||] in
        Jv.Int.set e "binding" binding;
        Jv.set e "resource" (Sampler.to_jv resource); e

      let of_texture_view binding resource =
        let e = Jv.obj [||] in
        Jv.Int.set e "binding" binding;
        Jv.set e "resource" (Texture.View.to_jv resource); e

      let of_buffer_binding binding resource =
        let e = Jv.obj [||] in
        Jv.Int.set e "binding" binding;
        Jv.set e "resource" (Buffer.Binding.to_jv resource); e

      let of_external_texture binding resource =
        let e = Jv.obj [||] in
          Jv.Int.set e "binding" binding;
          Jv.set e "resource" (Texture.External.to_jv resource); e
    end
    module Descriptor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?label ~layout ~entries () =
        let entries = Jv.of_list Entry.to_jv entries in
        let d = Jv.obj [||] in
        Jv.Jstr.set_if_some d "label" label;
        Jv.set d "layout" (Layout.to_jv layout);
        Jv.set d "entries" entries;
        d
      end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let label l = Jv.Jstr.get l "label"
  end

  module Pipeline_layout = struct
    module Descriptor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?label ~bind_group_layouts () =
        let d = Jv.obj [||] in
        let ls = Jv.of_list Bind_group.Layout.to_jv bind_group_layouts in
        Jv.Jstr.set_if_some d "label" label;
        Jv.set d "bindGroupLayouts" ls;
        d
    end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let label l = Jv.Jstr.get l "label"
  end

  module Shader_module = struct
    module Compilation_message = struct
      module Type = struct
        type t = Jstr.t
        let error = Jstr.v "error"
        let warning = Jstr.v "warning"
        let info = Jstr.v "info"
      end
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let message m = Jv.Jstr.get m "message"
      let type' m = Jv.Jstr.get m "type"
      let linenum m = Jv.Int.get m "lineNum"
      let linepos m = Jv.Int.get m "linePos"
      let offset m = Jv.Int.get m "offset"
      let length m = Jv.Int.get m "length"
    end
    module Compilation_info = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let messages i =
        Jv.to_list Compilation_message.of_jv (Jv.get i "messages")
    end
    module Compilation_hint = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?layout () =
        let h = Jv.obj [||] in
        begin match layout with
        | None -> ()
        | Some `Auto -> Jv.Jstr.set h "layout" (Jstr.v "auto")
        | Some (`Layout l) -> Jv.set h "layout" (Pipeline_layout.to_jv l)
        end;
        h
    end
    module Descriptor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let hints_obj hints =
        let c = Jv.obj [||] in
        let set o (k, h) = Jv.set' o k (Compilation_hint.to_jv h) in
        List.iter (set c) hints; c

      let v ?label ?source_map ?(hints = []) ~code () =
        let hints = hints_obj hints in
        let d = Jv.obj [||] in
        Jv.Jstr.set_if_some d "label" label;
        Jv.Jstr.set d "code" code;
        Jv.set_if_some d "sourceMap" source_map;
        Jv.set d "hints" hints;
        d
    end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let label l = Jv.Jstr.get l "label"
    let get_compilation_info m =
      let ok = Compilation_info.of_jv in
      Fut.of_promise ~ok @@ Jv.call m "getCompilationInfo" [||]
  end

  module Programmable_stage = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let constants_obj constants =
      let c = Jv.obj [||] in
      let set o (k, v) = Jv.set' o k (Jv.of_float v) in
      List.iter (set c) constants; c

    let v ?(constants = []) ~module' ~entry_point () =
      let p = Jv.obj [||] in
      Jv.set p "module" module';
      Jv.Jstr.set p "entryPoint" entry_point;
      Jv.set p "constants" (constants_obj constants);
      p
  end

  (* Compute pipelines *)

  module Compute_pipeline = struct
    module Descriptor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?label ~layout ~compute () =
        let d = Jv.obj [||]in
        Jv.Jstr.set_if_some d "label" label;
        begin match layout with
        | `Auto -> Jv.Jstr.set d "layout" (Jstr.v "auto")
        | `Layout l -> Jv.set d "layout" (Pipeline_layout.to_jv l)
        end;
        Jv.set d "compute" (Programmable_stage.to_jv compute);
        d
    end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let label p = Jv.Jstr.get p "label"
    let get_bind_group_layout p i =
      Bind_group.Layout.of_jv @@ Jv.call p "getBindGroupLayout" [|Jv.of_int i|]
  end

  (* Render pipeline *)

  module Index_format = struct
    type t = Jstr.t
    let uint16 = Jstr.v "uint16"
    let uint32 = Jstr.v "uint32"
  end

  module Primitive = struct
    module Topology = struct
      type t = Jstr.t
      let point_list = Jstr.v "point-list"
      let line_list = Jstr.v "line-list"
      let line_strip = Jstr.v "line-strip"
      let triangle_list = Jstr.v "triangle-list"
      let triangle_strip = Jstr.v "triangle-strip"
    end
    module Front_face = struct
      type t = Jstr.t
      let ccw = Jstr.v "ccw"
      let cw = Jstr.v "cw"
    end
    module Cull_mode = struct
      type t = Jstr.t
      let none = Jstr.v "none"
      let front = Jstr.v "front"
      let back = Jstr.v "back"
    end
    module State = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v
          ?topology ?strip_index_format ?front_face ?cull_mode
          ?unclipped_depth ()
        =
        let s = Jv.obj [||] in
        Jv.Jstr.set_if_some s "topology" topology;
        Jv.Jstr.set_if_some s "stripIndexFormat" strip_index_format;
        Jv.Jstr.set_if_some s "fontFace" front_face;
        Jv.Jstr.set_if_some s "cullMode" cull_mode;
        Jv.Bool.set_if_some s "unclippedDepth" unclipped_depth;
        s
    end
  end

  module Vertex = struct
    module Format = struct
      type t = Jstr.t
      let uint8x2 = Jstr.v "uint8x2"
      let uint8x4 = Jstr.v "uint8x4"
      let sint8x2 = Jstr.v "sint8x2"
      let sint8x4 = Jstr.v "sint8x4"
      let unorm8x2 = Jstr.v "unorm8x2"
      let unorm8x4 = Jstr.v "unorm8x4"
      let snorm8x2 = Jstr.v "snorm8x2"
      let snorm8x4 = Jstr.v "snorm8x4"
      let uint16x2 = Jstr.v "uint16x2"
      let uint16x4 = Jstr.v "uint16x4"
      let sint16x2 = Jstr.v "sint16x2"
      let sint16x4 = Jstr.v "sint16x4"
      let unorm16x2 = Jstr.v "unorm16x2"
      let unorm16x4 = Jstr.v "unorm16x4"
      let snorm16x2 = Jstr.v "snorm16x2"
      let snorm16x4 = Jstr.v "snorm16x4"
      let float16x2 = Jstr.v "float16x2"
      let float16x4 = Jstr.v "float16x4"
      let float32 = Jstr.v "float32"
      let float32x2 = Jstr.v "float32x2"
      let float32x3 = Jstr.v "float32x3"
      let float32x4 = Jstr.v "float32x4"
      let uint32 = Jstr.v "uint32"
      let uint32x2 = Jstr.v "uint32x2"
      let uint32x3 = Jstr.v "uint32x3"
      let uint32x4 = Jstr.v "uint32x4"
      let sint32 = Jstr.v "sint32"
      let sint32x2 = Jstr.v "sint32x2"
      let sint32x3 = Jstr.v "sint32x3"
      let sint32x4 = Jstr.v "sint32x4"
    end
    module Step_mode = struct
      type t = Jstr.t
      let vertex = Jstr.v "vertex"
      let instance = Jstr.v "instance"
    end
    module Attribute = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ~format ~offset ~shader_location () =
        let a = Jv.obj [||] in
        Jv.Jstr.set a "format" format;
        Jv.Int.set a "offset" offset;
        Jv.Int.set a "shaderLocation" shader_location;
        a
    end
    module Buffer_layout = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?step_mode ~array_stride ~attributes () =
        let attributes = Jv.of_list Attribute.to_jv attributes in
        let l = Jv.obj [||] in
        Jv.Jstr.set_if_some l "stepMode" step_mode;
        Jv.set l "attributes" attributes;
        Jv.Int.set l "arrayStride" array_stride;
        l
    end
    module State = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?(constants = []) ~buffers ~module' ~entry_point () =
        let buffers = Jv.of_list Buffer_layout.to_jv buffers in
        let p = Jv.obj [||] in
        Jv.set p "buffers" buffers;
        Jv.set p "module" module';
        Jv.Jstr.set p "entryPoint" entry_point;
        Jv.set p "constants" (Programmable_stage.constants_obj constants);
        p
    end
  end

  module Blend = struct
    module Factor = struct
      type t = Jstr.t
      let zero = Jstr.v "zero"
      let one = Jstr.v "one"
      let src = Jstr.v "src"
      let one_minus_src = Jstr.v "one-minus-src"
      let src_alpha = Jstr.v "src-alpha"
      let one_minus_src_alpha = Jstr.v "one-minus-src-alpha"
      let dst = Jstr.v "dst"
      let one_minus_dst = Jstr.v "one-minus-dst"
      let dst_alpha = Jstr.v "dst-alpha"
      let one_minus_dst_alpha = Jstr.v "one-minus-dst-alpha"
      let src_alpha_saturated = Jstr.v "src-alpha-saturated"
      let constant = Jstr.v "constant"
      let one_minus_constant = Jstr.v "one-minus-constant"
    end
    module Operation = struct
      type t = Jstr.t
      let add = Jstr.v "add"
      let subtract = Jstr.v "subtract"
      let reverse_subtract = Jstr.v "reverse-subtract"
      let min = Jstr.v "min"
      let max = Jstr.v "max"
    end
    module Component = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?operation ?src_factor ?dst_factor () =
        let c = Jv.obj [||] in
        Jv.Jstr.set_if_some c "add" operation;
        Jv.Jstr.set_if_some c "srcFactor" src_factor;
        Jv.Jstr.set_if_some c "dstFactor" dst_factor;
        c
    end
    module State = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?color ?alpha () =
        let c = Jv.obj [||] in
        Jv.set_if_some c "color" (Option.map Component.to_jv color);
        Jv.set_if_some c "alpha" (Option.map Component.to_jv alpha);
        c
    end
  end

  module Color = struct
    module Write = struct
      type t = int
      let red   = 0x1
      let green = 0x2
      let blue  = 0x4
      let alpha = 0x8
      let all   = 0xF
    end
    module Target_state = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?blend ?write_mask ~format () =
        let s = Jv.obj [||] in
        Jv.set s "format" (Texture.Format.to_jv format);
        Jv.set_if_some s "blend" (Option.map Blend.State.to_jv blend);
        Jv.Int.set_if_some s "writeMask" write_mask;
        s
    end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let v ~r ~g ~b ~a =
      let c = Jv.obj [||] in
      Jv.Float.set c "r" r; Jv.Float.set c "g" g; Jv.Float.set c "b" b;
      Jv.Float.set c "a" a; c
  end

  module Stencil = struct
    module Operation = struct
      type t = Jstr.t
      let keep = Jstr.v "keep"
      let zero = Jstr.v "zero"
      let replace = Jstr.v "replace"
      let invert = Jstr.v "invert"
      let increment_clamp = Jstr.v "increment-clamp"
      let decrement_clamp = Jstr.v "decrement-clamp"
      let increment_wrap = Jstr.v "increment-wrap"
      let decrement_wrap = Jstr.v "decrement-wrap"
    end
    module Face_state = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?compare ?fail_op ?depth_fail_op ?pass_op () =
        let s = Jv.obj [||] in
        Jv.Jstr.set_if_some s "compare" compare;
        Jv.Jstr.set_if_some s "failOp" fail_op;
        Jv.Jstr.set_if_some s "depthFailOp" depth_fail_op;
        Jv.Jstr.set_if_some s "passOp" pass_op;
        s
    end
  end

  module Depth_stencil_state = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let v
        ?stencil_front ?stencil_back ?stencil_read_mask ?stencil_write_mask
        ?depth_bias ?depth_bias_slope_scale ?depth_bias_clamp ~format
        ~depth_write_enabled ~depth_compare ()
      =
      let s = Jv.obj [||] in
      Jv.Jstr.set s "format" format;
      Jv.Bool.set s "depthWriteEnabled" depth_write_enabled;
      Jv.Jstr.set s "depthCompare" depth_compare;
      Jv.set_if_some s "stencilFront" stencil_front;
      Jv.set_if_some s "stencilBack" stencil_back;
      Jv.Int.set_if_some s "stencilReadMask" stencil_read_mask;
      Jv.Int.set_if_some s "stencilWriteMask" stencil_write_mask;
      Jv.Int.set_if_some s "depthBias" depth_bias;
      Jv.Int.set_if_some s "depthBiasSlopeScale" depth_bias_slope_scale;
      Jv.Int.set_if_some s "depthBiasClamp" depth_bias_clamp;
      s
  end

  module Multisample_state = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let v ?count ?mask ?alpha_to_coverage_enabled () =
      let s = Jv.obj [||] in
      Jv.Int.set_if_some s "count" count;
      Jv.Int.set_if_some s "mask" mask;
      Jv.Bool.set_if_some s "alphaToCoverageEnabled" alpha_to_coverage_enabled;
      s
  end

  module Fragment_state = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let v ?(constants = []) ~targets ~module' ~entry_point () =
      let targets = Jv.of_list Color.Target_state.to_jv targets in
      let p = Jv.obj [||] in
      Jv.set p "targets" targets;
      Jv.set p "module" module';
      Jv.Jstr.set p "entryPoint" entry_point;
      Jv.set p "constants" (Programmable_stage.constants_obj constants);
      p
  end

  module Render_pipeline = struct
    module Descriptor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v
          ?label ?primitive ?depth_stencil ?multisample ?fragment ~layout
          ~vertex ()
        =
        let d = Jv.obj [||] in
        Jv.Jstr.set_if_some d "label" label;
        begin match layout with
        | `Auto -> Jv.Jstr.set d "layout" (Jstr.v "auto")
        | `Layout l -> Jv.set d "layout" (Pipeline_layout.to_jv l)
        end;
        Jv.set d "vertex" (Vertex.State.to_jv vertex);
        let m = Option.map in
        Jv.set_if_some d "primitive" (m Primitive.State.to_jv primitive);
        Jv.set_if_some d "multisample" (m Multisample_state.to_jv multisample);
        Jv.set_if_some d "depthStencil"
          (m Depth_stencil_state.to_jv depth_stencil);
        Jv.set_if_some d "fragment" (m Fragment_state.to_jv fragment);
        d
    end

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let label p = Jv.Jstr.get p "label"
    let get_bind_group_layout p i =
      Bind_group.Layout.of_jv @@ Jv.call p "getBindGroupLayout" [|Jv.of_int i|]
  end

  (* Issuing commands *)

  (* Queries *)

  module Query = struct
    module Type = struct
      type t = Jstr.t
      let occlusion = Jstr.v "occlusion"
      let timestamp = Jstr.v "timestamp"
    end
    module Set = struct
      module Descriptor = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v ?label ~type' ~count () =
          let d = Jv.obj [||] in
          Jv.Jstr.set_if_some d "label" label;
          Jv.Jstr.set d "type" type';
          Jv.Int.set d "count" count;
          d
      end
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let label s = Jv.Jstr.get s "label"
      let type' s = Jv.Jstr.get s "type"
      let count s = Jv.Int.get s "count"
      let destroy s = ignore @@ Jv.call s "destroy" [||]
    end
  end

  (* Passes *)

  module Compute_pass = struct
    module Timestamp_writes = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v
          ?beginning_of_pass_write_index ?end_of_pass_write_index ~query_set ()
        =
        let w = Jv.obj [||] in
        Jv.set w "querySet" (Query.Set.to_jv query_set);
        Jv.Int.set_if_some w "beginningOfPassWriteIndex"
          beginning_of_pass_write_index;
        Jv.Int.set_if_some w "endOfPassWriteIndex" end_of_pass_write_index;
        w
    end
    module Descriptor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?label ~timestamp_writes () =
        let d = Jv.obj [||] in
        Jv.Jstr.set_if_some d "label" label;
        Jv.set d "timestampWrites" timestamp_writes;
        d
    end
    module Encoder = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let label e = Jv.Jstr.get e "label"
      let set_pipeline e p =
        ignore @@ Jv.call e "setPipeline" [| Compute_pipeline.to_jv p |]

      let dispatch_workgroups ?(count_z = 1) ?(count_y = 1) e ~count_x =
        let count_x = Jv.of_int count_x and count_y = Jv.of_int count_y
        and count_z = Jv.of_int count_z in
        ignore @@ Jv.call e "dispatchWorkgroups" [| count_x; count_y; count_z |]

      let dispatch_workgroups_indirect e buf ~offset =
        let buf = Buffer.to_jv buf and offset = Jv.of_int offset in
        ignore @@ Jv.call e "dispatchWorkgroupsIndirect" [| buf; offset |]

      let end' e = ignore @@ Jv.call e "end" [||]

      let set_bind_group ?(dynamic_offsets = []) ?group e ~index =
        let index = Jv.of_int index in
        let group = Jv.of_option ~none:Jv.undefined Bind_group.to_jv group in
        let dynamic_offsets = Jv.of_list Jv.of_int dynamic_offsets in
        ignore @@ Jv.call e "setBindGroup" [|index; group; dynamic_offsets|]

      let set_bind_group'
          ?group e ~index ~dynamic_offsets ~offsets_start ~offsets_length
        =
        let index = Jv.of_int index in
        let group = Jv.of_option ~none:Jv.undefined Bind_group.to_jv group in
        let dynamic_offsets = Jv.of_array Jv.of_int dynamic_offsets in
        let offsets_start = Jv.of_int offsets_start in
        let offsets_length = Jv.of_int offsets_length in
        ignore @@ Jv.call e "setBindGroup"
          [| index; group; dynamic_offsets; offsets_start; offsets_length |]

      let push_debug_group e label =
        ignore @@ Jv.call e "pushDebugGroup" [| Jv.of_jstr label |]

      let pop_debug_group e = ignore @@ Jv.call e "popDebugGroup" [||]

      let insert_debug_marker e marker =
        ignore @@ Jv.call e "insertDebugMarker" [| Jv.of_jstr marker |]
    end
  end

  module Render_bundle = struct
    module Descriptor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?label () =
        let d = Jv.obj [||] in
        Jv.Jstr.set_if_some d "label" label;
        d
    end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let label b = Jv.Jstr.get b "label"

    module Encoder = struct
      module Descriptor = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v
            ?label ?(color_formats = []) ?depth_stencil_format ?sample_count
            ?depth_read_only ?stencil_read_only () =
          let d = Jv.obj [||] in
          let color_formats = Jv.of_list Texture.Format.to_jv color_formats in
          Jv.Jstr.set_if_some d "label" label;
          Jv.set d "colorFormats" color_formats;
          Jv.set_if_some d "depthStencilFormat"
            (Option.map Texture.Format.to_jv depth_stencil_format);
          Jv.Int.set_if_some d "sampleCount" sample_count;
          Jv.Bool.set_if_some d "depthReadOnly" depth_read_only;
          Jv.Bool.set_if_some d "stencilReadOnly" stencil_read_only;
          d
      end

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)

      let label e = Jv.Jstr.get e "label"

      let set_pipeline e p =
        ignore @@ Jv.call e "setPipeline" [| Compute_pipeline.to_jv p |]

      let finish ?(descr = Jv.undefined) e =
        of_jv @@ Jv.call e "finish" [| e |]

      let set_bind_group ?(dynamic_offsets = []) ?group e ~index =
        let index = Jv.of_int index in
        let group = Jv.of_option ~none:Jv.undefined Bind_group.to_jv group in
        let dynamic_offsets = Jv.of_list Jv.of_int dynamic_offsets in
        ignore @@ Jv.call e "setBindGroup" [|index; group; dynamic_offsets|]

      let set_bind_group'
          ?group e ~index ~dynamic_offsets ~offsets_start ~offsets_length
        =
        let index = Jv.of_int index in
        let group = Jv.of_option ~none:Jv.undefined Bind_group.to_jv group in
        let dynamic_offsets = Jv.of_array Jv.of_int dynamic_offsets in
        let offsets_start = Jv.of_int offsets_start in
        let offsets_length = Jv.of_int offsets_length in
        ignore @@ Jv.call e "setBindGroup"
          [|index; group; dynamic_offsets; offsets_start; offsets_length |]

      let set_index_buffer ?(offset = 0) ?size e buffer ~format =
        let buffer = Buffer.to_jv buffer and format = Jv.of_jstr format in
        let offset = Jv.of_int offset in
        let size = Jv.of_option ~none:Jv.undefined Jv.of_int size in
        ignore @@ Jv.call e "setIndexBuffer" [|buffer; format; offset; size|]

      let set_vertex_buffer ?buffer ?(offset = 0) ?size e ~slot =
        let slot = Jv.of_int slot in
        let buffer = Jv.of_option ~none:Jv.undefined Buffer.to_jv buffer in
        let offset = Jv.of_int offset in
        let size = Jv.of_option ~none:Jv.undefined Jv.of_int size in
        ignore @@ Jv.call e "setVertexBuffer" [|slot; buffer; offset; size|]

      let draw
          ?(first_instance = 0) ?(first_vertex = 0) ?(instance_count = 0) e
          ~vertex_count =
        let vertex_count = Jv.of_int vertex_count in
        let instance_count = Jv.of_int instance_count in
        let first_vertex = Jv.of_int first_vertex in
        let first_instance = Jv.of_int first_instance in
        ignore @@ Jv.call e "draw"
          [|vertex_count; instance_count; first_vertex; first_instance|]

      let draw_indexed
          ?(first_instance = 0) ?(base_vertex = 0) ?(first_index = 0)
          ?(instance_count = 1) e ~index_count
        =
        let index_count = Jv.of_int index_count in
        let instance_count = Jv.of_int instance_count in
        let first_index = Jv.of_int first_index in
        let base_vertex = Jv.of_int base_vertex in
        let first_instance = Jv.of_int first_instance in
        ignore @@ Jv.call e "drawIndexed"
          [|index_count; instance_count; first_index; base_vertex;
            first_instance|]

      let draw_indirect e buffer ~offset =
        let buffer = Buffer.to_jv buffer and offset = Jv.of_int offset in
        ignore @@ Jv.call e "drawIndirect" [|buffer; offset|]

      let draw_indexed_indirect e buffer ~offset =
        let buffer = Buffer.to_jv buffer and offset = Jv.of_int offset in
        ignore @@ Jv.call e "drawIndexedIndirect" [|buffer; offset|]

      let push_debug_group e label =
        ignore @@ Jv.call e "pushDebugGroup" [| Jv.of_jstr label |]

      let pop_debug_group e = ignore @@ Jv.call e "popDebugGroup" [||]

      let insert_debug_marker e marker =
        ignore @@ Jv.call e "insertDebugMarker" [| Jv.of_jstr marker |]
    end
  end

  module Render_pass = struct
    module Load_op = struct
      type t = Jstr.t
      let load = Jstr.v "load"
      let clear = Jstr.v "clear"
    end
    module Store_op = struct
      type t = Jstr.t
      let store = Jstr.v "store"
      let discard = Jstr.v "discard"
    end
    module Timestamp_writes = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v
          ?beginning_of_pass_write_index ?end_of_pass_write_index ~query_set ()
        =
        let w = Jv.obj [||] in
        Jv.set w "querySet" (Query.Set.to_jv query_set);
        Jv.Int.set_if_some w "beginningOfPassWriteIndex"
          beginning_of_pass_write_index;
        Jv.Int.set_if_some w "endOfPassWriteIndex" end_of_pass_write_index;
        w
    end
    module Color_attachment = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?resolve_target ?clear_value ~view ~load_op ~store_op () =
        let a = Jv.obj [||] in
        let m = Option.map in
        Jv.set a "view" (Texture.View.to_jv view);
        Jv.set_if_some a "resolveTarget" (m Texture.View.to_jv resolve_target);
        Jv.set_if_some a "clearValue" (m Color.to_jv clear_value);
        Jv.Jstr.set a "loadOp" load_op;
        Jv.Jstr.set a "storeOp" store_op;
        a
    end
    module Depth_stencil_attachment = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v
          ?depth_clear_value ?depth_load_op ?depth_store_op
          ?depth_read_only ?stencil_clear_value ?stencil_load_op
          ?stencil_store_op ?stencil_read_only ~view ()
        =
        let a = Jv.obj [||] in
        Jv.set a "view" (Texture.View.to_jv view);
        Jv.Float.set_if_some a "depthClearValue" depth_clear_value;
        Jv.Jstr.set_if_some a "depthLoadOp" depth_load_op;
        Jv.Jstr.set_if_some a "depthStoreOp" depth_store_op;
        Jv.Bool.set_if_some a "depthReadOnly" depth_read_only;
        Jv.Int.set_if_some a "stencilClearValue" stencil_clear_value;
        Jv.Jstr.set_if_some a "stencilLoadOp" stencil_load_op;
        Jv.Jstr.set_if_some a "stencilStoreOp" stencil_store_op;
        Jv.Bool.set_if_some a "stencilReadOnly" stencil_read_only;
        a
    end
    module Descriptor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v
          ?label ?depth_stencil_attachment ?occlusion_query_set
          ?timestamp_writes ?max_draw_count ~color_attachments:cs ()
        =
        let d = Jv.obj [||] in
        let m = Option.map in
        let color_attachments = Jv.of_list Color_attachment.to_jv cs in
        Jv.Jstr.set_if_some d "label" label;
        Jv.set d "colorAttachments" color_attachments;
        Jv.set_if_some d "depthStencilAttachment"
          (m Depth_stencil_attachment.to_jv depth_stencil_attachment);
        Jv.set_if_some d "occlusionQuerySet"
          (m Query.Set.to_jv occlusion_query_set);
        Jv.set_if_some d "timestampWrites"
          (m Timestamp_writes.to_jv timestamp_writes);
        Jv.Int.set_if_some d "maxDrawCount" max_draw_count;
        d
    end
    module Encoder = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)

      let label e = Jv.Jstr.get e "label"
      let set_pipeline e p =
        ignore @@ Jv.call e "setPipeline" [| Compute_pipeline.to_jv p |]

      let end' e = ignore @@ Jv.call e "end" [||]
      let set_viewport e ~x ~y ~w ~h ~min_depth ~max_depth =
        let x = Jv.of_float x and y = Jv.of_float y in
        let w = Jv.of_float w and h = Jv.of_float h in
        let min_depth = Jv.of_float min_depth in
        let max_depth = Jv.of_float max_depth in
        ignore @@ Jv.call e "setViewport" [|x; y; w; h; min_depth; max_depth|]

      let set_scissor_rect e ~x ~y ~w ~h =
        let x = Jv.of_int x and y = Jv.of_int y in
        let w = Jv.of_int w and h = Jv.of_int h in
        ignore @@ Jv.call e "setScissorRect" [|x; y; w; h|]

      let set_blend_constant e color =
        ignore @@ Jv.call e "setBlendConstant" [| Color.to_jv color |]

      let set_stencil_reference e ref =
        ignore @@ Jv.call e "setStencilReference" [| Jv.of_int ref |]

      let set_bind_group ?(dynamic_offsets = []) ?group e ~index =
        let index = Jv.of_int index in
        let group = Jv.of_option ~none:Jv.undefined Bind_group.to_jv group in
        let dynamic_offsets = Jv.of_list Jv.of_int dynamic_offsets in
        ignore @@ Jv.call e "setBindGroup" [|index; group; dynamic_offsets|]

      let set_bind_group'
          ?group e ~index ~dynamic_offsets ~offsets_start ~offsets_length
        =
        let index = Jv.of_int index in
        let group = Jv.of_option ~none:Jv.undefined Bind_group.to_jv group in
        let dynamic_offsets = Jv.of_array Jv.of_int dynamic_offsets in
        let offsets_start = Jv.of_int offsets_start in
        let offsets_length = Jv.of_int offsets_length in
        ignore @@ Jv.call e "setBindGroup"
          [| index; group; dynamic_offsets; offsets_start; offsets_length |]

      let set_index_buffer ?(offset = 0) ?size e buffer ~format =
        let buffer = Buffer.to_jv buffer and format = Jv.of_jstr format in
        let offset = Jv.of_int offset in
        let size = Jv.of_option ~none:Jv.undefined Jv.of_int size in
        ignore @@ Jv.call e "setIndexBuffer" [| buffer; format; offset; size |]

      let set_vertex_buffer ?buffer ?(offset = 0) ?size e ~slot =
        let slot = Jv.of_int slot in
        let buffer = Jv.of_option ~none:Jv.undefined Buffer.to_jv buffer in
        let offset = Jv.of_int offset in
        let size = Jv.of_option ~none:Jv.undefined Jv.of_int size in
        ignore @@ Jv.call e "setVertexBuffer" [| slot; buffer; offset; size |]

      let begin_occlusion_query e i =
        ignore @@ Jv.call e "beginOcclusionQuery" [| Jv.of_int i |]

      let end_occlusion_query e =
        ignore @@ Jv.call e "endOcclusionQuery" [||]

      let execute_bundles e bundles =
        let bundles = Jv.of_list Render_bundle.to_jv bundles in
        ignore @@ Jv.call e "executeBundles" [| bundles |]

      let draw
          ?(first_instance = 0) ?(first_vertex = 0) ?(instance_count = 0) e
          ~vertex_count =
        let vertex_count = Jv.of_int vertex_count in
        let instance_count = Jv.of_int instance_count in
        let first_vertex = Jv.of_int first_vertex in
        let first_instance = Jv.of_int first_instance in
        ignore @@ Jv.call e "draw"
          [| vertex_count; instance_count; first_vertex; first_instance |]

      let draw_indexed
          ?(first_instance = 0) ?(base_vertex = 0) ?(first_index = 0)
          ?(instance_count = 1) e ~index_count
        =
        let index_count = Jv.of_int index_count in
        let instance_count = Jv.of_int instance_count in
        let first_index = Jv.of_int first_index in
        let base_vertex = Jv.of_int base_vertex in
        let first_instance = Jv.of_int first_instance in
        ignore @@ Jv.call e "drawIndexed"
          [| index_count; instance_count; first_index; base_vertex;
             first_instance |]

      let draw_indirect e buffer ~offset =
        let buffer = Buffer.to_jv buffer and offset = Jv.of_int offset in
        ignore @@ Jv.call e "drawIndirect" [| buffer; offset |]

      let draw_indexed_indirect e buffer ~offset =
        let buffer = Buffer.to_jv buffer and offset = Jv.of_int offset in
        ignore @@ Jv.call e "drawIndexedIndirect" [| buffer; offset |]

      let push_debug_group e label =
        ignore @@ Jv.call e "pushDebugGroup" [| Jv.of_jstr label |]

      let pop_debug_group e = ignore @@ Jv.call e "popDebugGroup" [||]

      let insert_debug_marker e marker =
        ignore @@ Jv.call e "insertDebugMarker" [| Jv.of_jstr marker |]
    end
  end

  (* Commands and queues *)

  module Command = struct
    module Buf = Buffer
    module Buffer = struct
      module Descriptor = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v ?label () =
          let d = Jv.obj [||] in
          Jv.Jstr.set_if_some d "label" label;
          d
      end
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let label q = Jv.Jstr.get q "label"
    end
    module Encoder = struct
      module Descriptor = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v ?label () =
          let d = Jv.obj [||] in
          Jv.Jstr.set_if_some d "label" label;
          d
      end
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let label q = Jv.Jstr.get q "label"

      let finish ?(descr = Jv.undefined) e =
        Buffer.of_jv @@ Jv.call e "finish" [| descr |]

      let begin_render_pass e d =
        let d = Render_pass.Descriptor.to_jv d in
        Render_pass.Encoder.of_jv @@ Jv.call e "beginRenderPass" [| d |]

      let begin_compute_pass e d =
        let d = Compute_pass.Descriptor.to_jv d in
        Compute_pass.Encoder.of_jv @@ Jv.call e "beginComputePass" [| d |]

      let copy_buffer_to_buffer e ~src ~src_offset ~dst ~dst_offset ~size =
        let src = Buf.to_jv src and src_offset = Jv.of_int src_offset in
        let dst = Buf.to_jv dst and dst_offset = Jv.of_int dst_offset in
        let size = Jv.of_int size in
        ignore @@ Jv.call e "copyBufferToBuffer"
          [| src; src_offset; dst; dst_offset; size |]

      let copy_buffer_to_texture e ~src ~dst ~size =
        let src = Image.Copy_buffer.to_jv src in
        let dst = Image.Copy_texture.to_jv dst in
        let size = Extent_3d.to_jv size in
        ignore @@ Jv.call e "copyBufferToTexture" [| src; dst; size |]

      let copy_texture_to_buffer e ~src ~dst ~size =
        let src = Image.Copy_texture.to_jv src in
        let dst = Image.Copy_buffer.to_jv dst in
        let size = Extent_3d.to_jv size in
        ignore @@ Jv.call e "copyTextureToBuffer" [| src; dst; size |]

      let copy_texture_to_texture e ~src ~dst ~size =
        let src = Image.Copy_texture.to_jv src in
        let dst = Image.Copy_texture.to_jv dst in
        let size = Extent_3d.to_jv size in
        ignore @@ Jv.call e "TextureToTexture" [| src; dst; size |]

      let clear_buffer ?size ?(offset = 0) e buffer  =
        let buffer = Buf.to_jv buffer and offset = Jv.of_int offset in
        let size = Jv.of_option ~none:Jv.undefined Jv.of_int size in
        ignore @@ Jv.call e "clearBuffer" [| buffer; offset; size |]

      let write_timestamp e qs i =
        let qs = Query.Set.to_jv qs and i = Jv.of_int i in
        ignore @@ Jv.call e "writeTimestamp" [| qs; i |]

      let resolve_query_set e qs ~first ~count ~dst ~dst_offset =
        let qs = Query.Set.to_jv qs in
        let first = Jv.of_int first and count = Jv.of_int count in
        let dst = Buf.to_jv dst and dst_offset = Jv.of_int dst_offset in
        ignore @@ Jv.call e "resolveQuerySet"
          [| qs; first; count; dst; dst_offset |]

      let push_debug_group e label =
        ignore @@ Jv.call e "pushDebugGroup" [| Jv.of_jstr label |]

      let pop_debug_group e = ignore @@ Jv.call e "popDebugGroup" [||]

      let insert_debug_marker e marker =
        ignore @@ Jv.call e "insertDebugMarker" [| Jv.of_jstr marker |]
    end
  end

  (* GPU queues *)

  module Queue = struct
    module Descriptor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?label () =
        let d = Jv.obj [||] in
        Jv.Jstr.set_if_some d "label" label;
        d
    end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let label q = Jv.Jstr.get q "label"

    let submit q buffers =
      let buffers = Jv.of_list Command.Buffer.to_jv buffers in
      ignore @@ Jv.call q "submit" [| buffers |]

    let on_submitted_work_done q =
      Fut.of_promise ~ok:ignore @@ Jv.call q "onSubmittedWorkDone" [||]

    let write_buffer ?(src_offset = 0) ?size q ~dst ~dst_offset ~src =
      let dst = Buffer.to_jv dst and dst_offset = Jv.of_int dst_offset in
      let src = Brr.Tarray.to_jv src in
      let src_offset = Jv.of_int src_offset in
      let size = match size with
      | None -> Jv.undefined | Some size -> Jv.of_int size
      in
      let args = [| dst; dst_offset; src; src_offset; size |] in
      ignore @@ Jv.call q "writeBuffer" args

    let write_texture q ~dst ~src ~src_layout ~size =
      let dst = Image.Copy_texture.to_jv dst in
      let src = Brr.Tarray.to_jv src in
      let src_layout = Image.Data_layout.to_jv src_layout in
      let size = Extent_3d.to_jv size in
      ignore @@ Jv.call q "writeTexture" [|dst; src; src_layout; size|]

    let copy_external_image_to_texture q ~src ~dst ~size =
      let src = Image.Copy_external_image.to_jv src in
      let dst = Image.Copy_texture_tagged.to_jv dst in
      let size = Extent_3d.to_jv size in
      ignore @@ Jv.call q "copyExternalImageToTexture" [|src; dst; size|]
  end

  (* Adapters and devices *)

  module Supported_limits = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let max_texture_dimension_1d l = Jv.Int.get l "maxTextureDimension1D"
    let max_texture_dimension_2d l = Jv.Int.get l "maxTextureDimension2D"
    let max_texture_dimension_3d l = Jv.Int.get l "maxTextureDimension3D"
    let max_texture_array_layers l = Jv.Int.get l "maxTextureArrayLayers"
    let max_bind_groups l = Jv.Int.get l "maxBindGroups"
    let max_bind_groups_plus_vertex_buffers l =
      Jv.Int.get l "maxBindGroupsPlusVertexBuffers"
    let max_bindings_per_bind_group l = Jv.Int.get l "maxBindingsPerBindGroup"
    let max_dynamic_uniform_buffers_per_pipeline_layout l =
      Jv.Int.get l "maxDynamicUniformBuffersPerPipelineLayout"
    let max_dynamic_storage_buffers_per_pipeline_layout l =
      Jv.Int.get l "maxDynamicStorageBuffersPerPipelineLayout"
    let max_sampled_textures_per_shader_stage l =
      Jv.Int.get l "maxSampledTexturesPerShaderStage"
    let max_samplers_per_shader_stage l =
      Jv.Int.get l "maxSamplersPerShaderStage"
    let max_storage_buffers_per_shader_stage l =
      Jv.Int.get l "maxStorageBuffersPerShaderStage"
    let max_storage_textures_per_shader_stage l =
      Jv.Int.get l "maxStorageTexturesPerShaderStage"
    let max_uniform_buffers_per_shader_stage l =
      Jv.Int.get l "maxUniformBuffersPerShaderStage"
    let max_uniform_buffer_binding_size l =
      Jv.Int.get l "maxUniformBufferBindingSize"
    let max_storage_buffer_binding_size l =
      Jv.Int.get l "maxStorageBufferBindingSize"
    let min_uniform_buffer_offset_alignment l =
      Jv.Int.get l "minUniformBufferOffsetAlignment"
    let min_storage_buffer_offset_alignment l =
      Jv.Int.get l "minStorageBufferOffsetAlignment"
    let max_vertex_buffers l = Jv.Int.get l "maxVertexBuffers"
    let max_buffer_size l = Jv.Int.get l "maxBufferSize"
    let max_vertex_attributes l = Jv.Int.get l "maxVertexAttributes"
    let max_vertex_buffer_array_stride l =
      Jv.Int.get l "maxVertexBufferArrayStride"
    let max_inter_stage_shader_components l =
      Jv.Int.get l "maxInterStageShaderComponents"
    let max_inter_stage_shader_variables l =
      Jv.Int.get l "maxInterStageShaderVariables"
    let max_color_attachments l =
      Jv.Int.get l "maxColorAttachments"
    let max_color_attachment_bytes_per_sample l =
      Jv.Int.get l "maxColorAttachmentBytesPerSample"
    let max_compute_workgroup_storage_size l =
      Jv.Int.get l "maxComputeWorkgroupStorageSize"
    let max_compute_invocations_per_workgroup l =
      Jv.Int.get l "maxComputeInvocationsPerWorkgroup"
    let max_compute_workgroup_size_x l = Jv.Int.get l "maxComputeWorkgroupSizeX"
    let max_compute_workgroup_size_y l = Jv.Int.get l "maxComputeWorkgroupSizeY"
    let max_compute_workgroup_size_z l = Jv.Int.get l "maxComputeWorkgroupSizeZ"
    let max_compute_workgroups_per_dimension l =
      Jv.Int.get l "maxComputeWorkgroupsPerDimension"
  end

  module Feature_name = struct
    type t = Jstr.t
    let depth_clip_control = Jstr.v "depth-clip-control"
    let depth32float_stencil8 = Jstr.v "depth32float-stencil8"
    let texture_compression_bc = Jstr.v "texture-compression-bc"
    let texture_compression_etc2 = Jstr.v "texture-compression-etc2"
    let texture_compression_astc = Jstr.v "texture-compression-astc"
    let timestamp_query = Jstr.v "timestamp-query"
    let indirect_first_instance = Jstr.v "indirect-first-instance"
    let shader_f16 = Jstr.v "shader-f16"
    let rg11b10ufloat_renderable = Jstr.v "rg11b10ufloat-renderable"
    let bgra8unorm_storage = Jstr.v "bgra8unorm-storage"
    let float32_filterable = Jstr.v "float32-filterable"
    include (Jv.Id : Jv.CONV with type t := t)
  end

  module Error = struct
    module Filter = struct
      type t = Jstr.t
      let validation = Jstr.v "validation"
      let out_of_memory = Jstr.v "out-of-memory"
      let internal = Jstr.v "internal"
    end

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let message i = Jv.Jstr.get i "message"
  end

  module Pipeline_error = struct
    module Reason = struct
      type t = Jstr.t
      let validation = Jstr.v "validation"
      let internal = Jstr.v "internal"
    end
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let message i = Jv.Jstr.get i "message"
    let reason i = Jv.Jstr.get i "reason"
  end

  module Device = struct
    module Lost_reason = struct
      type t = Jstr.t
      let unknown = Jstr.v "unknown"
      let destroyed = Jstr.v "destroyed"
    end
    module Lost_info = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let reason i = Jv.Jstr.get i "reason"
      let message i = Jv.Jstr.get i "message"
    end
    module Descriptor = struct
      type required_limits = Jv.t
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let v ?label ?required_features:rf ?required_limits ?default_queue () =
        let rf = Option.map (Jv.of_list Feature_name.to_jv) rf in
        let d = Jv.obj [||] in
        Jv.Jstr.set_if_some d "label" label;
        Jv.set_if_some d "requiredFeatures" rf;
        Jv.set_if_some d "requiredLimits" required_limits;
        Jv.set_if_some d "defaultQueue" default_queue;
        d

      let required_limits
          ?max_texture_dimension_1d ?max_texture_dimension_2d
          ?max_texture_dimension_3d ?max_texture_array_layers
          ?max_bind_groups ?max_bind_groups_plus_vertex_buffers
          ?max_bindings_per_bind_group
          ?max_dynamic_uniform_buffers_per_pipeline_layout
          ?max_dynamic_storage_buffers_per_pipeline_layout
          ?max_sampled_textures_per_shader_stage ?max_samplers_per_shader_stage
          ?max_storage_buffers_per_shader_stage
          ?max_storage_textures_per_shader_stage
          ?max_uniform_buffers_per_shader_stage
          ?max_uniform_buffer_binding_size ?max_storage_buffer_binding_size
          ?min_uniform_buffer_offset_alignment
          ?min_storage_buffer_offset_alignment ?max_vertex_buffers
          ?max_buffer_size ?max_vertex_attributes
          ?max_vertex_buffer_array_stride
          ?max_inter_stage_shader_components ?max_inter_stage_shader_variables
          ?max_color_attachments ?max_color_attachment_bytes_per_sample
          ?max_compute_workgroup_storage_size
          ?max_compute_invocations_per_workgroup
          ?max_compute_workgroup_size_x ?max_compute_workgroup_size_y
          ?max_compute_workgroup_size_z
          ?max_compute_workgroups_per_dimension ()
        =
        let l = Jv.obj [||] in
        Jv.Int.set_if_some l "maxTextureDimension1D" max_texture_dimension_1d;
        Jv.Int.set_if_some l "maxTextureDimension2D" max_texture_dimension_2d;
        Jv.Int.set_if_some l "maxTextureDimension3D" max_texture_dimension_3d;
        Jv.Int.set_if_some l "maxTextureArrayLayers" max_texture_array_layers;
        Jv.Int.set_if_some l "maxBindGroups" max_bind_groups;
        Jv.Int.set_if_some l "maxBindGroupsPlusVertexBuffers"
          max_bind_groups_plus_vertex_buffers;
        Jv.Int.set_if_some l "maxBindingsPerBindGroup"
          max_bindings_per_bind_group;
        Jv.Int.set_if_some l "maxDynamicUniformBuffersPerPipelineLayout"
          max_dynamic_uniform_buffers_per_pipeline_layout;
        Jv.Int.set_if_some l "maxDynamicStorageBuffersPerPipelineLayout"
          max_dynamic_storage_buffers_per_pipeline_layout;
        Jv.Int.set_if_some l "maxSampledTexturesPerShaderStage"
          max_sampled_textures_per_shader_stage;
        Jv.Int.set_if_some l "maxSamplersPerShaderStage"
          max_samplers_per_shader_stage;
        Jv.Int.set_if_some l "maxStorageBuffersPerShaderStage"
          max_storage_buffers_per_shader_stage;
        Jv.Int.set_if_some l "maxStorageTexturesPerShaderStage"
          max_storage_textures_per_shader_stage;
        Jv.Int.set_if_some l "maxUniformBuffersPerShaderStage"
          max_uniform_buffers_per_shader_stage;
        Jv.Int.set_if_some l "maxUniformBufferBindingSize"
          max_uniform_buffer_binding_size;
        Jv.Int.set_if_some l "maxStorageBufferBindingSize"
          max_storage_buffer_binding_size;
        Jv.Int.set_if_some l "minUniformBufferOffsetAlignment"
          min_uniform_buffer_offset_alignment;
        Jv.Int.set_if_some l "minStorageBufferOffsetAlignment"
          min_storage_buffer_offset_alignment;
        Jv.Int.set_if_some l "maxVertexBuffers" max_vertex_buffers;
        Jv.Int.set_if_some l "maxBufferSize" max_buffer_size;
        Jv.Int.set_if_some l "maxVertexAttributes" max_vertex_attributes;
        Jv.Int.set_if_some l "maxVertexBufferArrayStride"
          max_vertex_buffer_array_stride;
        Jv.Int.set_if_some l "maxInterStageShaderComponents"
          max_inter_stage_shader_components;
        Jv.Int.set_if_some l "maxInterStageShaderVariables"
          max_inter_stage_shader_variables;
        Jv.Int.set_if_some l "maxColorAttachments" max_color_attachments;
        Jv.Int.set_if_some l "maxColorAttachmentBytesPerSample"
          max_color_attachment_bytes_per_sample;
        Jv.Int.set_if_some l "maxComputeWorkgroupStorageSize"
          max_compute_workgroup_storage_size;
        Jv.Int.set_if_some l "maxComputeInvocationsPerWorkgroup"
          max_compute_invocations_per_workgroup;
        Jv.Int.set_if_some l "maxComputeWorkgroupSizeX"
          max_compute_workgroup_size_x;
        Jv.Int.set_if_some l "maxComputeWorkgroupSizeY"
          max_compute_workgroup_size_y;
        Jv.Int.set_if_some l "maxComputeWorkgroupSizeZ"
          max_compute_workgroup_size_z;
        Jv.Int.set_if_some l "maxComputeWorkgroupsPerDimension"
          max_compute_workgroups_per_dimension;
        l
    end

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    external as_target : t -> Brr.Ev.target = "%identity"
    let has_feature d f =
      let set = Jv.get d "features" in
      if Jv.is_none set then false else
      Jv.to_bool (Jv.call set "has" [|Jv.of_jstr f|])

    let label d = Jv.Jstr.get d "label"
    let limits d = Jv.get d "limits"
    let queue d = Jv.get d "queue"
    let destroy d = ignore @@ Jv.call d "destroy" [||]
    let lost d = Fut.of_promise ~ok:Lost_info.of_jv (Jv.get d "lost")

    let push_error_scope d filter =
      ignore @@ Jv.call d "pushErrorScope" [| Jv.of_jstr filter |]

    let pop_error_scope d =
      let ok = Jv.to_option Error.of_jv in
      Fut.of_promise ~ok @@ Jv.call d "popErrorScope" [||]

    let create_buffer d bd =
      let bd = Buffer.Descriptor.to_jv bd in
      Buffer.of_jv @@ Jv.call d "createBuffer" [| bd |]

    let create_texture d td =
      let td = Texture.Descriptor.to_jv td in
      Texture.of_jv @@ Jv.call d "createTexture" [| td |]

    let import_external_texture d td =
      let td = Texture.External.Descriptor.to_jv td in
      Texture.External.of_jv @@ Jv.call d "importExternalTexture" [| td |]

    let create_sampler d sd =
      let sd = Sampler.Descriptor.to_jv sd in
      Sampler.of_jv @@ Jv.call d "createSampler" [| sd |]

    let create_bind_group_layout d ld =
      let ld = Bind_group.Layout.Descriptor.to_jv ld in
      Bind_group.Layout.of_jv @@ Jv.call d "createBindGroupLayout" [| ld |]

    let create_bind_group d gd =
      let gd = Bind_group.Descriptor.to_jv gd in
      Bind_group.of_jv @@ Jv.call d "createBindGroup" [| gd |]

    let create_pipeline_layout d ld =
      let ld = Pipeline_layout.Descriptor.to_jv ld in
      Pipeline_layout.of_jv @@ Jv.call d "createPipelineLayout" [| ld |]

    let create_shader_module d md =
      let md = Shader_module.Descriptor.to_jv md in
      Shader_module.of_jv @@ Jv.call d "createShaderModule" [| md |]

    let create_compute_pipeline d cd =
      let cd = Compute_pipeline.Descriptor.to_jv cd in
      Compute_pipeline.of_jv @@ Jv.call d "createComputePipeline" [| cd |]

    let create_compute_pipeline_async d cd =
      let cd = Compute_pipeline.Descriptor.to_jv cd in
      let ok = Compute_pipeline.of_jv in
      let error = Pipeline_error.of_jv in
      Fut.of_promise' ~ok ~error @@
      Jv.call d "createComputePipelineAsync" [| cd |]

    let create_render_pipeline d cd =
      let cd = Render_pipeline.Descriptor.to_jv cd in
      Render_pipeline.of_jv @@ Jv.call d "createRenderPipeline" [| cd |]

    let create_render_pipeline_async d rd =
      let rd = Render_pipeline.Descriptor.to_jv rd in
      let ok = Render_pipeline.of_jv in
      let error = Pipeline_error.of_jv in
      Fut.of_promise' ~ok ~error @@
      Jv.call d "createRenderPipelineAsync" [| rd |]

    let create_query_set d qd =
      let qd = Query.Set.Descriptor.to_jv qd in
      Query.Set.of_jv @@ Jv.call d "createQuerySet" [| qd |]

    let create_render_bundle_encoder d ed =
      let ed = Render_bundle.Encoder.Descriptor.to_jv ed in
      Render_bundle.Encoder.of_jv @@
      Jv.call d "createRenderBundleEncoder" [| ed |]

    let create_command_encoder ?(descr = Jv.undefined) d =
      Command.Encoder.of_jv @@ Jv.call d "createCommandEncoder" [| descr |]

    module Ev = struct
      module Uncaptured_error = struct
        type t = Jv.t
        let error e = Error.of_jv (Jv.get e "error")
      end
      let uncapturederror = Brr.Ev.Type.create (Jstr.v "uncapturederror")
    end
  end

  module Adapter = struct
    module Info = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let vendor i = Jv.Jstr.get i "vendor"
      let architecture i = Jv.Jstr.get i "architecture"
      let device i = Jv.Jstr.get i "device"
      let description i = Jv.Jstr.get i "description"
    end

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let limits a = Supported_limits.of_jv @@ Jv.get a "limits"
    let has_feature a f =
      let set = Jv.get a "features" in
      if Jv.is_none set then false else
      Jv.to_bool (Jv.call set "has" [|Jv.of_jstr f|])

    let is_fallback_adapter a = Jv.Bool.get a "isFallbackAdapter"

    let request_device ?descriptor:(descr = Jv.undefined) a =
      Fut.of_promise ~ok:Device.of_jv @@ Jv.call a "requestDevice" [|descr|]

    let request_adapter_info a ~unmask_hints =
      let arr = Jv.of_list Jv.of_jstr unmask_hints in
      Fut.of_promise ~ok:Info.of_jv @@ Jv.call a "requestAdapterInfo" [|arr|]
  end

  (* GPU object *)

  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)

  let of_navigator n = Jv.find (Brr.Navigator.to_jv n) "gpu"
  let get_preferred_canvas_format g =
    Texture.Format.of_jv @@ Jv.call g "getPreferredCanvasFormat" [||]

  let has_wgsl_language_feature g f =
    let set = Jv.get g "wgslLanguageFeatures" in
    if Jv.is_none set then false else
    Jv.to_bool (Jv.call set "has" [|Jv.of_jstr f|])

  module Power_preference = struct
    type t = Jstr.t
    let low_power = Jstr.v "low-power"
    let high_performance = Jstr.v "high-performance"
  end

  type opts = Jv.t

  let opts ?power_preference ?force_fallback_adapater () =
    let o = Jv.obj [||] in
    Jv.Jstr.set_if_some o "powerPreference" power_preference;
    Jv.Bool.set_if_some o "forceFallbackAdapter" force_fallback_adapater;
    o

  let request_adapter ?(opts = Jv.undefined) g =
    let ok = Jv.to_option Adapter.of_jv in
    Fut.of_promise ~ok @@ Jv.call g "requestAdapter" [| opts |]

  (* Canvas context *)

  module Canvas_context = struct
    module Alpha_mode = struct
      type t = Jstr.t
      let opaque = Jstr.v "opaque"
      let premultiplied = Jstr.v "premultiplied"
    end

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let get cnv =
      let webgpu = Jstr.v "webgpu" in
      Jv.to_option Fun.id @@
      Jv.call (Brr_canvas.Canvas.to_jv cnv) "getContext" [| Jv.of_jstr webgpu|]

    let canvas ctx = Brr_canvas.Canvas.of_jv (Jv.get ctx "canvas")

    type conf = Jv.t
    let conf
        ?usage ?(view_formats = []) ?color_space ?alpha_mode device format
      =
      let view_formats = Jv.of_list Jv.of_jstr view_formats in
      let c = Jv.obj [||] in
      Jv.Int.set_if_some c "usage" usage;
      Jv.set c "viewFormats" view_formats;
      Jv.Jstr.set_if_some c "colorSpace" color_space;
      Jv.Jstr.set_if_some c "alphaMode" alpha_mode;
      Jv.set c "device" (Device.to_jv device);
      Jv.set c "format" (Jv.of_jstr format);
      c

    let configure ctx conf = ignore @@ Jv.call ctx "configure" [|conf|]
    let unconfigure ctx = ignore @@ Jv.call ctx "unconfigure" [||]
    let get_current_texture ctx =
      Texture.of_jv @@ Jv.call ctx "getCurrentTexture" [||]
  end
end
