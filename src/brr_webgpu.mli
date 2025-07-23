(*---------------------------------------------------------------------------
   Copyright (c) 2023 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** WebGPU API. *)

(** WebGPU objects.

    See the API documentation on
    {{:https://developer.mozilla.org/en-US/docs/Web/API/WebGPU_API}MDN},
    on the {{:https://www.w3.org/TR/webgpu}W3C} and
    {{:https://webgpu.github.io/webgpu-samples}WebGPU Samples}.

    {b Note.} MDN's coverage of the API's objects is uneven, that's the reason
    why we link both on MDN and in the standard in the documentation strings.

    {b Convention.} Most (but not exactly all) API object names of the
    form [GPUHeyHo] are mapped on modules named [Gpu.Hey.Ho] or
    [Gpu.Hey_ho]. *)
module Gpu : sig

  (** 2D origins. *)
  module Origin_2d : sig
    type t
    (** The type for
        {{:https://www.w3.org/TR/webgpu/#typedefdef-gpuorigin2d}
        [GPUOrigin2D]} objects. *)

    val v : x:int -> y:int -> t
    (** [v] constructs a
        {{:https://www.w3.org/TR/webgpu/#typedefdef-gpuorigin2d}
        [GPUOrigin2D]} object with given parameters. *)
    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** 3D origins. *)
  module Origin_3d :sig
    type t
    (** The type for
        {{:https://www.w3.org/TR/webgpu/#typedefdef-gpuorigin3d}[GPUOrigin3D]}
        objects. *)

    val v : x:int -> y:int -> z:int -> t
    (** [v] constructs a
        {{:https://www.w3.org/TR/webgpu/#typedefdef-gpuorigin3d}[GPUOrigin3D]}
        object with given parameters. *)
    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** 3D extents. *)
  module Extent_3d : sig
    type t
    (** The type for {{:https://www.w3.org/TR/webgpu/#dictdef-gpuextent3ddict}
        [GPUExtent3D]} objects *)

    val v : ?h:int -> ?d:int -> w:int -> unit -> t
    (** [v] constructs a
        {{:https://www.w3.org/TR/webgpu/#dictdef-gpuextent3ddict}
        [GPUExtent3D]} object with given parameters.  *)
    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Compare functions. *)
  module Compare_function : sig
    type t = Jstr.t
    (** The type for
        {{:https://www.w3.org/TR/webgpu/#enumdef-gpucomparefunction}
        [GPUCompareFunction]} values. *)

    val never : t
    val less : t
    val equal : t
    val less_equal : t
    val greater : t
    val not_equal : t
    val greater_equal : t
    val always : t
  end

    (** GPU buffers. *)
  module Buffer : sig

    (** Map states. *)
    module Map_state : sig
      type t = Jstr.t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#enumdef-gpubuffermapstate}
          [GPUBufferMapState]} values. *)

      val unmapped : t
      val pending : t
      val mapped : t
    end

    (** Map mode flags. *)
    module Map_mode : sig
      type t = int
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#namespacedef-gpumapmode}[GPUMapMode]}
          values. *)
      val read : int
      val write : int
    end

    (** Usage flags. *)
    module Usage : sig
      type t = int
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#buffer-usage}[GPUBufferUsage]}
          values. *)
      val map_read : int
      val map_write : int
      val copy_src : int
      val copy_dst : int
      val index : int
      val vertex : int
      val uniform : int
      val storage : int
      val indirect : int
      val query_resolve : int
    end

    (** Buffer descriptors. *)
    module Descriptor : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#gpubufferdescriptor}
          [GPUBufferDescriptor]} objects. *)

      val v :
        ?label:Jstr.t -> ?size:int -> ?usage:Usage.t ->
        ?mapped_at_creation:bool -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#gpubufferdescriptor}
          [GPUBufferDescriptor]} object.

          See the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBuffer#validation}validation rules}. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBuffer}[GPUBuffer]} objects. *)

    val label : t -> Jstr.t
    (** [label b] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBuffer/label}label} of [b]. *)

    val size : t -> int
    (** [size b] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBuffer/size}size} of [b]. *)

    val usage : t -> int
    (** [usage b] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBuffer/usage}usage} of [b]. *)

    val map_state : t -> Map_state.t
    (** [map_state b] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBuffer/mapState}map state} of [b]. *)

    val map_async :
      ?size:int -> ?offset:int -> t -> Map_mode.t -> unit Fut.or_error
    (** [map_async b] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBuffer/mapAsync}maps} [b]. *)

    val get_mapped_range :
      ?size:int -> ?offset:int -> t -> Brr.Tarray.Buffer.t
    (** [get_mapped_range b] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBuffer/getMappedRange}mapped range} of [b]. *)

    val unmap : t -> unit
    (** [unmap b] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBuffer/unmap}unmaps} [b]. *)

    val destroy : t -> unit
    (** [destroy b] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBuffer/destroy}destroys} [b]. *)

    (** {1:binding Binding} *)

    (** Binding types. *)
    module Binding_type : sig
      type t = Jstr.t
      val uniform : t
      val storage : t
      val read_only_storage : t
    end

    (** Binding layouts *)
    module Binding_layout : sig
      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout#resource_layout_objects}
          [GPUBufferBindingLayout]} objects. *)

      val v :
        ?type':Binding_type.t -> ?has_dynamic_offset:bool ->
        ?min_binding_size:int -> unit -> t
      (** [v] contsructs a {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout#resource_layout_objects}
          [GPUBufferBindingLayout]} object. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Bindings. *)
    module Binding : sig
      type buffer := t

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroup#gpubufferbinding_objects}[GPUBufferBinding]} objects. *)

      val v : ?offset:int -> ?size:int -> buffer:buffer -> unit -> t
      (** [v] constructs a {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroup#gpubufferbinding_objects}[GPUBufferBinding]} object
          with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Textures. *)
  module Texture : sig

    (** Texture formats. *)
    module Format : sig
      type t
      (** The type for the
          {{:https://www.w3.org/TR/webgpu/#enumdef-gputextureformat}
          [GPUTextureFormat]} enum. *)

      val r8unorm : t
      val r8snorm : t
      val r8uint : t
      val r8sint : t
      val r16uint : t
      val r16sint : t
      val r16float : t
      val rg8unorm : t
      val rg8snorm : t
      val rg8uint : t
      val rg8sint : t
      val r32uint : t
      val r32sint : t
      val r32float : t
      val rg16uint : t
      val rg16sint : t
      val rg16float : t
      val rgba8unorm : t
      val rgba8unorm_srgb : t
      val rgba8snorm : t
      val rgba8uint : t
      val rgba8sint : t
      val bgra8unorm : t
      val bgra8unorm_srgb : t
      val rgb9e5ufloat : t
      val rgb10a2unorm : t
      val rg11b10ufloat : t
      val rg32uint : t
      val rg32sint : t
      val rg32float : t
      val rgba16uint : t
      val rgba16sint : t
      val rgba16float : t
      val rgba32uint : t
      val rgba32sint : t
      val rgba32float : t
      val stencil8 : t
      val depth16unorm : t
      val depth24plus : t
      val depth24plus_stencil8 : t
      val depth32float : t
      val depth32float_stencil8 : t
      val bc1_rgba_unorm : t
      val bc1_rgba_unorm_srgb : t
      val bc2_rgba_unorm : t
      val bc2_rgba_unorm_srgb : t
      val bc3_rgba_unorm : t
      val bc3_rgba_unorm_srgb : t
      val bc4_r_unorm : t
      val bc4_r_snorm : t
      val bc5_rg_unorm : t
      val bc5_rg_snorm : t
      val bc6h_rgb_ufloat : t
      val bc6h_rgb_float : t
      val bc7_rgba_unorm : t
      val bc7_rgba_unorm_srgb : t
      val etc2_rgb8unorm : t
      val etc2_rgb8unorm_srgb : t
      val etc2_rgb8a1unorm : t
      val etc2_rgb8a1unorm_srgb : t
      val etc2_rgba8unorm : t
      val etc2_rgba8unorm_srgb : t
      val eac_r11unorm : t
      val eac_r11snorm : t
      val eac_rg11unorm : t
      val eac_rg11snorm : t
      val astc_4x4_unorm : t
      val astc_4x4_unorm_srgb : t
      val astc_5x4_unorm : t
      val astc_5x4_unorm_srgb : t
      val astc_5x5_unorm : t
      val astc_5x5_unorm_srgb : t
      val astc_6x5_unorm : t
      val astc_6x5_unorm_srgb : t
      val astc_6x6_unorm : t
      val astc_6x6_unorm_srgb : t
      val astc_8x5_unorm : t
      val astc_8x5_unorm_srgb : t
      val astc_8x6_unorm : t
      val astc_8x6_unorm_srgb : t
      val astc_8x8_unorm : t
      val astc_8x8_unorm_srgb : t
      val astc_10x5_unorm : t
      val astc_10x5_unorm_srgb : t
      val astc_10x6_unorm : t
      val astc_10x6_unorm_srgb : t
      val astc_10x8_unorm : t
      val astc_10x8_unorm_srgb : t
      val astc_10x10_unorm : t
      val astc_10x10_unorm_srgb : t
      val astc_12x10_unorm : t
      val astc_12x10_unorm_srgb : t
      val astc_12x12_unorm : t
      val astc_12x12_unorm_srgb : t
      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Texture usage. *)
    module Usage : sig
      type t = int
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/usage#value}GPU texture usage} flags. *)

      val copy_src : t
      val copy_dst : t
      val texture_binding : t
      val storage_binding : t
      val render_attachment : t
    end

    (** Texture dimensions. *)
    module Dimension : sig
      type t = Jstr.t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/dimension#value}GPU texture dimensions}. *)

      val d1 : t
      val d2 : t
      val d3 : t
    end

    (** Texture view dimensions. *)
    module View_dimension : sig
      type t = Jstr.t
      val d1 : t
      val d2 : t
      val d2_array : t
      val cube : t
      val cube_array : t
      val d3 : t
    end

    (** Texture aspects. *)
    module Aspect : sig
      type t = Jstr.t
      val all : t
      val stencil_only : t
      val depth_only : t
    end

    (** Storage textures. *)
    module Storage : sig

      (** Storage accesses. *)
      module Access : sig
        type t = Jstr.t
        val write_only : t
      end

      (** Binding layouts. *)
      module Binding_layout : sig
        type t
        (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout#resource_layout_objects}
          [GPUStorageTextureBindingLayout]} objects. *)

        val v :
          ?access:Access.t -> ?format:Format.t ->
          ?view_dimension:View_dimension.t -> unit -> t
        (** [v] constructs a {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout#resource_layout_objects}
            [GPUStorageTextureBindingLayout]} object with given parameters. *)

        (**/**) include Jv.CONV with type t := t (**/**)
      end
    end

    (** External textures. *)
    module External : sig

      (** Binding layouts. *)
      module Binding_layout : sig
        type t
        (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout#resource_layout_objects}
          [GPUExternalTextureBindingLayout]} objects. *)

        val v : unit -> t
        (** [v] constructs a {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout#resource_layout_objects}
            [GPUExternalTextureBindingLayout]} object with given parameters. *)

        (**/**) include Jv.CONV with type t := t (**/**)
      end

      (** Exeternal texture descriptors. *)
      module Descriptor : sig
        type t
        (** The type for {{:https://www.w3.org/TR/webgpu/#dictdef-gpuexternaltexturedescriptor}[GPUExternalTextureDescriptor]}
            objects. *)

        val v :
          ?label:Jstr.t -> ?color_space:Jstr.t -> source:Jv.t -> unit -> unit
        (** [v source] is a {{:https://www.w3.org/TR/webgpu/#dictdef-gpuexternaltexturedescriptor}[GPUExternalTextureDescriptor]}
            object with given parameters. *)

        (**/**) include Jv.CONV with type t := t (**/**)
      end

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUExternalTexture}[GPUExternalTexture]} objects. *)

      val label : t -> Jstr.t
      (** [label e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUExternalTexture/label}label} of [e]. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Texture views. *)
    module View : sig

      (** Texture view descriptors. *)
      module Descriptor : sig
        type t
        (** The type for
            {{:https://www.w3.org/TR/webgpu/#dictdef-gputextureviewdescriptor}
            [GPUTextureViewDescriptor]} objects. *)

        val v :
          ?label:Jstr.t -> ?format:Format.t -> ?dimension:Extent_3d.t ->
          ?aspect:Aspect.t -> ?base_mip_level:int -> ?mip_level_count:int ->
          ?base_array_layer:int -> ?array_layer_count:int -> unit -> t
        (** [v] constructs a
            {{:https://www.w3.org/TR/webgpu/#dictdef-gputextureviewdescriptor}
            [GPUTextureViewDescriptor]} object with given parameters. *)

        (**/**) include Jv.CONV with type t := t (**/**)
      end

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTextureView}[GPUTextureView]} objects. *)

      val label : t -> Jstr.t
      (** [label v] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTextureView/label}label} of [v]. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Sample types. *)
    module Sample_type : sig
      type t = Jstr.t
      val float : t
      val unfilterable_float : t
      val depth : t
      val sint : t
      val uint : t
    end

    (** Binding layouts. *)
    module Binding_layout : sig
      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout#resource_layout_objects}[GPUTextureBindingLayout]}
          objects. *)

      val v :
        ?sample_type:Sample_type.t -> ?view_dimension:View_dimension.t ->
        ?multisampled:bool -> unit -> t
      (** [v] constructs a {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout#resource_layout_objects}[GPUTextureBindingLayout]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end
    (** Texture descriptors. *)
    module Descriptor : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#gputexturedescriptor}
          [GPUTextureDescriptor]} objects. *)

      val v :
        ?label:Jstr.t -> ?mip_level_count:int -> ?sample_count:int ->
        ?dimension:Dimension.t -> ?view_formats:Format.t list ->
        size:Extent_3d.t -> format:Format.t -> usage:Usage.t -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#gputexturedescriptor}
          [GPUTextureDescriptor]} objects with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/}[GPUTexture]} objects. *)

    val create_view : ?descriptor:t -> t -> View.t
    (** [create_view t] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/createView}creates} a view on [t]. *)

    val destroy : t -> unit
    (** [destroy t] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/destroy}destroys} [t]. *)

    val width : t -> int
   (** [width t] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/width}width} of [t]. *)

    val height : t -> int
    (** [height t] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/height}height} of [t]. *)

    val depth_or_array_layers : t -> int
    (** [depth t] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/depthOrArrayLayers}depth} of [t]. *)

    val mip_level_count : t -> int
    (** [mip_level_count t] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/mipLevelCount}mip level count} of [t]. *)

    val sample_count : t -> int
    (** [sample_count t] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/sampleCount}sample_count} of [t]. *)

    val dimension : t -> Dimension.t
    (** [dimension t] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/dimension}dimension} of [t]. *)

    val format : t -> Format.t
    (** [format t] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/format}format} of [t]. *)

    val usage : t -> Usage.t
    (** [usage t] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUTexture/usage}usage} of [t]. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Images. *)
  module Image : sig

    (** Data layouts. *)
    module Data_layout : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#gpuimagedatalayout}
          [GPUImageDataLayout]} objects. *)

      val v :
        ?offset:int ->
        ?bytes_per_row:int -> ?rows_per_image:int -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#gpuimagedatalayout}
          [GPUImageDataLayout]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Buffer copies. *)
    module Copy_buffer : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#gpuimagecopybuffer}
          [GPUImageCopyBuffer]} objects. *)

      val v :
        ?offset:int ->
        ?bytes_per_row:int ->
        ?rows_per_image:int -> buffer:Buffer.t -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#gpuimagecopybuffer}
          [GPUImageCopyBuffer]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Texture copies. *)
    module Copy_texture : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#gpuimagecopytexture}
          [GPUImageCopyTexture]} objects. *)

      val v :
        ?mip_level:int ->
        ?origin:Origin_3d.t -> ?aspect:Texture.Aspect.t ->
        texture:Texture.t -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#gpuimagecopytexture}
          [GPUImageCopyTexture]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Tagged texture copies. *)
    module Copy_texture_tagged : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#gpuimagecopytexturetagged}
          [GPUImageCopyTextureTagged]} objects. *)

      val v :
        ?mip_level:int ->
        ?origin:Origin_3d.t ->
        ?aspect:Texture.Aspect.t ->
        ?color_space:Jstr.t ->
        ?premultiplied_alpha:bool -> texture:Texture.t -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#gpuimagecopytexturetagged}
          [GPUImageCopyTextureTagged]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** External image copies. *)
    module Copy_external_image : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#gpuimagecopyexternalimage}
          [GPUImageCopyExternalImage]} objects. *)

      val v : ?origin:Origin_2d.t -> ?flip_y:bool -> source:Jv.t -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#gpuimagcecopyexternalimage}
          [GPUImageCopyExternalImage]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end
  end

  (** Samplers. *)
  module Sampler : sig

    (** Binding types. *)
    module Binding_type : sig
      type t = Jstr.t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#enumdef-gpusamplerbindingtype}
          [GPUSamplerBindingType]} values. *)

      val filtering : t
      val non_filtering : t
      val comparison : t
    end

    (** Binding layouts. *)
    module Binding_layout : sig
      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout#resource_layout_objects}
          [GPUSamplerBindingLayout]} objects. *)

      (** The type for *)
      val v : ?type':Binding_type.t -> unit -> t
      (** [v] constructs a
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout#resource_layout_objects}
          [GPUSamplerBindingLayout]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Address modes. *)
    module Address_mode : sig
      type t = Jstr.t
      (** The type for {{:https://www.w3.org/TR/webgpu/#enumdef-gpuaddressmode}
          [GPUAddressMode]} values. *)

      val clamp_to_edge : t
      val repeat : t
      val mirror_repeat : t
    end

    (** Filter modes. *)
    module Filter_mode : sig
      type t = Jstr.t
      (** The type for {{:https://www.w3.org/TR/webgpu/#enumdef-gpufiltermode}
          [GPUFilterMode]} values. *)

      val nearest : t
      val linear : t
    end

    (** Mimap filter modes. *)
    module Mipmap_filter_mode : sig
      type t = Jstr.t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#enumdef-gpumipmapfiltermode}
          [GPUMimapFilterMode]} values. *)

      val nearest : t
      val linear : t
    end

    (** Descriptors. *)
    module Descriptor : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#gpudevicedescriptor}
          [GPUDeviceDescriptor]} objects. *)

      val v :
        ?address_mode_u:Address_mode.t ->
        ?address_mode_v:Address_mode.t ->
        ?address_mode_w:Address_mode.t ->
        ?mag_filter:Filter_mode.t ->
        ?min_filter:Filter_mode.t ->
        ?mipmap_filter:Mipmap_filter_mode.t ->
        ?lod_min_clamp:float ->
        ?lod_max_clamp:float ->
        ?compare:Jstr.t -> ?max_anisotropy:int -> unit -> t
      (** [v] consructs a
          {{:https://www.w3.org/TR/webgpu/#gpudevicedescriptor}
          [GPUDeviceDescriptor]} objects with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUSampler}[GPUSampler]} objects. *)

    val label : t -> Jstr.t
    (** [label s] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUSampler/label}label} of [s]. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** {1:pipelines Pipelines} *)

  (** {2:shader Shaders} *)

  (** Bind groups. *)
  module Bind_group : sig

    (** Layouts. *)
    module Layout : sig

      (** Shader stages. *)
      module Shader_stage : sig
        type t = int
        val vertex : t
        val fragment : t
        val compute : t
      end

      (** Entries. *)
      module Entry : sig
        type t
        (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout#entry_objects}[GPUBindGroupLayoutEntry]} objects. *)
        val v :
          ?buffer:Buffer.Binding_layout.t ->
          ?sampler:Sampler.Binding_layout.t ->
          ?texture:Texture.Binding_layout.t ->
          ?storage_texture:Texture.Storage.Binding_layout.t ->
          ?external_texture:Texture.Storage.Binding_layout.t ->
          binding:int -> visibility:Shader_stage.t -> unit -> t
          (** [v] constructs a {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout#entry_objects}[GPUBindGroupLayoutEntry]} object
              with given parameters. *)
      end

      (** Descriptors. *)
      module Descriptor : sig
        type t
        (** The type for
            {{:https://www.w3.org/TR/webgpu/#dictdef-gpubindgroupdescriptor}
            [GPUBindGroupLayoutDescriptor]} objects. *)

        val v : entries:Entry.t list -> unit -> t
        (** [v] constructs a
            {{:https://www.w3.org/TR/webgpu/#dictdef-gpubindgroupdescriptor}
            [GPUBindGroupLayoutDescriptor]} objects with given parameters. *)

        (**/**) include Jv.CONV with type t := t (**/**)
      end

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBindGroupLayout}[GPUBindGroupLayout]} objects. *)

      val label : t -> Jstr.t
      (** [label l] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBindGroupLayout/label}label} of [l]. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Entries. *)
    module Entry : sig
      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroup#entries}[GPUBindGroupEntry]} objects. *)

      val of_sampler : int -> Sampler.t -> t
      val of_texture_view : int -> Texture.View.t -> t
      val of_buffer_binding : int -> Buffer.Binding.t -> t
      val of_external_texture : int -> Texture.External.t -> t
      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Descriptors. *)
    module Descriptor : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpubindgroupdescriptor}
          [GPUBindGroupDescriptor]} objects. *)

      val v :
        ?label:Jstr.t ->
        layout:Layout.t -> entries:Entry.t list -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpubindgroupdescriptor}
          [GPUBindGroupDescriptor]} object with given parameters. *)
      (**/**) include Jv.CONV with type t := t (**/**)
    end

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBindGroup/}[GPUBindGroup]} objects. *)

    val label : t -> Jstr.t
    (** [label g] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUBindGroup/label}label} of [g]. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Pipeline layouts. *)
  module Pipeline_layout : sig

    (** Descriptors. *)
    module Descriptor : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpupipelinelayoutdescriptor}
          [GPUPipelineLayoutDescription]} objects. *)

      val v :
        ?label:Jstr.t ->
        bind_group_layouts:Bind_group.Layout.t list -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpupipelinelayoutdescriptor}
          [GPUPipelineLayoutDescription]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUPipelineLayout}[GPUPipelineLayout]} objects. *)

    val label : t -> Jstr.t
    (** [label l] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUPipelineLayout/label}label} of [l]. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Shader modules. *)
  module Shader_module : sig

    (** Compilation messages. *)
    module Compilation_message : sig

      (** Message types. *)
      module Type : sig
        type t = Jstr.t
        val error : t
        val warning : t
        val info : t
      end

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCompilationMessage}GPUCompilationMessage} objects. *)

      val message : t -> Jstr.t
      (** [message m] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCompilationMessage/message}message} of [m]. *)

      val type' : t -> Type.t
      (** [type' m] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCompilationMessage/type}type} of [m]. *)

      val linenum : t -> int
      (** [linenum m] is the source {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCompilationMessage/lineNum}line number} of [m]. *)

      val linepos : t -> int
      (** [linepos m] is the source {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCompilationMessage/linePos}position on the line} of [m]. *)

      val offset : t -> int
      (** [linepos m] is the source {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCompilationMessage/offset}offset} of [m]. *)

      val length : t -> int
      (** [length m] is the source {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCompilationMessage/length}length} of [m]. *)


      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Compilation information. *)
    module Compilation_info : sig
      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCompilationInfo}[GPUCompilationInfo]} objects. *)

      val messages : t -> Compilation_message.t list
      (** [messages i] are the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCompilationInfo/messages}messages} of [i]. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Compilation hints. *)
    module Compilation_hint : sig
      type t
      val v : ?layout:[`Auto | `Layout of Pipeline_layout.t] -> unit -> t
      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Descriptors. *)
    module Descriptor : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpushadermoduledescriptor}
          [GPUShaderModuleDescriptor]} objects. *)

      val v :
        ?label:Jstr.t -> ?source_map:Jv.t ->
        ?hints:(Jstr.t * Compilation_hint.t) list -> code:Jstr.t -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpushadermoduledescriptor}
          [GPUShaderModuleDescriptor]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUShaderModule}[GPUShaderModule]} objects. *)

    val label : t -> Jstr.t
    (** [label sm] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUShaderModule/label}label} of [sm]. *)

    val get_compilation_info : t -> Compilation_info.t Fut.or_error
   (** [get_compilation_info sm] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUShaderModule/getCompilationInfo}compilation info} of [sm]. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Programmable stages. *)
  module Programmable_stage : sig
    type t
    (** The type for
        {{:https://www.w3.org/TR/webgpu/#gpuprogrammablestage}
        [GPUProgrammableStage]} objects. *)

    val v :
      ?constants:(Jstr.t * float) list -> module':Shader_module.t ->
      entry_point:Jstr.t -> unit -> t
    (** [v] constructs a
        {{:https://www.w3.org/TR/webgpu/#gpuprogrammablestage}
        [GPUProgrammableStage]} object with given parameters. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** {2:compute_pipelines Compute pipelines} *)

  (** Compute pipelines. *)
  module Compute_pipeline : sig

    (** Descriptors. *)
    module Descriptor : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpucomputepipelinedescriptor}
          [GPUComputePipelineDescriptor]} objects. *)

      val v :
        ?label:Jstr.t -> layout:[ `Auto | `Layout of Pipeline_layout.t ] ->
        compute:Programmable_stage.t -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpucomputepipelinedescriptor}
          [GPUComputePipelineDescriptor]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePipeline}[GPUComputePipeline]} objects. *)

    val label : t -> Jstr.t
    (** [label p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePipeline/label}label} of [p]. *)

    val get_bind_group_layout : t -> int -> Bind_group.Layout.t
    (** [get_bind_group_layout p i]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePipeline/getBindGroupLayout}gets} the bind group layout [i] of [p]. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** {2:render_pipelines Render pipelines} *)

  (** Index buffer format. *)
  module Index_format : sig
    type t = Jstr.t
    val uint16 : t
    val uint32 : t
  end

  (** Primitives. *)
  module Primitive : sig

    (** Primitive topology. *)
    module Topology : sig
      type t = Jstr.t
      (** The type for {{:https://www.w3.org/TR/webgpu/#enumdef-gpuprimitivetopology}[GPUPrimitiveTopology]} values. *)

      val point_list : t
      val line_list : t
      val line_strip : t
      val triangle_list : t
      val triangle_strip : t
    end

    (** Primitive front face. *)
    module Front_face : sig
      type t = Jstr.t
      (** The type for {{:https://www.w3.org/TR/webgpu/#enumdef-gpufrontface}
          [GPUFrontFace]} values. *)

      val ccw : t
      val cw : t
    end

    (** Cull modes. *)
    module Cull_mode : sig
      type t = Jstr.t
      (** The type for {{:https://www.w3.org/TR/webgpu/#enumdef-gpucullmode}[GPUCullMode]} values. *)

      val none : t
      val front : t
      val back : t
    end

    (** Primitive state. *)
    module State : sig
      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createRenderPipeline#primitive_object_structure}[GPUPrimitiveState]} objects. *)

      val v :
        ?topology:Topology.t ->
        ?strip_index_format:Index_format.t ->
        ?front_face:Front_face.t ->
        ?cull_mode:Cull_mode.t -> ?unclipped_depth:bool -> unit -> t
      (** [v] constructs a {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createRenderPipeline#primitive_object_structure}[GPUPrimitiveState]} object
    with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end
  end

    (** Vertex states. *)
  module Vertex : sig

    (** Vertex formats. *)
    module Format : sig
      type t = Jstr.t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#vertex-formats}[GPUVertexFormat]}
          values. *)

      val uint8x2 : t
      val uint8x4 : t
      val sint8x2 : t
      val sint8x4 : t
      val unorm8x2 : t
      val unorm8x4 : t
      val snorm8x2 : t
      val snorm8x4 : t
      val uint16x2 : t
      val uint16x4 : t
      val sint16x2 : t
      val sint16x4 : t
      val unorm16x2 : t
      val unorm16x4 : t
      val snorm16x2 : t
      val snorm16x4 : t
      val float16x2 : t
      val float16x4 : t
      val float32 : t
      val float32x2 : t
      val float32x3 : t
      val float32x4 : t
      val uint32 : t
      val uint32x2 : t
      val uint32x3 : t
      val uint32x4 : t
      val sint32 : t
      val sint32x2 : t
      val sint32x3 : t
      val sint32x4 : t
    end

  (** Step modes. *)
    module Step_mode : sig
      type t = Jstr.t
      (** The type {{:https://www.w3.org/TR/webgpu/#enumdef-gpuvertexstepmode}
          [GPUVertexStepMode]} values. *)

      val vertex : t
      val instance : t
    end

    (** Vertex attributes. *)
    module Attribute : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpuvertexattribute}
          [GPUVertexAttribute]} objects. *)

      val v :
        format:Format.t -> offset:int -> shader_location:int -> unit -> t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpuvertexattribute}
          [GPUVertexAttribute]} objects. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Vertex buffer layouts. *)
    module Buffer_layout : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpuvertexbufferlayout}
          [GPUVertexBufferLayout]} objects. *)

      val v :
        ?step_mode:Step_mode.t -> array_stride:int ->
        attributes:Attribute.t list -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpuvertexbufferlayout}
          [GPUVertexBufferLayout]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Vertex states. *)
    module State : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpuvertexstate}
          [GPUVertexState]} objects. *)

      val v :
        ?constants:(Jstr.t * float) list -> buffers:Buffer_layout.t list ->
        module':Shader_module.t -> entry_point:Jstr.t -> unit -> t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpuvertexstate}
          [GPUVertexState]} objects. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end
  end

  (** Blend state. *)
  module Blend : sig

    (** Blend factors. *)
    module Factor : sig
      type t = Jstr.t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#enumdef-gpublendfactor}
          [GPUBlendFactor]} values. *)

      val zero : t
      val one : t
      val src : t
      val one_minus_src : t
      val src_alpha : t
      val one_minus_src_alpha : t
      val dst : t
      val one_minus_dst : t
      val dst_alpha : t
      val one_minus_dst_alpha : t
      val src_alpha_saturated : t
      val constant : t
      val one_minus_constant : t
    end

    (** Blend operations. *)
    module Operation : sig
      type t = Jstr.t
      (** The type for {{:https://www.w3.org/TR/webgpu/#enumdef-gpublendoperation}[GPUBlendOperation]} values. *)

      val add : t
      val subtract : t
      val reverse_subtract : t
      val min : t
      val max : t
    end

    (** Blend components. *)
    module Component : sig
      type t
(** The type for
    {{:https://www.w3.org/TR/webgpu/#dictdef-gpublendcomponent}[GPUBlendComponent]} objects. *)

      val v :
        ?operation:Operation.t -> ?src_factor:Factor.t ->
        ?dst_factor:Factor.t -> unit -> t
      (** [v] constructs a {{:https://www.w3.org/TR/webgpu/#dictdef-gpublendcomponent}[GPUBlendComponent]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Blend state. *)
    module State : sig
      type t
      (** The type for {{:https://www.w3.org/TR/webgpu/#dictdef-gpublendstate}[GPUBlendState]} objects. *)

      val v : ?color:Component.t -> ?alpha:Component.t -> unit -> t
      (** [v] constructs a {{:https://www.w3.org/TR/webgpu/#dictdef-gpublendstate}[GPUBlendState]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end
  end

  (** Colors and color state.  *)
  module Color : sig

    (** Color write flags. *)
    module Write : sig
      type t = int
      (** The type for {{:https://www.w3.org/TR/webgpu/#typedefdef-gpucolorwriteflags}[GPUColorWriteFlags]}. *)

      val red : int
      val green : int
      val blue : int
      val alpha : int
      val all : int
    end

    (** Color target states. *)
    module Target_state : sig
      type t
      (** The type for {{:https://www.w3.org/TR/webgpu/#dictdef-gpucolortargetstate}[GPUColorTargetState]} objects. *)

      val v :
        ?blend:Blend.State.t ->
        ?write_mask:Write.t -> format:Texture.Format.t -> unit -> t
      (** [v] constructs a {{:https://www.w3.org/TR/webgpu/#dictdef-gpucolortargetstate}[GPUColorTargetState]} object. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end


    type t
    (** The type for
        {{:https://www.w3.org/TR/webgpu/#typedefdef-gpucolor}[GPUColor]}
        objects. *)

    val v : r:float -> g:float -> b:float -> a:float -> t
    (** [v] constructs a
        {{:https://www.w3.org/TR/webgpu/#typedefdef-gpucolor}
        [GPUColor]} object with given parameters. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Stencil state and operations. *)
  module Stencil : sig

    (** Stencil operations. *)
    module Operation : sig
      type t = Jstr.t
      (** The type for {{:https://www.w3.org/TR/webgpu/#enumdef-gpustenciloperation}[GPUStencilOperation]} values. *)

      val keep : t
      val zero : t
      val replace : t
      val invert : t
      val increment_clamp : t
      val decrement_clamp : t
      val increment_wrap : t
      val decrement_wrap : t
    end

    (** Stencil face states. *)
    module Face_state : sig
      type t
      (** The type for {{:https://www.w3.org/TR/webgpu/#dictdef-gpustencilfacestate}[GPUStencilFaceState]} objects. *)

      val v :
        ?compare:Compare_function.t -> ?fail_op:Operation.t ->
        ?depth_fail_op:Operation.t -> ?pass_op:Operation.t -> unit -> t
      (** [v] constructs a {{:https://www.w3.org/TR/webgpu/#dictdef-gpustencilfacestate}[GPUStencilFaceState]} with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end
  end

  (** Depth stencil state. *)
  module Depth_stencil_state : sig
    type t
    (** The type for
        {{:https://www.w3.org/TR/webgpu/#dictdef-gpudepthstencilstate}
        [GPUDepthStencilState]} objects. *)

    val v :
      ?stencil_front:Stencil.Face_state.t ->
      ?stencil_back:Stencil.Face_state.t ->
      ?stencil_read_mask:int ->
      ?stencil_write_mask:int ->
      ?depth_bias:int ->
      ?depth_bias_slope_scale:int ->
      ?depth_bias_clamp:int ->
      format:Texture.Format.t ->
      depth_write_enabled:bool -> depth_compare:Compare_function.t -> unit -> t
    (** [v] constructs a
        {{:https://www.w3.org/TR/webgpu/#dictdef-gpudepthstencilstate}
          [GPUDepthStencilState]} object with given parameters. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Multisample states. *)
  module Multisample_state : sig
    type t
    (** The type for
        {{:https://www.w3.org/TR/webgpu/#dictdef-gpumultisamplestate}
        [GPUMultisample]} objects. *)

    val v :
      ?count:int -> ?mask:int -> ?alpha_to_coverage_enabled:bool -> unit -> t
    (** [v] constructs a
        {{:https://www.w3.org/TR/webgpu/#dictdef-gpumultisamplestate}
        [GPUMultisample]} object with given parameters. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Fragment states. *)
  module Fragment_state : sig
    type t
    (** The type for
        {{:https://www.w3.org/TR/webgpu/#dictdef-gpumultisamplestate}
        [GPUFragmentState]} objects. *)

    val v :
      ?constants:(Jstr.t * float) list ->
      targets:Color.Target_state.t list ->
      module':Shader_module.t -> entry_point:Jstr.t -> unit -> t
    (** [v] constructs a
        {{:https://www.w3.org/TR/webgpu/#dictdef-gpumultisamplestate}
        [GPUFragmentState]} object with given parameters. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Render pipelines. *)
  module Render_pipeline : sig

    (** Descriptors. *)
    module Descriptor : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderpipelinedescriptor}
          [GPURenderPipelineDescriptor]} objects. *)

      val v :
        ?label:Jstr.t ->
        ?primitive:Primitive.State.t ->
        ?depth_stencil:Depth_stencil_state.t ->
        ?multisample:Multisample_state.t ->
        ?fragment:Fragment_state.t ->
        layout:[ `Auto | `Layout of Pipeline_layout.t ] ->
        vertex:Vertex.State.t -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderpipelinedescriptor}
          [GPURenderPipelineDescriptor]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPipeline}
        [GPURenderPipeline]} objects. *)

    val label : t -> Jstr.t
    (** [label p] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPipeline/label}label} of [p]. *)

    val get_bind_group_layout : t -> int -> Bind_group.Layout.t
    (** [get_bind_group_layout p i]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPipeline/getBindGroupLayout}gets} the bind group layout [i] of [p]. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** {1:issuing_commands Issuing commands} *)

  (** {2:queries Queries} *)

  (** Queries. *)
  module Query : sig

    (** Query types. *)
    module Type : sig
      type t = Jstr.t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#enumdef-gpuquerytype}[GPUQueryType]}
          values. *)

      val occlusion : t
      val timestamp : t
    end

    (** Query sets *)
    module Set : sig

      (** Descriptors. *)
      module Descriptor : sig
        type t
        (** The type for
            {{:https://www.w3.org/TR/webgpu/#dictdef-gpuquerysetdescriptor}
            [GPUQuerySetDescriptor]} objects. *)

        val v :
          ?label:Jstr.t -> type':Type.t -> count:int -> unit -> t
        (** [v] constructs a
            {{:https://www.w3.org/TR/webgpu/#dictdef-gpuquerysetdescriptor}
            [GPUQuerySetDescriptor]} object with given parameters. *)
      end

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUQuerySet}
          [GPUQuerySet]} objects. *)

      val label : t -> Jstr.t
      (** [label s] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUQuerySet/label}
          label} of [s]. *)

      val type' : t -> Type.t
      (** [type' s] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUQuerySet/type}
          type} of [s]. *)

      val count : t -> int
      (** [count s] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUQuerySet/count}
          count} of [s]. *)

      val destroy : t -> unit
      (** [destroy s]
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUQuerySet/destroy}destroys} [s]. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end
  end

  (** {2:passes Passes} *)

  (** Compute passes. *)
  module Compute_pass : sig

    (** Timestamp writes. *)
    module Timestamp_writes : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpucomputepasstimestampwrites}[GPUComputePassTimestampWrites]} objects. *)

      val v :
        ?beginning_of_pass_write_index:int ->
        ?end_of_pass_write_index:int -> query_set:Query.Set.t -> unit -> t
      (** [v] constructs a {{:https://www.w3.org/TR/webgpu/#dictdef-gpucomputepasstimestampwrites}[GPUComputePassTimestampWrites]} object with given
          parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Descriptors. *)
    module Descriptor : sig
      type t
      (** The type for {{:https://www.w3.org/TR/webgpu/#dictdef-gpucomputepassdescriptor}[GPUComputePassDescriptor]} objects. *)

      val v : ?label:Jstr.t -> timestamp_writes:Timestamp_writes.t -> unit -> t
      (** [v] constructs a {{:https://www.w3.org/TR/webgpu/#dictdef-gpucomputepassdescriptor}[GPUComputePassDescriptor]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Pass encoders. *)
    module Encoder : sig

      (** {1:encoders Encoders} *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePassEncoder}[GPUComputePassEncoder]} objects. *)

      val label : t -> Jstr.t
      (** [label e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePassEncoder/label}label} of [e]. *)

      val end' : t -> unit
      (** [end' e] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePassEncoder/end}ends} the pass on [e]. *)

      (** {1:setup Setup commands} *)

      val set_pipeline : t -> Compute_pipeline.t -> unit
      (** [set_pipeline e p] sets the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePassEncoder/setPipeline}pipeline} of [e] to [p]. *)

      val set_bind_group :
        ?dynamic_offsets:int list -> ?group:Bind_group.t ->t -> index:int ->
        unit
      (** [set_bind_group] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePassEncoder/setBindGroup}sets} a bind group for subsequent commands. *)

      val set_bind_group' :
        ?group:Bind_group.t -> t -> index:int -> dynamic_offsets:int array ->
        offsets_start:int -> offsets_length:int -> unit
      (** [set_bind_group'] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePassEncoder/setBindGroup}sets} a bind group for subsequent
          commands. *)

      (** {1:dispatching Dispatch commands} *)

      val dispatch_workgroups :
        ?count_z:int -> ?count_y:int -> t -> count_x:int -> unit
      (** [dispatch_workgroups] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePassEncoder/dispatchWorkgroups}dispaches} a grid of workgroups. *)

      val dispatch_workgroups_indirect : t -> Buffer.t -> offset:int -> unit
      (** [dispatch_workgroups_indirect] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePassEncoder/dispatchWorkgroupsIndirect}dispatches}
          a grid of workgroups. *)

      (** {1:debug Debug commands} *)

      val push_debug_group : t -> Jstr.t -> unit
      (** [push_debug_group e l] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePassEncoder/pushDebugGroup}starts} a debug group pass
          [l] on [e]. *)

      val pop_debug_group : t -> unit
      (** [pop_debug_group] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePassEncoder/popDebugGroup}ends} the debug group pass
          on [e]. *)

      val insert_debug_marker : t -> Jstr.t -> unit
      (** [insert_debug_marker e l] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUComputePassEncoder/insertDebugMarker}marks} a point [l] in [e]. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end
  end

  (** Render bundles. *)
  module Render_bundle : sig

    (** Descriptors. *)
    module Descriptor : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderbundledescriptor}
           [GPURenderBundleDescriptor]}. *)

      val v : ?label:Jstr.t -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderbundledescriptor}
          [GPURenderBundleDescriptor]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundle}
        [GPURenderBundle]} objects. *)

    val label : t -> Jstr.t
    (** [label b] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundle/label}label} of [b]. *)

    (**/**) include Jv.CONV with type t := t (**/**)

    (** Encoders. *)
    module Encoder : sig

      (** {1:encoder Encoders} *)

      (** Descriptors. *)
      module Descriptor : sig
        type t
        (** The type for
            {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderbundleencoderdescriptor}[GPURenderBundleEncoderDescriptor]} objects. *)

        val v :
          ?label:Jstr.t ->
          ?color_formats:Texture.Format.t list ->
          ?depth_stencil_format:Texture.Format.t ->
          ?sample_count:int ->
          ?depth_read_only:bool -> ?stencil_read_only:bool -> unit -> t
        (** [v] constructs a {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderbundleencoderdescriptor}[GPURenderBundleEncoderDescriptor]} object with
            given parameters. *)

        (**/**) include Jv.CONV with type t := t (**/**)
      end

      type bundle := t

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder}[GPURenderBundleEncoder]} objects. *)

      val label : t -> Jstr.t
      (** [label e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/label}label} of [e]. *)

      val finish : ?descr:t -> t -> bundle
      (** [finish e] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/finish}finishes} recording commands. *)

      (** {1:setup Setup commands} *)

      val set_pipeline : t -> Compute_pipeline.t -> unit
      (** [set_pipline e p] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/setPipeline}sets} the pipeline of [e] to [p] for
          subsequent commands. *)

      val set_bind_group :
        ?dynamic_offsets:int list -> ?group:Bind_group.t ->t -> index:int ->
        unit
      (** [set_bind_group] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/setBindGroup}sets} a bind group for subsequent commands. *)

      val set_bind_group' :
        ?group:Bind_group.t -> t -> index:int -> dynamic_offsets:int array ->
        offsets_start:int -> offsets_length:int -> unit
      (** [set_bind_group'] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/setBindGroup}sets} a bind group for subsequent
          commands. *)

      val set_index_buffer :
        ?offset:int -> ?size:int -> t -> Buffer.t -> format:Index_format.t ->
        unit
      (** [set_index_buffer] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/setIndexBuffer}sets} the index data for subsequent
          commands. *)

      val set_vertex_buffer :
        ?buffer:Buffer.t -> ?offset:int -> ?size:int -> t -> slot:int ->
        unit
      (** [set_index_buffer] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/setIndexBuffer}sets} sets the vertex data for subsequent
          commands. *)

      (** {1:draw Draw commands} *)

      val draw :
        ?first_instance:int -> ?first_vertex:int -> ?instance_count:int ->
        t -> vertex_count:int -> unit
      (** [draw] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/draw}draws} primitives. *)

      val draw_indexed :
        ?first_instance:int -> ?base_vertex:int -> ?first_index:int ->
        ?instance_count:int -> t -> index_count:int -> unit
      (** [draw_indexed] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/drawIndexed}draws} indexed primitives. *)

      val draw_indirect : t -> Buffer.t -> offset:int -> unit
      (** [draw_indirect] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/drawIndirect}draws} primitives. *)

      val draw_indexed_indirect : t -> Buffer.t -> offset:int -> unit
      (** [draw_indexed_indirect] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/drawIndirectIndexed}draws} indexed primitives. *)

      (** {1:debug Debug commands} *)

      val push_debug_group : t -> Jstr.t -> unit
      (** [push_debug_group e l] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/pushDebugGroup}starts} a debug group
          [l] on [e]. *)

      val pop_debug_group : t -> unit
      (** [pop_debug_group e] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/popDebugGroup}ends} the debug group o n [e]. *)

      val insert_debug_marker : t -> Jstr.t -> unit
      (** [insert_debug_marker e l] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderBundleEncoder/insertDebugMarker}marks} a point [l] in [e]. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end
  end

  (** Render passes. *)
  module Render_pass : sig

    (** Load operations. *)
    module Load_op : sig
      type t = Jstr.t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#enumdef-gpuloadop}[GPULoadOp]}
          values. *)

      val load : t
      val clear : t
    end

    (** Store operations. *)
    module Store_op : sig
      type t = Jstr.t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#enumdef-gpustoreop}[GPUStoreOp]}
          values. *)

      val store : t
      val discard : t
    end

    (** Timestamp writes. *)
    module Timestamp_writes : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderpasstimestampwrites}
          [GPURenderPassTimestampWrites]} objects. *)

      val v :
        ?beginning_of_pass_write_index:int ->
        ?end_of_pass_write_index:int -> query_set:Query.Set.t -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderpasstimestampwrites}
          [GPURenderPassTimestampWrites]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Color attachments. *)
    module Color_attachment : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderpasscolorattachment}
          [GPURenderPassColorAttachment]} objects. *)

      val v :
        ?resolve_target:Texture.View.t -> ?clear_value:Color.t ->
        view:Texture.View.t -> load_op:Jstr.t -> store_op:Jstr.t -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderpasscolorattachment}
          [GPURenderPassColorAttachment]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Depth and stencil attachments. *)
    module Depth_stencil_attachment : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderpassdepthstencilattachment}[GPURenderPassDepthStencilAttachment]} objects. *)

      val v :
        ?depth_clear_value:float ->
        ?depth_load_op:Jstr.t ->
        ?depth_store_op:Jstr.t ->
        ?depth_read_only:bool ->
        ?stencil_clear_value:int ->
        ?stencil_load_op:Jstr.t ->
        ?stencil_store_op:Jstr.t ->
        ?stencil_read_only:bool -> view:Texture.View.t -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderpassdepthstencilattachment}[GPURenderPassDepthStencilAttachment]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Descriptors. *)
    module Descriptor : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderpassdescriptor}
          [GPURenderPassDescriptor]} objects. *)

      val v :
        ?label:Jstr.t ->
        ?depth_stencil_attachment:Depth_stencil_attachment.t ->
        ?occlusion_query_set:Query.Set.t ->
        ?timestamp_writes:Timestamp_writes.t -> ?max_draw_count:int ->
        color_attachments:Color_attachment.t list -> unit -> t
      (** [v] constructs a
          {{:https://www.w3.org/TR/webgpu/#dictdef-gpurenderpassdescriptor}
          [GPURenderPassDescriptor]} objects with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Encoders. *)
    module Encoder : sig

      (** {1:encoders Encoders} *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder}[GPURenderPassEncoder]} objects. *)

      val label : t -> Jstr.t
      (** [label e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/label}label} of [e]. *)

      val end' : t -> unit
      (** [end e] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/end}ends} the command sequence. *)

      (** {1:setup Setup commands} *)

      val set_pipeline : t -> Render_pipeline.t -> unit
      (** [set_pipline e p] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/setPipeline}sets} the pipeline of [e] to [p] for
          subsequent commands. *)

      val set_viewport :
        t -> x:float -> y:float -> w:float -> h:float -> min_depth:float ->
        max_depth:float -> unit
      (** [set_viewport] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/setViewport}sets} the viewport. *)

      val set_scissor_rect : t -> x:int -> y:int -> w:int -> h:int -> unit
      (** [set_scissor_rect] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/setScissorRect}sets} the scissor rectangle. *)

      val set_blend_constant : t -> Color.t -> unit
      (** [set_blend_constant] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/setBlendConstant}sets} the blend color constant. *)

      val set_stencil_reference : t -> int -> unit
      (** [set_stencil_reference] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/setStencilReference}sets} the stencil reference. *)

      val set_bind_group :
        ?dynamic_offsets:int list -> ?group:Bind_group.t ->t -> index:int ->
        unit
      (** [set_bind_group] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/setBindGroup}sets} a bind group for subsequent commands. *)
      val set_bind_group' :
        ?group:Bind_group.t -> t -> index:int -> dynamic_offsets:int array ->
        offsets_start:int -> offsets_length:int -> unit
      (** [set_bind_group'] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/setBindGroup}sets} a bind group for subsequent
          commands. *)

      val set_index_buffer :
        ?offset:int -> ?size:int -> t -> Buffer.t -> format:Index_format.t ->
        unit
      (** [set_index_buffer] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/setIndexBuffer}sets} the index data for subsequent
          commands. *)

      val set_vertex_buffer :
        ?buffer:Buffer.t -> ?offset:int -> ?size:int -> t -> slot:int ->
        unit
      (** [set_index_buffer] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/setIndexBuffer}sets} sets the vertex data for subsequent
          commands. *)

      (** {1:bundle_and_draw Bundle and draw commands} *)

      val execute_bundles : t -> Render_bundle.t list -> unit
      (** [execute_bundles e bs]
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/executeBundles}executes} bundles [bs] on [e]. *)

      val draw :
        ?first_instance:int -> ?first_vertex:int -> ?instance_count:int ->
        t -> vertex_count:int -> unit
      (** [draw] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/draw}draws} primitives. *)

      val draw_indexed :
        ?first_instance:int -> ?base_vertex:int -> ?first_index:int ->
        ?instance_count:int -> t -> index_count:int -> unit
      (** [draw_indexed] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/drawIndexed}draws} indexed primitives. *)

      val draw_indirect : t -> Buffer.t -> offset:int -> unit
      (** [draw_indirect] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/drawIndirect}draws} primitives. *)

      val draw_indexed_indirect : t -> Buffer.t -> offset:int -> unit
      (** [draw_indexed_indirect] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/drawIndirectIndexed}draws} indexed primitives. *)

      (** {1:debug Debug commands} *)

      val push_debug_group : t -> Jstr.t -> unit
      (** [push_debug_group e l] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/pushDebugGroup}starts} a debug group
          [l] on [e]. *)

      val pop_debug_group : t -> unit
      (** [pop_debug_group e] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/popDebugGroup}ends} the debug group o n [e]. *)

      val insert_debug_marker : t -> Jstr.t -> unit
      (** [insert_debug_marker e l] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPURenderPassEncoder/insertDebugMarker}marks} a point [l] in [e]. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end
  end

  (** {2:commands_queues Commands and queues} *)

  (** Command buffers and encoders. *)
  module Command :  sig

    type buffer := Buffer.t

    (** Buffers. *)
    module Buffer : sig

      (** Descriptors. *)
      module Descriptor : sig
        type t
        (** The type for {{:https://www.w3.org/TR/webgpu/#dictdef-gpucommanbufferdescriptor}[GPUCommandBufferDescriptors]} objects *)

        val v : ?label:Jstr.t -> unit -> t
        (** [v] constructs a {{:https://www.w3.org/TR/webgpu/#dictdef-gpucommandbufferdescriptor}[GPUCommandBufferDescriptors]} object with given
            parameters. *)

        (**/**) include Jv.CONV with type t := t (**/**)
      end

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandBuffer}[GPUCommandBuffer]} objects. *)

      val label : t -> Jstr.t
      (** [label b] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandBuffer/label}label} of [b]. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    (** Encoders. *)
    module Encoder : sig

      (** {1:encoders Encoders} *)

      (** Descriptors. *)
      module Descriptor : sig
        type t
        (** The type for {{:https://www.w3.org/TR/webgpu/#dictdef-gpucommandencoderdescriptor}[GPUCommandEncoderDescriptors]} objects *)

        val v : ?label:Jstr.t -> unit -> t
        (** [v] constructs a {{:https://www.w3.org/TR/webgpu/#dictdef-gpucommandencoderdescriptor}[GPUCommandEncoderDescriptors]} object with given
            parameters. *)

        (**/**) include Jv.CONV with type t := t (**/**)
      end

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder}GPUCommandEncoder} objects. *)

      val label : t -> Jstr.t
      (** [label e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/label}label} of [e]. *)

      val finish : ?descr:Buffer.Descriptor.t -> t -> Buffer.t
      (** [finish e] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/finish}finishes} recording commands on [e]. *)

      val begin_render_pass :
        t -> Render_pass.Descriptor.t -> Render_pass.Encoder.t
      (** [begin_render_pass] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/beginRenderPass}begins} encoding a render pass. *)

      val begin_compute_pass :
        t -> Compute_pass.Descriptor.t -> Compute_pass.Encoder.t
      (** [begin_compute_pass] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/beginComputePass}begins} encoding a compute pass. *)

      val clear_buffer : ?size:int -> ?offset:int -> t -> buffer -> unit
      (** [clear_buffer] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/clearBuffer}clears} a buffer. *)

      val write_timestamp : t -> Query.Set.t -> int -> unit
      (** [write_timetamp] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/writeTimestamp}writes} a timetamp. *)

      val resolve_query_set :
        t -> Query.Set.t -> first:int -> count:int -> dst:buffer ->
        dst_offset:int -> unit
      (** [resolve_query_set] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/resolveQuerySet}copies} a query set in a buffer. *)

      (** {1:copies Copy commands} *)

      val copy_buffer_to_buffer :
        t -> src:buffer -> src_offset:int -> dst:buffer -> dst_offset:int ->
        size:int -> unit
      (** [copy_buffer_to_buffer] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/copyBufferToBuffer}copies} betwen two buffers. *)

      val copy_buffer_to_texture :
        t -> src:Image.Copy_buffer.t -> dst:Image.Copy_texture.t ->
        size:Extent_3d.t -> unit
      (** [copy_buffer_to_texture] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/copyBufferToTexture}copies} betwen a buffer and
          a texture. *)

      val copy_texture_to_buffer :
        t -> src:Image.Copy_texture.t -> dst:Image.Copy_buffer.t ->
        size:Extent_3d.t -> unit
      (** [copy_texture_to_buffer] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/copyTextureToBuffer}copies} betwen a texture and
          a buffer. *)

      val copy_texture_to_texture :
        t -> src:Image.Copy_texture.t -> dst:Image.Copy_texture.t ->
        size:Extent_3d.t -> unit
      (** [copy_texture_to_texture] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/copyTextureToTexture}copies} betwen a texture and
          a texture. *)

      (** {1:debug Debug commands} *)

      val push_debug_group : t -> Jstr.t -> unit
      (** [push_debug_group e l] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/pushDebugGroup}starts} a debug group
          [l] on [e]. *)

      val pop_debug_group : t -> unit
      (** [pop_debug_group e] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/popDebugGroup}ends} the debug group o n [e]. *)

      val insert_debug_marker : t -> Jstr.t -> unit
      (** [insert_debug_marker e l] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCommandEncoder/insertDebugMarker}marks} a point [l] in [e]. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end
  end

  (** Queues. *)
  module Queue : sig

    (** Descriptors. *)
    module Descriptor : sig
      type t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#gpuqueuedescriptor}
          [GPUQueueDescriptor]} objects. *)

      val v : ?label:Jstr.t -> unit -> t
      (** [v] constructs a {{:https://www.w3.org/TR/webgpu/#gpuqueuedescriptor}
          [GPUQueueDescriptor]} object with given parameters. *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUQueue}
        [GPUQueue]} objects. *)

    val label : t -> Jstr.t
    (** [label q] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUQueue/label}
        label} of [q]. *)

    val submit : t -> Command.Buffer.t list -> unit
    (** [submit q bs]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUQueue/submit}
        submits} buffers [bs] on [q]. *)

    val on_submitted_work_done : t -> unit Fut.or_error
    (** [on_submitted_work_done q] resovles when submitted work on [q] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUQueue/onSubmittedWorkDone}
        is done}. *)

    val write_buffer :
      ?src_offset:int -> ?size:int -> t -> dst:Buffer.t -> dst_offset:int ->
      src:('a, 'b) Brr.Tarray.t -> unit
    (** [write_buffer] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUQueue/writeBuffer}writes} a buffer. *)

    val write_texture :
      t -> dst:Image.Copy_texture.t -> src:('a, 'b) Brr.Tarray.t ->
      src_layout:Image.Data_layout.t -> size:Extent_3d.t -> unit
    (** [write_texture] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUQueue/writeTexture}writes} a texture. *)

    val copy_external_image_to_texture :
      t -> src:Image.Copy_external_image.t ->
      dst:Image.Copy_texture_tagged.t -> size:Extent_3d.t -> unit
    (** [copy_external_image_to_texture]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUQueue/copyExternalImageToTexture}copies} an image to a texture. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** {1:devices_and_adapters Adapters and devices}  *)

    (** Supported limits. *)
  module Supported_limits : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUSupportedLimits}
        [GPUSupportedLimits]} objects. *)

    val max_texture_dimension_1d : t -> int
    val max_texture_dimension_2d : t -> int
    val max_texture_dimension_3d : t -> int
    val max_texture_array_layers : t -> int
    val max_bind_groups : t -> int
    val max_bind_groups_plus_vertex_buffers : t -> int
    val max_bindings_per_bind_group : t -> int
    val max_dynamic_uniform_buffers_per_pipeline_layout : t -> int
    val max_dynamic_storage_buffers_per_pipeline_layout : t -> int
    val max_sampled_textures_per_shader_stage : t -> int
    val max_samplers_per_shader_stage : t -> int
    val max_storage_buffers_per_shader_stage : t -> int
    val max_storage_textures_per_shader_stage : t -> int
    val max_uniform_buffers_per_shader_stage : t -> int
    val max_uniform_buffer_binding_size : t -> int
    val max_storage_buffer_binding_size : t -> int
    val min_uniform_buffer_offset_alignment : t -> int
    val min_storage_buffer_offset_alignment : t -> int
    val max_vertex_buffers : t -> int
    val max_buffer_size : t -> int
    val max_vertex_attributes : t -> int
    val max_vertex_buffer_array_stride : t -> int
    val max_inter_stage_shader_components : t -> int
    val max_inter_stage_shader_variables : t -> int
    val max_color_attachments : t -> int
    val max_color_attachment_bytes_per_sample : t -> int
    val max_compute_workgroup_storage_size : t -> int
    val max_compute_invocations_per_workgroup : t -> int
    val max_compute_workgroup_size_x : t -> int
    val max_compute_workgroup_size_y : t -> int
    val max_compute_workgroup_size_z : t -> int
    val max_compute_workgroups_per_dimension : t -> int

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Features names. *)
  module Feature_name : sig
    type t = Jstr.t
    (** The type for the {{:https://www.w3.org/TR/webgpu/#gpufeaturename}
        [GPUFeatureName]} enum. *)

    val depth_clip_control : t
    val depth32float_stencil8 : t
    val texture_compression_bc : t
    val texture_compression_etc2 : t
    val texture_compression_astc : t
    val timestamp_query : t
    val indirect_first_instance : t
    val shader_f16 : t
    val rg11b10ufloat_renderable : t
    val bgra8unorm_storage : t
    val float32_filterable : t
    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Errors. *)
  module Error : sig

    (** Error filters. *)
    module Filter : sig
      type t = Jstr.t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#enumdef-gpuerrorfilter}
          [GPUErrorFilter]} values *)

      val validation : t
      val out_of_memory : t
      val internal : t
    end

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUError}
        [GPUError]} objects. *)

    val message : t -> Jstr.t
    (** [message e] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUError/message}
        message} of [e]. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Pipeline errors. *)
  module Pipeline_error : sig

    (** Error reasons. *)
    module Reason : sig
      type t = Jstr.t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#enumdef-gpupipelineerrorreason}
          [GPUPipelineErrorReason]} values. *)

      val validation : t
      val internal : t
    end

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUPipelineError}[GPUPipelineError]} objects. *)

    val message : t -> Jstr.t
    (** [message e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/DOMException/message}message} of [e]. *)

    val reason : t -> Jstr.t
    (** [reason e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUPipelineError/reason}reason} of [e]. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Devices. *)
  module Device : sig

    (** {1:devices Devices} *)

    (** Device lost reasons. *)
    module Lost_reason : sig
      type t = Jstr.t
      (** The type for
          {{:https://www.w3.org/TR/webgpu/#enumdef-gpudevicelostreason}
          [GPUDeviceLostReason]} values. *)

      val unknown : t
      val destroyed : t
    end

    (** Device lost information. *)
    module Lost_info : sig
      type t
      (** The type for {{:https://www.w3.org/TR/webgpu/#gpudevicelostinfo}
          [GPUDeviceLostInfo]} objects. *)

      val reason : t -> Jstr.t
      val message : t -> Jstr.t

      (**/**) include Jv.CONV with type t := t (**/**)
    end
    (** Descriptors. *)
    module Descriptor : sig

      type required_limits
      (** The type for {!val-required_limits}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUAdapter/requestDevice}[GPUDeviceDescriptor]} objects. *)

      val v :
        ?label:Jstr.t -> ?required_features:Feature_name.t list ->
        ?required_limits:required_limits ->
        ?default_queue:Queue.Descriptor.t -> unit -> t

      val required_limits :
        ?max_texture_dimension_1d:int ->
        ?max_texture_dimension_2d:int ->
        ?max_texture_dimension_3d:int ->
        ?max_texture_array_layers:int ->
        ?max_bind_groups:int ->
        ?max_bind_groups_plus_vertex_buffers:int ->
        ?max_bindings_per_bind_group:int ->
        ?max_dynamic_uniform_buffers_per_pipeline_layout:int ->
        ?max_dynamic_storage_buffers_per_pipeline_layout:int ->
        ?max_sampled_textures_per_shader_stage:int ->
        ?max_samplers_per_shader_stage:int ->
        ?max_storage_buffers_per_shader_stage:int ->
        ?max_storage_textures_per_shader_stage:int ->
        ?max_uniform_buffers_per_shader_stage:int ->
        ?max_uniform_buffer_binding_size:int ->
        ?max_storage_buffer_binding_size:int ->
        ?min_uniform_buffer_offset_alignment:int ->
        ?min_storage_buffer_offset_alignment:int ->
        ?max_vertex_buffers:int ->
        ?max_buffer_size:int ->
        ?max_vertex_attributes:int ->
        ?max_vertex_buffer_array_stride:int ->
        ?max_inter_stage_shader_components:int ->
        ?max_inter_stage_shader_variables:int ->
        ?max_color_attachments:int ->
        ?max_color_attachment_bytes_per_sample:int ->
        ?max_compute_workgroup_storage_size:int ->
        ?max_compute_invocations_per_workgroup:int ->
        ?max_compute_workgroup_size_x:int ->
        ?max_compute_workgroup_size_y:int ->
        ?max_compute_workgroup_size_z:int ->
        ?max_compute_workgroups_per_dimension:int -> unit -> required_limits

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice}
        [GPUDevice]} objects. *)

    val as_target : t -> Brr.Ev.target
    (** [as_target d] is [d] as an event target. *)

    val label : t -> Jstr.t
    (** [label d] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/label}label} of [d]. *)

    val has_feature : t -> Feature_name.t -> bool
    (** [has_feature d n] is [true] iff [n] is a {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/features}features} of [d]. *)

    val limits : t -> Supported_limits.t
    (** [limits d] are the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/limits}limits} of [d]. *)

    val lost : t -> Lost_info.t Fut.or_error
    (** [lost d] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/lost}lost} property of [d]. *)

    val queue : t -> Queue.t
    (** [queue d] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/queue}queue} of [d]. *)

    val destroy : t -> unit
    (** [destroy d]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/destroy}
        destroys} [d]. *)

    (** {1:error_scopes Error scopes} *)

    val push_error_scope : t -> Error.Filter.t -> unit
    (** [push_error_scope] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/pushErrorScope}pushes} an error scope. *)

    val pop_error_scope : t -> Error.t option Fut.or_error
    (** [pop_error_scope] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/popErrorScope}pops} the last error scope. *)

    (** {1:creating Creating ressources} *)

    val create_buffer : t -> Buffer.Descriptor.t -> Buffer.t
    (** [create_buffer d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBuffer}creates} a buffer on [d] according to [descr].
        See the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBuffer#validation}validation rules} on [descr]. *)

    val create_texture : t -> Texture.Descriptor.t -> Texture.t
    (** [create_texture d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createTexture}creates} a texture on [d] according to [descr]. *)

    val import_external_texture :
      t -> Texture.External.Descriptor.t -> Texture.External.t
    (** [import_external_texture d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/importExternalTexture}imports} an external texture on
        [d] according to [descr]. *)

    val create_sampler : t -> Sampler.Descriptor.t -> Sampler.t
    (** [create_sampler d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createSampler}creates} a sampler on [d] according to [descr]. *)

    val create_bind_group_layout :
      t -> Bind_group.Layout.Descriptor.t -> Bind_group.Layout.t
    (** [create_bind_group_layout d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroupLayout}creates} a bind group layout
        on [d] according to [descr]. *)

    val create_bind_group : t -> Bind_group.Descriptor.t -> Bind_group.t
    (** [create_bind_group d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createBindGroup}creates} a bind group
        on [d] according to [descr]. *)

    val create_pipeline_layout :
      t -> Pipeline_layout.Descriptor.t -> Pipeline_layout.t
    (** [create_pipeline_layout d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createPipelineLayout}creates} a pipeline layout
        on [d] according to [descr]. *)

    val create_shader_module :
      t -> Shader_module.Descriptor.t -> Shader_module.t
    (** [create_shader_module d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createShaderModule}creates} a shader module on [d]
        according to [descr]. *)

    val create_compute_pipeline :
      t -> Compute_pipeline.Descriptor.t -> Compute_pipeline.t
    (** [create_compute_pipeline d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createComputePipeline}creates} a compute pipeline on [d]
        according to [descr]. *)

    val create_compute_pipeline_async :
      t -> Compute_pipeline.Descriptor.t ->
      (Compute_pipeline.t, Pipeline_error.t) result Fut.t
    (** [create_compute_pipeline_async d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createComputePipelineAsync}creates} a compute pipeline on [d] according to [descr]. *)

    val create_render_pipeline :
      t -> Render_pipeline.Descriptor.t -> Render_pipeline.t
    (** [create_render_pipeline d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createRenderPipeline}creates} a render pipeline on [d]
        according to [descr]. *)

    val create_render_pipeline_async :
      t -> Render_pipeline.Descriptor.t ->
      (Compute_pipeline.t, Pipeline_error.t) result Fut.t
    (** [create_render_pipeline_async d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createRenderPipelineAsync}creates} a render pipeline on [d] according to [descr]. *)

    val create_query_set : t -> Query.Set.Descriptor.t -> Query.Set.t
    (** [create_query_set d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createQuerySet}creates} a query set on [d] according to
    [descr]. *)

    val create_render_bundle_encoder :
      t -> Render_bundle.Encoder.Descriptor.t -> Render_bundle.Encoder.t
    (** [create_render_bundle_encoder d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createRenderBundleEncoder}creates} a render
        bundle encoder on [d] according to [descr]. *)

    val create_command_encoder :
      ?descr:Command.Encoder.Descriptor.t -> t -> Command.Encoder.t
    (** [create_command_encoder d descr] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/createCommandEncoder}creates} a command
        encoder on [d] according to [descr]. *)

    (** {1:events Events} *)

    (** Events. *)
    module Ev : sig

      (** Uncaptured error. *)
      module Uncaptured_error : sig
        type t
        (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUUncapturedErrorEvent}[GPUUncapturedErrorEvent]}. *)

        val error : t -> Error.t
        (** [error ev] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUUncapturedErrorEvent/error}error} of [ev]. *)
      end

      val uncapturederror : Uncaptured_error.t Brr.Ev.type'
      (** [uncaptured_error] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUDevice/uncapturederror_event}[uncapturederror]} event. *)
    end
    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** Adapters. *)
  module Adapter : sig

    (** Adapter info *)
    module Info : sig
      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUAdapterInfo}
          [GPUAdapterInfo]} objects. *)

      val vendor : t -> Jstr.t
      (** [vendor i] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUAdapterInfo/vendor}vendor} of [i]. *)

      val architecture : t -> Jstr.t
      (** [architecture i] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUAdapterInfo/architecture}architecture} of [i]. *)

      val device : t -> Jstr.t
      (** [device i] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUAdapterInfo/device}device} of [i] *)

      val description : t -> Jstr.t
      (** [description i] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUAdapterInfo/description}description} of [i] *)

      (**/**) include Jv.CONV with type t := t (**/**)
    end

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUAdapter}
        [GPUAdapter]} objects. *)

    val has_feature : t -> Feature_name.t -> bool
    (** [has_feature a n] is [true] iff [n] is a
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUAdapter/features}
        features} of [a]. *)

    val limits : t -> Supported_limits.t
    (** [limits a] are the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUAdapter/limits}
        limits} of [a]. *)

    val is_fallback_adapter : t -> bool
    (** [is_fallback_adapter a] indicates if [a] is a
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUAdapter/isFallbackAdapter}fallback adapter}. *)

    val request_device :
      ?descriptor:Device.Descriptor.t -> t -> Device.t Fut.or_error
    (** [request_device a]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUAdapter/requestDevice}requests} the device of [a]. *)

    val request_adapter_info :
      t -> unmask_hints:Jstr.t list -> Info.t Fut.or_error
    (** [request_adapter_info a ~unmask_hints] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUAdapter/requestAdapterInfo}requests} the adapter info of [a]. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end

  (** {1:gpu GPU object} *)

  type t
   (** The type for
       {{:https://developer.mozilla.org/en-US/docs/Web/API/GPU}GPU} objects. *)

  val of_navigator : Brr.Navigator.t -> t option
  (** [of_navigator n] is the [gpu] object of [n] (if any). *)

  val get_preferred_canvas_format : t -> Texture.Format.t
(** [get_preferred_canvas_format g] is the 8-bit depth
    {{:https://developer.mozilla.org/en-US/docs/Web/API/GPU/getPreferredCanvasFormat}optimal texture format}. *)

  val has_wgsl_language_feature : t -> Jstr.t -> bool
  (** [has_wgsl_language_features g n] is [true] iff [g] has WGSL
      feature [n]. *)

  (** {2:adapter Adapter request} *)

  (** Power preference. *)
  module Power_preference : sig
    type t
    (** The type for the
        {{:https://www.w3.org/TR/webgpu/#enumdef-gpupowerpreference}
        [GPUPowerPreference]} enum. *)

    val low_power : t
    val high_performance : t
  end

  type opts
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/GPU/requestAdapter}
      adapter request} options. *)

  val opts :
    ?power_preference:Power_preference.t ->
    ?force_fallback_adapater:bool -> unit -> opts
  (** [opts] are options for {!request_adapter}. *)

  val request_adapter : ?opts:opts -> t -> Adapter.t option Fut.or_error
  (** [request_adapter gpu]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/GPU/requestAdapter}
      requests} an adapter from [gpu]. *)

  (**/**) include Jv.CONV with type t := t (**/**)

  (** {1:context Canvas context} *)

  (** GPU canvas contexts. *)
  module Canvas_context : sig

    (** Texture alpha modes. *)
    module Alpha_mode : sig
      type t = Jstr.t
      (** The type {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCanvasContext/configure#alphamode}context alpha modes}. *)

      val opaque : t
      val premultiplied : t
    end

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCanvasContext}[GPUCanvasContext]} objects. *)

    val get : Brr_canvas.Canvas.t -> t option
    (** [get cnv] is {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/getContext}gets} a GPU canvas context from [cnv]. *)

    val get_current_texture : t -> Texture.t
    (** [get_current_texture ctx] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCanvasContext/getCurrentTexture}current texture} of [ctx]. *)

    (** {1:configuring Configuring} *)

    type conf
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCanvasContext/configure#configuration}context configuration objects}. *)

    val conf :
      ?usage:Texture.Usage.t -> ?view_formats:Texture.Format.t list ->
      ?color_space:Jstr.t -> ?alpha_mode:Alpha_mode.t -> Device.t ->
      Texture.Format.t -> conf
    (** [conf] constructs a {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCanvasContext/configure#configuration}context configuration object}. *)

    val configure : t -> conf -> unit
    (** [configure ctx conf] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCanvasContext/configure}configures} context [ctx] with [conf]. *)

    val unconfigure : t -> unit
    (** [unconfigure ctx conf] {{:https://developer.mozilla.org/en-US/docs/Web/API/GPUCanvasContext/unconfigure}unconfigures} context [ctx]. *)

    (**/**) include Jv.CONV with type t := t (**/**)
  end
end
