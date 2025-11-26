(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Browser APIs.

    Open this module to use it. It defines only modules in your scope. *)

(** {1:data Data containers and encodings} *)

(** Typed arrays. *)
module Tarray : sig

  (** {1:buffer Buffers} *)

  (** [ArrayBuffer] objects (byte buffers).  *)
  module Buffer : sig

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/ArrayBuffer}[ArrayBuffer]}
      objects. They hold the bytes of typed arrays. *)

    val create : int -> t
    (** [create n] is a new buffer with [n] bytes. *)

    val byte_length : t -> int
    (** [byte_length b] is the byte length of [b]. *)

    val slice : ?start:int -> ?stop:int -> t -> t
    (** [slice ~start ~stop b] is a new buffer holding the bytes of
        [b] in range \[[start];[stop-1]\]. This is {b a copy}.
        [start] defaults to [0] and [stop] to [byte_length b].

        If [start] or [stop] are negative they are subtracted from
        [byte_length b]. This means that [-1] denotes the last byte of
        the buffer. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** [DataView objects] (byte-level typed data access on [ArrayBuffer]s).

      This module allows to read and write buffers with any data element
      at any byte offset. *)
  module Data_view : sig

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DataView}DataView} objects. *)

    val of_buffer : ?byte_offset:int -> ?byte_length:int -> Buffer.t -> t
    (** [of_buffer ~byte_offset ~length b k] provides access to
        [byte_length] (defaults to [Buffer.byte_length b]) bytes of [b]
        starting at byte offset [byte_offset]. *)

    val buffer : t -> Buffer.t
    (** [buffer d] is the untyped buffer of [d]. *)

    val byte_offset : t -> int
    (** [byte_offset d] is the byte index where [d] starts in [buffer d]. *)

    val byte_length : t -> int
    (** [byte_length d] is the byte length of [d]. *)

    (** {1:reads Reads}

        {b Suffixes.} [_be] stands for big endian, [_le] for little endian. *)

    val get_int8 : t -> int -> int
    val get_int16_be : t -> int -> int
    val get_int16_le : t -> int -> int
    val get_int32_be : t -> int -> int32
    val get_int32_le : t -> int -> int32

    val get_uint8 : t -> int -> int
    val get_uint16_be : t -> int -> int
    val get_uint16_le : t -> int -> int
    val get_uint32_be : t -> int -> int32
    val get_uint32_le : t -> int -> int32

    val get_float32_be : t -> int -> float
    val get_float32_le : t -> int -> float
    val get_float64_be : t -> int -> float
    val get_float64_le : t -> int -> float

    (** {1:writes Writes}

        {b Suffixes.} [_be] stands for big endian, [_le] for little endian. *)

    val set_int8 : t -> int -> int -> unit
    val set_int16_be : t -> int -> int -> unit
    val set_int16_le : t -> int -> int -> unit
    val set_int32_be : t -> int -> int32 -> unit
    val set_int32_le : t -> int -> int32 -> unit

    val set_uint8 : t -> int -> int -> unit
    val set_uint16_be : t -> int -> int -> unit
    val set_uint16_le : t -> int -> int -> unit
    val set_uint32_be : t -> int -> int32 -> unit
    val set_uint32_le : t -> int -> int32 -> unit

    val set_float32_be : t -> int -> float -> unit
    val set_float32_le : t -> int -> float -> unit
    val set_float64_be : t -> int -> float -> unit
    val set_float64_le : t -> int -> float -> unit

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** {1:types Array types} *)

  type ('a, 'b) type' =
  | Int8 : (int, Bigarray.int8_signed_elt) type'
  | Int16 : (int, Bigarray.int16_signed_elt) type'
  | Int32 : (int32, Bigarray.int32_elt) type'
  | Uint8 : (int, Bigarray.int8_unsigned_elt) type'
  | Uint8_clamped : (int, Bigarray.int8_unsigned_elt) type'
  | Uint16 : (int, Bigarray.int16_unsigned_elt) type'
  | Uint32 : (int32, Bigarray.int32_elt) type'
  | Float32 : (float, Bigarray.float32_elt) type'
  | Float64 : (float, Bigarray.float64_elt) type' (** *)
  (** The type for typed array whose elements are of type ['b] and
      are accessed with type ['a]. *)

  val type_size_in_bytes : ('a, 'b) type' -> int
  (** [type_size_in_bytes t] is the number of bytes used to store
      an element of type ['b]. *)

  (** {1:typed Typed arrays}

      {b Note.} In the functions below.
      {ul
      {- Indices can always be negative in which case they are subtracted
         from {!length}. This means that [-1] denotes the last element of
         the buffer.}
      {- If unspecified [start] defaults to [0].}
      {- If unspecified [stop] defaults to [length b].}} *)

  type ('a, 'b) t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/ArrayBufferView}
      [ArrayBufferView]} objects (typed access to [ArrayBuffer] objects)
      whose elements are of type ['b] and accessed with type ['a]. See
      the {{!type_aliases}type aliases}. *)

  val create : ('a, 'b) type' -> int -> ('a, 'b) t
  (** [create n t] is an array of type [t] with [n] elements of type ['b]
      initialised to their zero. See also {{!converting} converting}. *)

  val of_buffer :
    ('a, 'b) type' -> ?byte_offset:int -> ?length:int -> Buffer.t -> ('a, 'b) t
  (** [of_buffer t ~byte_offset ~length b] is an array of type [t] with
      [length] elements of type ['b] starting at the byte offset [byte_offset]
      of [b]. [byte_offset] defaults to [0] and length so as to get to
      the end of the buffer. *)

  val buffer : ('a, 'b) t -> Buffer.t
  (** [buffer a] is the untyped buffer of [a]. *)

  val byte_offset : ('a, 'b) t -> int
  (** [byte_offset a] is the byte index where [a] starts in [buffer a]. *)

  val byte_length : ('a, 'b) t -> int
  (** [byte_length a] is the byte length of [a]. *)

  val length : ('a, 'b) t -> int
  (** [length a] are the number of elements in [a]. *)

  val type' : ('a, 'b) t -> ('a, 'b) type'
  (** [type' a] is the type of [a]. *)

  (** {1:set Setting, copying and slicing} *)

  val get : ('a, 'b) t -> int -> 'a
  [@@ocaml.deprecated
    "Use Brr.Tarray.to_bigarray1 and operate on the bigarray instead."]
  (** [get a i] is the element of [a] at [i]. *)

  val set : ('a, 'b) t -> int -> 'a -> unit
  [@@ocaml.deprecated
    "Use Brr.Tarray.to_bigarray1 and operate on the bigarray instead."]
  (** [set a i v] sets the element of [a] at [i] to [v]. *)

  val set_tarray : ('a, 'b) t -> dst:int -> ('c, 'd) t -> unit
  (** [set_tarray a ~dst b] sets the values of [a] starting
      at index [dst] with those of [b] which are converted to match
      the type of [a] ({{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/TypedArray/set}unclear} how exactly). *)

  val fill : ?start:int -> ?stop:int -> 'a -> ('a, 'b) t -> unit
  (** [fill ~start ~stop v a] sets the elements in range [[start];[stop-1]]
      to [v]. *)

  val copy_within : ?start:int -> ?stop:int -> dst:int -> ('a, 'b) t -> unit
  (** [copy_within ~start ~stop ~dst a] copies at at [dst] the elements in
      range [[start];[stop-1]]. *)

  val slice : ?start:int -> ?stop:int -> ('a, 'b) t -> ('a, 'b) t
  (** [slice ~start ~stop a] is a new array holding a copy of the
      bytes of [a] in range \[[start];[stop-1]\]. This is {b a copy},
      use {!sub} to share the data. *)

  val sub : ?start:int -> ?stop:int -> ('a, 'b) t -> ('a, 'b) t
  (** [sub ~start ~stop a] is an array that spans the bytes of [b] in
      range \[[start];[stop-1]\]. This is {b not a copy}, use {!slice}
      to make a copy. *)

  (** {1:predicates Predicates} *)

  val find : (int -> 'a -> bool) -> ('a, 'b) t -> 'a option
  (** [find sat a] is the first index a.[i] for which [sat i a.[i]] is true. *)

  val find_index : (int -> 'a -> bool) -> ('a, 'b) t -> int option
  (** [find sat a] is the first index i for which [sat i a.[i]] is true. *)

  val for_all : (int -> 'a -> bool) -> ('a, 'b) t -> bool
  (** [for_all sat a] is [true] iff all elements [a.[i]] of [b] satisfy
      [sat i a.[i]]. *)

  val exists : (int -> 'a -> bool) -> ('a, 'b) t -> bool
  (** [exists sat a] is [true] iff one elements [a.[i]] of [b] satisfies
      [sat i a.[i]]. *)

  (** {1:traversal Traversals} *)

  val filter : (int -> 'a -> bool) -> ('a, 'b) t -> ('a, 'b) t
  (** [filter sat a] is an array with the elements [a.[i]] of [a] for which
      [sat i a.[i]] is [true]. *)

  val iter : (int -> 'a -> unit) -> ('a, 'b) t -> unit
  (** [iter f a] calls [f i a.[i]] on each element of [a]. *)

  val map : ('a -> 'a) -> ('a, 'b) t -> ('a, 'b) t
  (** [map f a] is a new typed array with elements of [a] mapped by [f]. *)

  val fold_left : ('c -> 'a -> 'c) -> 'c -> ('a, 'b) t -> 'c
  (** [fold_left f acc a] folds [f] over the elements of [a] starting with
      [acc]. *)

  val fold_right : ('a -> 'c -> 'c) -> ('a, 'b) t -> 'c -> 'c
  (** [fold_right f acc a] folds [f] over the elements of [a] starting with
      [acc]. *)

  val reverse : ('a, 'b) t -> ('a, 'b) t
  (** [reverse a] is a new array with [a]'s elements reversed. *)

  (** {1:type_aliases Type aliases}

      Use these in interfaces. *)

  type int8 = (int, Bigarray.int8_signed_elt) t
  type int16 = (int, Bigarray.int16_signed_elt) t
  type int32 = (Int32.t, Bigarray.int32_elt) t
  type uint8 = (int, Bigarray.int8_unsigned_elt) t
  type uint8_clamped = (int, Bigarray.int8_unsigned_elt) t
  type uint16 = (int, Bigarray.int16_unsigned_elt) t
  type uint32 = (Int32.t, Bigarray.int32_elt) t
  type float32 = (float, Bigarray.float32_elt) t
  type float64 = (float, Bigarray.float64_elt) t

  (** {1:converting Converting} *)

  val of_tarray : ('c, 'd) type' -> ('a, 'b) t -> ('c, 'd) t
  (** [of_tarray t a] is an array of type [t] with the elements of
      [a] converted accordingly ({{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/TypedArray#Constructor}unclear} how
      exactly). *)

  val uint8_of_buffer : Buffer.t -> uint8
  (** [uint8_of_buffer b] wraps [b] as an Uint8 typed array. *)

  val of_int_array : ('a, 'b) type' -> int array -> ('a, 'b) t
  (** [of_int_array t arr] is an array of type [t] whose elements
      are the values of [arr], values exceeding the range for the type
      are taken modulo the range bounds (except for [Uint8_clamped]). *)

  val of_float_array : ('a, 'b) type' -> float array -> ('a, 'b) t
  (** [of_int_array t arr] is an array of type [t] whose elements
      are the values of [arr], values exceeding the range for the type
      are taken modulo the range bounds (except for [Uint8_clamped]). *)

  (** {2:string With strings} *)

  val of_jstr : Jstr.t -> uint8
  (** [of_jstr s] is an unsigned byte array with [s] as UTF-8 encoded data. *)

  val to_jstr : uint8 -> (Jstr.t, Jv.Error.t) result
  (** [to_jstr a] is the UTF-8 encoded data [a] as a string. Errors
      if [a] holds invalid UTF-8. *)

  val of_binary_jstr : Jstr.t -> (uint8, Jv.Error.t) result
  (** [of_binary_jstr s] is an unsigned byte array with the bytes of the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/DOMString/Binary}
      JavaScript binary string} [s]. Errors if a code unit of [s] is greater
      than [255]. *)

  val to_binary_jstr : uint8 -> Jstr.t
  (** [to_binary_jstr a] is a
      {{:https://developer.mozilla.org/en-US/docs/Web/API/DOMString/Binary}
      JavaScript binary string} with the unsigned bytes of [a]. *)

  val to_int_jstr : ?sep:Jstr.t -> ('a, 'b) t -> Jstr.t
  (** [to_int_jstr ~sep a] is a string with the elements of [a] printed and
      separated by [sep] (defaults to {!Jstr.sp}). *)

  val to_hex_jstr : ?sep:Jstr.t -> ('a, 'b) t -> Jstr.t
  (** [to_hex_jstr ?sep a] is a string with the bytes of [a] printed in
      lowercase hex and separated by [sep] (defaults to {!Jstr.empty}). *)

  external to_string :  uint8 -> string = "caml_string_of_array"
  (** [to_string a] is an OCaml {e byte} string from the byte array. *)

  (** {1:bigarrays As bigarrays} *)

  val type_to_bigarray_kind : ('a, 'b) type' -> ('a, 'b) Bigarray.kind
  (** [type_to_bigarray_kind t] is [t] as a bigarray kind. [Uint32] is
      mapped on {!Bigarray.int32}. *)

  val type_of_bigarray_kind : ('a, 'b) Bigarray.kind -> ('a, 'b) type' option
  (** [type_of_bigarray_kind k] is [k] as a type array type or [None] if
      there is no corresponding one. *)

  external bigarray_kind : ('a, 'b) t -> ('a,'b) Bigarray.kind =
    "caml_ba_kind_of_typed_array"
  (** [bigarray_kind a] is the bigarray kind of [a]. *)

  external of_bigarray1 :
    ('a, 'b, Bigarray.c_layout) Bigarray.Array1.t -> ('a, 'b) t
    = "caml_ba_to_typed_array"
  (** [of_bigarray1 b] is a typed array with the data of bigarray
      [b]. The data buffer is shared. *)

  external to_bigarray1 :
    ('a, 'b) t -> ('a, 'b, Bigarray.c_layout) Bigarray.Array1.t
    = "caml_ba_from_typed_array"
  (** [to_bigarray b] is a bigarray with the data of bigarray [b]. The
      data buffer is shared. *)

  external of_bigarray :
    ('a, 'b, Bigarray.c_layout) Bigarray.Genarray.t -> ('a, 'b) t
    = "caml_ba_to_typed_array"
  (** [of_bigarray b] is a typed array with the data of bigarray
      [b]. The data buffer is shared. {b XXX.} How is the data laid
      out ? *)

  (**/**)
  external to_jv : ('a, 'b) t -> Jv.t = "%identity"
  external of_jv : Jv.t -> ('a, 'b) t = "%identity"
  (**/**)
end

(** Blob objects.

    See the {{:https://w3c.github.io/FileAPI/#blob-section}Blob Interface}. *)
module Blob : sig

  (** {1:enums Enumerations} *)

  (** The line ending type enum. *)
  module Ending_type : sig
    type t = Jstr.t
    (** The type for line endings.
        {{:https://w3c.github.io/FileAPI/#dom-blobpropertybag-endings}
        [EndingType]} values. *)

    val transparent : Jstr.t
    val native : Jstr.t
  end

  (** {1:blobs Blobs} *)

  type init
  (** The type for blob initialisation objects. *)

  val init : ?type':Jstr.t -> ?endings:Ending_type.t -> unit -> init
  (** [init ()] is a blob initialisation object with given
      {{:https://w3c.github.io/FileAPI/#ref-for-dfn-BlobPropertyBag%E2%91%A0}
      properties}. *)

  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Blob}[Blob]}
      objects. *)

  val of_jstr : ?init:init -> Jstr.t -> t
  (** [of_jstr ~init s] is a blob containing the UTF-8 encoded data of [s]. *)

  val of_array_buffer : ?init:init -> Tarray.Buffer.t -> t
  (** [of_array_buffer ~init b] is a blob containing the bytes of [b]. *)

  val byte_length : t -> int
  (** [byte_length b] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Blob/size}byte
      length} of the blob. *)

  val type' : t -> Jstr.t
  (** [type' b] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Blob/type}MIME type}
      of [b] or {!Jstr.empty} if unknown. *)

  val slice : ?start:int -> ?stop:int -> ?type':Jstr.t -> t -> t
  (** [slice ~start ~stop ~type b] are the bytes in
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Blob/slice}range}
      \[[start];[stop-1]\]
      as blob. [start] defaults to [0] and [stop] to [byte_length b].

      If [start] or [stop] are negative they are subtracted from
      [byte_length b]. This means that [-1] denotes the last byte of the
      blob.

      [type'] specifies the resulting type for the blob, defaults to
      the empty string. *)

  (** {1:loading Loading} *)

  type progress = (float * float) option -> unit
  (** The type for loading progress callbacks.

      If the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/ProgressEvent/lengthComputable}length is computable} the function is periodically called with [Some
      (loaded, total)] which are respectively the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/ProgressEvent/loaded}
      [loaded]} and
      {{:https://developer.mozilla.org/en-US/docs/Web/API/ProgressEvent/total}
      [total]} fields of the progress event. If the length is not computable it
      is called with [None]. *)

  val array_buffer : ?progress:progress -> t -> Tarray.Buffer.t Fut.or_error
  (** [array_buffer b] is an
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Blob/arrayBuffer}
      array buffer} with the contents of [b].  If [progress] is
      specified, the given callback reports it (in this case the load
      happens via a
      {{:https://developer.mozilla.org/en-US/docs/Web/API/FileReader}
      [FileReader]} object). *)

  val stream : t -> Jv.t
  (** [stream b] is a
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Blob/stream}stream}
      to read the contents of [b]. *)

  val text : ?progress:progress -> t -> Jstr.t Fut.or_error
  (** [text b] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Blob/text}string}
      that results from UTF-8 decoding the contents of [b]. If [progress]
      is specified, the given callback reports it (in this case the load
      happens via a
      {{:https://developer.mozilla.org/en-US/docs/Web/API/FileReader}
      [FileReader]} object). *)

  val data_uri : ?progress:progress -> t -> Jstr.t Fut.or_error
  (** [data_uri b] is [b] as a data URI. If [progress] is specified,
      the given callback reports it. This function always goes through
      {{:https://developer.mozilla.org/en-US/docs/Web/API/FileReader}
      [FileReader]} object. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** File objects and reads.

    There are various ways to get {!File.t} values. On of them is to create
    an {!El.input} element of type [file] and use the
    {!El.Input.files} function. Another way is to use drag and
    drop events and get them via the {!Ev.Data_transfer} values. *)
module File : sig

  (** {1:files Files} *)

  type init
  (** The type for file initialisation objects. *)

  val init : ?blob_init:Blob.init -> ?last_modified_ms:int -> unit -> init
  (** [init ()] is a file initialisation object with
      the given
      {{:https://w3c.github.io/FileAPI/#ref-for-dfn-BlobPropertyBag%E2%91%A0}
      properties}. *)

  type t
  (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/File}
      [File]} objects. *)

  val of_blob : ?init:init -> Jstr.t -> Blob.t -> t
  (** [of_blob name b] is a file named [name] with data [b].

      {b Note.} Reading the
      {{:https://w3c.github.io/FileAPI/#file-constructor} constructor
      specificaton} it seems this will not look into [b] to define the
      {!Blob.type'} of the resulting file object's
      {{!as_blob}blob}. You should define it via the [init] object. *)

  val name : t -> Jstr.t
  (** [name f] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/File/name}filename}
      of [f]. *)

  val relative_path : t -> Jstr.t
  (** [relative_path] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/File/webkitRelativePath}[webkitRelativePath]}
      of [f]. *)

  val last_modified_ms : t -> int
  (** [last_modified_ms f] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/File/lastModified}
      last modified time} in milliseconds since the POSIX epoch. *)

  external as_blob : t -> Blob.t = "%identity"
  (** [as_blob f] is [f]'s {!Blob} interface. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** [base64] codec.

    As performed by {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/btoa}[btoa]} and
{{:https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/atob}[atob]} functions.

    {b Warning.} These functions are slightly broken API-wise. They
    are easy to use incorrectly and involve a lot of data copies to
    use them correctly. Use only for quick hacks. The detour via the
    {!Base64.type-data} type is provided to hopefully prevent people
    from shooting themselves in the foot. *)
module Base64 : sig

  (** {1:data Binary data} *)

  type data
  (** The type for representing binary data to codec. *)

  val data_utf_8_of_jstr : Jstr.t -> data
  (** [data_utf_8_of_jstr s] is the UTF-16 encoded JavaScript string
      [s] as UTF-8 binary data. This is to be used with {!encode}
      which results in a [base64] encoding of the UTF-8 representation
      of [s]. *)

  val data_utf_8_to_jstr : data -> (Jstr.t, Jv.Error.t) result
  (** [data_utf_8_to_jstr d] decodes the UTF-8 binary data [d] to an UTF-16
      encoded JavaScript string. *)

  val data_of_binary_jstr : Jstr.t -> data
  (** [data_of_binary_jstr d] is the binary data represented
      by the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/DOMString/Binary}
      JavaScript binary string} [d]. Note that this does not check that
      [d] is a binary string, {!encode} will error if that's not the case.
      Use {!Tarray.to_binary_jstr} to convert typed arrays to binary
      strings. *)

  val data_to_binary_jstr : data -> Jstr.t
  (** [data_to_jstr d] is a
      {{:https://developer.mozilla.org/en-US/docs/Web/API/DOMString/Binary}
      JavaScript binary string} from [d]. Use {!Tarray.of_binary_jstr} to
      convert binary strings to typed arrays. *)

  (** {1:codec Codec} *)

  val encode : data -> (Jstr.t, Jv.Error.t) result
  (** [encode d] encodes the binary data [d] to [base64]. This errors if
      [d] was constructed with {!data_of_binary_jstr} from an invalid
      {{:https://developer.mozilla.org/en-US/docs/Web/API/DOMString/Binary}
      JavaScript binary string}. *)

  val decode : Jstr.t -> (data, Jv.Error.t) result
  (** [decode s] decodes the [base64] encoded string [s] to
      a {{:https://developer.mozilla.org/en-US/docs/Web/API/DOMString/Binary}
      binary string}. Errors if [s] is not only made of US-ASCII characters or
      is not well formed Base64. *)
end

(** JSON codec.

    As codec by the
    {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON}JSON object}.

    {b Warning.} This interface will change in the future. *)
module Json : sig

  type t = Jv.t
  (** The type for JSON values.
      {b FIXME} have something more abstract. *)

  val encode : t -> Jstr.t
  (** [encode v] encodes [v] to JSON using
      {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify}JSON.stringify}.

      {b Warning.} Do not expect an [encode] on a {!Jv.repr} of an OCaml
      value to be decoded back by [decoded]. *)


  val decode : Jstr.t -> (t, Jv.Error.t) result
  (** [decode s] decodes the JSON text [s] into a JavaScript value using
      {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse}JSON.parse}. *)
end

(** URIs and URI parameters.

    {!Uri.t} values are
    {{:https://developer.mozilla.org/en-US/docs/Web/API/URL}URL}
    objects but we tweak the API to use
    {{:http://tools.ietf.org/html/rfc3986}RFC 3986} terminology and in
    contrast to the URL API we return component data without including
    separators like [':'], ['?']  and ['#'] in the results. *)
module Uri : sig

  (** {1:uris URIs} *)

  type t
  (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/URL}
      [URL]} objects. *)

  val v : ?base:Jstr.t -> Jstr.t -> t
  (** [v ?base s] is a URI from [s] relative to [base] (if specified).
      Raises in in case of error, use {!of_jstr} if you need to deal
      with user input. *)

  val scheme : t -> Jstr.t
  (** [scheme u] is the scheme of [u]. This is what the URL API calls
      the {{:https://developer.mozilla.org/en-US/docs/Web/API/URL/protocol}
      [protocol]} but without including the trailing [':']. *)

  val host : t -> Jstr.t
  (** [host u] is the host of [u]. This is not percent-decoded and
      what the URL API calls the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/URL/hostname}
      [hostname]}. *)

  val port : t -> int option
  (** [port u] is the port of [u], if any. Parsed from the URL API's
      {{:https://developer.mozilla.org/en-US/docs/Web/API/URL/port}port}. *)

  val path : t -> Jstr.t
  (** [path u] is the path of [u]. This is not percent-decoded and what the
      URL API calls
      {{:https://developer.mozilla.org/en-US/docs/Web/API/URL/pathname}
      [pathname]}. Use {!path_segments} for decoding the path.

      {b Note.} In hierarchical URI schemes like [http] this is ["/"]
      even if there is no path in [u]: no distinction is made between
      [http://example.org] and [http://example.org/]. *)

  val query : t -> Jstr.t
  (** [query u] is the query of [u]. This not percent-decoded and
      what the URL API calls the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/URL/search}
      [search]} but without including the leading ['?']. Use
      {!query_params} to decode key-value parameters. *)

  val fragment : t -> Jstr.t
  (** [fragment u] is fragment of [u]. This is not percent-decoded and
      what the URL API calls the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/URL/hash}[hash]}
      but without including the leading ['#']. Use {!fragment_params} to
      decode key-value parameters. *)

  val with_uri :
    ?scheme:Jstr.t -> ?host:Jstr.t -> ?port:int option -> ?path:Jstr.t ->
    ?query:Jstr.t -> ?fragment:Jstr.t -> t -> (t, Jv.Error.t) result
  (** [with_uri u] is [u] with the specified components updated. The components
      are assumed to be appropriately {{!encode_component}percent-encoded}.
      See also {!with_path_segments}, {!with_query_params} and
      {!with_fragment_params}. *)

  (** {1:path_segs Path segments} *)

  type path = Jstr.t list
  (** The type for absolute URI paths represented as {e non-empty}
      lists of {e percent-decoded} path segments. The empty list
      denotes the absence of a path.

      Path segments can be {!Jstr.empty}. The root path [/] is represented
      by the list [[Jstr.empty]] and [/a] by [[Jstr.v "a"]].

      {b Warning.} You should never concatenate these segments with a
      directory separator to get a file path because path segments may
      contain stray, percent-decoded, directory separators. *)

  val path_segments : t -> (path, Jv.Error.t) result
  (** [path_segments u] determines the segments of the {!val-path} of
      [u] and {{!decode_component}percent-decodes} them. This is the
      empty list if the path is empty. The root path is [[Jstr.empty]]. *)

  val with_path_segments : t -> path -> (t, Jv.Error.t) result
  (** [with_path_segments u segs] is [u] with a {!path} made by
      {{!encode_component}percent-encoding} the segments, prepending a
      ['/'] to each segment and concatenating the result.

      {b Note.} In hierarchical URI schemes like [http] an empty [segs]
      is mapped to the root path, see {!path}. *)

  (** {1:params Fragment or query parameters} *)

  (** URI fragment or query parameters.

      {!Params.t} values represent key-value parameters stored in
      strings as ["k0=v0&k1=v1..."]. They can be constructed from
      any {!Jstr.t}. In particular it means they can be used with an
      URI {!fragment} or {!query}. *)
  module Params : sig

    (** {1:params Parameters} *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams}
        [URLSearchParams]} objects. *)

    val is_empty : t -> bool
    (** [is_empty ps] is [true] if [ps] has no key value bindings. *)

    val mem : Jstr.t -> t -> bool
    (** [mem k ps] is [true] if key [k] is bound in [ps]. *)

    val find : Jstr.t -> t -> Jstr.t option
    (** [find k ps] is the value of the first binding of [k] in [ps]. *)

    val find_all : Jstr.t -> t -> Jstr.t list
    (** [find_all k ps] are the values of all bindings of [k] in [ps]. *)

    val fold : (Jstr.t -> Jstr.t -> 'a -> 'a) -> t -> 'a -> 'a
    (** [fold f ps acc] folds {e all} the key value bindings. *)

    (** {1:conver Converting} *)

    val of_obj : Jv.t -> t
    (** [of_obj o] uses the keys of object [o] to define URL parameters. *)

    val of_jstr : Jstr.t -> t
    (** [of_jstr s] URL decodes and parses parameters from [s]. *)

    val to_jstr : t -> Jstr.t
    (** [to_jstr ps] URL encodes the parameters [ps] to a string. *)

    val of_assoc : (Jstr.t * Jstr.t) list -> t
    (** [of_assoc assoc] are parameters for the assoc [assoc]. *)

    val to_assoc : t -> (Jstr.t * Jstr.t) list
    (** [to_assoc ps] is [ps] as an assoc list. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  val query_params : t -> Params.t
  (** [query_params u] is {!Params.of_jstr}[ (query u)]. *)

  val with_query_params : t -> Params.t -> t
  (** [with_query_params u ps] is [u] with a {!query} defined by parameters
      [ps]. *)

  val fragment_params : t -> Params.t
  (** [fragment_params u] is {!Params.of_jstr}[ (fragment u)]. *)

  val with_fragment_params : t -> Params.t -> t
  (** [with_fragment_params u ps] is [u] with a {!fragment} defined by
      parameters [ps]. *)

  (** {1:conv Converting} *)

  val of_jstr : ?base:Jstr.t -> Jstr.t -> (t, Jv.Error.t) result
  (** [of_jstr ~base s] is a URL from [s] relative to [base] (if
      specified). Note that if [s] is relative and [base] is
      unspecified the function errors. *)

  val to_jstr : t -> Jstr.t
  (** [to_jstr u] is [u] as a JavaScript string. The result is
      {{!encode}percent-encoded}. *)

  (** {1:encoding Percent encoding} *)

  val encode : Jstr.t -> (Jstr.t, Jv.Error.t) result
  (** [encode s] percent-encodes an UTF-8 representation
      of [s]. See
      {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURI}encodeURI}.

      {b Warning.} This encodes according to RFC2396 not according to RFC3986
      which reserves a few more characters. *)

  val decode : Jstr.t -> (Jstr.t, Jv.Error.t) result
  (** [decode s] percent-decodes a UTF-8 representation
      of [s]. See {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURI}decodeURI}.
  *)

  val encode_component : Jstr.t -> (Jstr.t, Jv.Error.t) result
  (** [encode s] percent-encodes a UTF-8 representation
      of [s]. See {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent}encodeURIComponent}. *)

  val decode_component : Jstr.t -> (Jstr.t, Jv.Error.t) result
  (** [decode s] percent-descodes a UTF-8 representation
      of [s]. See {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURIComponent}decodeURIComponent}. Note that
      this has the same effect as {!decode}. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** {1:dom DOM interaction} *)

(** DOM events. *)
module Ev : sig

  (** {1:types Event types} *)

  type 'a type'
  (** The type for events which can {{!as_type}pose} as values of type
      ['a]. See the {{!predefined_types}predefined} event types. *)

  (** Event types. *)
  module Type : sig
    type void
    (** A type for events that do not expose further data. *)

    type 'a t = 'a type'
    (** See {!type-type'}. *)

    external create : Jstr.t -> 'a type' = "%identity"
    (** [create n] is a new event type named [n]. Constrain the result
        to your event type. See the {{!Brr.Ev.predefined_types}
        predefined} types. *)

    external void : Jstr.t -> void t = "%identity"
    (** [void] is a new void event type. *)

    external name : 'a type' -> Jstr.t = "%identity"
    (** [name t] is the name of event type [t]. *)
  end

  type void = Type.void type'
  (** The type for events that do not expose further data. *)

  (** {1:events Events} *)

  type target
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/EventTarget}
      [EventTarget]} abiding objects. *)

  type init
  (** The type for event initialisation objects. *)

  val init : ?bubbles:bool -> ?cancelable:bool -> ?composed:bool -> unit -> init
  (** [init] is an event initialisation object with given
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Event/Event#Values}
      parameters}. *)

  type 'a t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Event}Event}
      objects which can {{!as_type}pose} as events of type ['a]. *)

  type 'a event
  (** See {!t}. *)

  val create : ?init:init -> 'a type' -> 'a t
  (** [create ?init t] is an event of type [t] initialised with [init]. *)

  external as_type : 'a t -> 'a = "%identity"
  (** [as_type e] specialises the event to its type. *)

  val type' : 'a t -> 'a type'
  (** [type' e] is the type of [e]. *)

  val target : 'a t -> target
  (** [target e] is the target on which [e] was originally dispatched. *)

  val current_target : 'a t -> target
  (** [current_target e] is the target currently handling [e]. See also
      {!val:target}. *)

  val composed_path : 'a t -> target list
  (** [composed_path e] are the targets on which listeners will be
      invoked. *)

  val event_phase : 'a t -> [ `None | `Capturing | `At_target | `Bubbling ]
  (** [event_phase e] is [e]'s event phase, see
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Event/eventPhase#Event_phase_constants}here}
      for details. This
      {{:https://w3c.github.io/uievents/#event-flow}picture} may
      help. *)

  val bubbles : 'a t -> bool
  (** [bubbles e] is [true] whether the event can bubble up through
      the DOM. *)

  val stop_propagation : 'a t -> unit
  (** [stop_propagation e] prevents the propagation of [e] in the DOM,
      remaining handlers of [e] on the {!current_target} are still
      invoked use {!stop_immediate_propagation} to stop these. The
      user agent's default action for [e] still occurs, use
      {!prevent_default} to prevent that. *)

  val stop_immediate_propagation : 'a t -> unit
  (** [stop_immediate_propagation e] is like {!stop_propagation} but it
      also prevents the invocation of other handlers for [e] that may
      be listening on the {!current_target}. *)

  val cancelable : 'a t -> bool
  (** [cancelable e] indicates whether [e] can be cancelled, that is
      whether {!prevent_default} will succeed. *)

  val prevent_default : 'a t -> unit
  (** [prevent_default e] prevents the user agent's default action for
      [e] to happen. This may have no effect if {!cancelable} is [false],
      see {!default_prevented}. *)

  val default_prevented : 'a t -> bool
  (** [default_prevented e] is [true] indicates whether a
      call to {!prevent_default} succeded. *)

  val composed : 'a t -> bool
  (** [composed e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Event/composed}[composed]} property of [e]. *)

  val is_trusted : 'a t -> bool
  (** [is_trusted e] is [true] if [e] was dispatched by the user agent
      and [false] otherwise. *)

  val timestamp_ms : 'a t -> float
  (** [timestamp_ms e] is the time in milleseconds since the POSIX
      epoch when the event was created. *)

  val dispatch : 'a t -> target -> bool
  (** [dispatch e t]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/dispatchEvent}dispatches}
      event [e] on target [t]. *)

  (** {1:listening Listening} *)

  type listen_opts
  (** The type for listening options. *)

  val listen_opts :
    ?capture:bool -> ?once:bool -> ?passive:bool -> unit -> listen_opts
  (** [listen_opts ()] are {{:https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener#Parameters}options} for {!listen}.
      {ul
      {- [capture] indicates if events are listened before being dispatched
         to descendents of the target in the DOM tree. Defaults to [false]. }
      {- [once] indicates at most a single event will be listened. If [true]
         the listener is automatically removed when invoked. Defaults to
         [false].}
      {- [passive] indicates the listener never calls {!prevent_default}
         on the event. If it does nothing will happen (except maybe
         a console warning). Defaults to [false].}} *)

  type listener
  (** The type for event listeners. See {!listen}. *)

  val listen :
    ?opts:listen_opts -> 'a type' -> ('a t -> unit) -> target -> listener
  (** [listen ~opts type' f t] is a listener listening for events of type
      [type'] on target [t] with function [f] and options [opts]
      (see {!val:listen_opts} for defaults). The listener can be used to
      {!unlisten}, if you don't need to, you can just `ignore` the result. *)

  val unlisten : listener -> unit
  (** [unlisten l] stops the listening done by [l]. *)

  val next : ?capture:bool -> 'a type' -> target -> 'a t Fut.t
  (** [next type' t] is a future that determines the next event of
      type [type'] on target [t]. For [capture] see {!val-listen_opts}. *)

  (** {1:objs Event subobjects} *)

  (** [DataTransfer] objects. *)
  module Data_transfer : sig

    (** The drop effect enum *)
    module Effect : sig
      type t = Jstr.t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/DataTransfer/effectAllowed#Values}drop effect} values. *)

      val none : Jstr.t
      val copy : Jstr.t
      val copy_link : Jstr.t
      val copy_move : Jstr.t
      val link : Jstr.t
      val link_move : Jstr.t
      val move : Jstr.t
      val all : Jstr.t
      val uninitialized : Jstr.t
    end

    (** [DataTransferItem] objects. *)
    module Item : sig

      (** Item kinds. *)
      module Kind : sig
        type t = Jstr.t
        val file : t
        val string : t
      end

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/DataTransferItem}[DataTransferItem]}
          objects. *)

      val kind : t -> Kind.t
      (** [kind i] is the kind of [i] *)

      val type' : t -> Jstr.t
      (** [type' i] is the MIME type of [i]. *)

      val get_file : t -> File.t option
      (** [get_file i] is item's the file's (if any). *)

      val get_jstr : t -> Jstr.t Fut.t
      (** [get_jstr i] is the item's text. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** [DataTransferItemList] objects. *)
    module Item_list : sig
      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/DataTransferItemList}[DataTransferItemList]}
          objects. *)

      val length : t -> int
      (** [length l] it the length of the list. *)

      val add_jstr : t -> type':Jstr.t -> Jstr.t -> Item.t option
      (** [add_jstr l type' s] adds [s] with MIME type [type']. [None] is
          returned in case of error, the corresponding data item otherwise. *)

      val add_file : t -> File.t -> Item.t option
      (** [add_file l f] adds file [s]. [None] is returned in case
          of error, the corresponding data item otherwise. *)

      val remove : t -> int -> unit
      (** [remove l i] removes the [i]th item from the list. *)

      val clear : t -> unit
      (** [clear l] removes all elements from the list. *)

      val item : t -> int -> Item.t
      (** [item l i] is the [i]th item in the list. *)

      val items : t -> Item.t list
      (** [items l] are the items of list [l]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** {1:data_transfers Data transfers} *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/DataTransfer}
        [DataTransfer]} objects. *)

    val drop_effect : t -> Effect.t
    (** [drop_effect d] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/DataTransfer/dropEffect}[dropEffect]} property. *)

    val set_drop_effect : t -> Effect.t -> unit
    (** [set_drop_effect d e] sets the {!drop_effect} property to [e].
        {b Note.} Only a subset of {!Effect.t} can be used. *)

    val effect_allowed : t -> Effect.t
    (** [effect_allowed d] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/DataTransfer/effectAllowed}[effectAllowed]} property. *)

    val set_effect_allowed : t -> Effect.t -> unit
    (** [set_effect_allowed d e] sets the {!effect_allowed} property to [e]. *)

    val items : t -> Item_list.t
    (** [items d] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/DataTransfer/items}[items]} property. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Clipboard events. *)
  module Clipboard : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Clipboard}
        [ClipboardEvent]} objects. *)

    val data : t -> Data_transfer.t option
    (** [data c] is the clipboard data for the event. *)
  end

  (** Composition events. *)
  module Composition : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/CompositionEvent}
        [CompositionEvent]} objects. *)

    val data : t -> Jstr.t
    (** [data c] is the data for the event. The
        {{:https://developer.mozilla.org/en-US/docs/Web/API/CompositionEvent/data#Value}semantics} depends on the composition event. *)
  end

  (** Error events. *)
  module Error : sig

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ErrorEvent}
        [ErrorEvent]} objects. *)

    val message : t -> Jstr.t
    (** [message e] is the error {{:https://developer.mozilla.org/en-US/docs/Web/API/ErrorEvent#Properties}message}. *)

    val filename : t -> Jstr.t
    (** [filename e] is the script {{:https://developer.mozilla.org/en-US/docs/Web/API/ErrorEvent#Properties}file name}. *)

    val lineno : t -> int
    (** [lineno e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ErrorEvent#Properties}line number}. *)

    val colno : t -> int
    (** [colno e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ErrorEvent#Properties}column number}. *)

    val error : t -> Jv.t
    (** [error e] is the error object. *)
  end

  (** Extendable events. *)
  module Extendable : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ExtendableEvent}
        [ExtendableEvent]} objects. *)

    val wait_until : t -> 'a Fut.or_error -> unit
    (** [wait_until e] {{:https://developer.mozilla.org/en-US/docs/Web/API/ExtendableEvent/waitUntil}indicates} to the event dispatcher that work is ongoing. *)
  end

  (** Focus events. *)
  module Focus : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FocusEvent}
        [FocusEvent]} objects. *)

    val related_target : t -> target option
    (** [related_target e] is a secondary target related to the focus event. *)
  end

  (** Hash change events *)
  module Hash_change : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HashChangeEvent}
        [HashChangeEvent]} objects. *)

    val old_url : t -> Jstr.t
    (** [old_url e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HashChangeEvent/oldURL}old URI}. *)

    val new_url : t -> Jstr.t
    (** [new_url e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HashChangeEvent/newURL}new URI}. *)
  end

  (** Input events. *)
  module Input : sig

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/InputEvent}
        [InputEvent]} objects. *)

    val data : t -> Jstr.t
    (** [data i] are the inserted characters. This may be empty
        e.g. if characters are being deleted. *)

    val data_transfer : t -> Data_transfer.t option
    (** [data_transfer i] has {!val-data} in a richer form. *)

    val input_type : t -> Jstr.t
    (** [input_type i] is a high-level description the input
        operation. See {{:https://rawgit.com/w3c/input-events/v1/index.html#interface-InputEvent-Attributes}here} for actual values. *)

    val is_composing : t -> bool
    (** [is_composing i] is [true] if the event occurs between
        {!compositionstart} and {!compositionend} events. *)
  end

    (** Keyboard events. *)
  module Keyboard : sig

    (** Key locations. *)
    module Location : sig
      type t = int
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent#Keyboard_locations}key location} values. *)

      val standard : t
      val left : t
      val right : t
      val numpad : t
    end

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent}
        KeyboardEvent} objects. *)

    val key : t -> Jstr.t
    (** [key k] is the {{:https://www.w3.org/TR/uievents-key/#key-attribute-value}key attribute value} of [k]. {{:https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key}This value} is affected by the current
        keyboard layout and modifier keys.
    *)

    val code : t -> Jstr.t
    (** [code k] is a string that identifies the physical key of the
        event.
        {{:https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/code}
        This value} is affected by the current keyboard
        layout or modifier state. *)

    val location : t -> Location.t
    (** [location k] is the key location of [k]. *)

    val repeat : t -> bool
    (** [repeat k] is [true] if the key has been pressed in a sustained
        manner. *)

    val is_composing : t -> bool
    (** [is_composing k] is [true] if the event occurs between
        {!compositionstart} and {!compositionend} events. *)

    val alt_key : t -> bool
    (** [alt_key k] is [true] if [Alt] modifier is active. *)

    val ctrl_key : t -> bool
    (** [ctrl_key k] is [true] if [Control] modifier is active. *)

    val shift_key : t -> bool
    (** [shift_key k] is [true] if [Shift] modifier is active. *)

    val meta_key : t -> bool
    (** [meta_key k] is [true] if [Meta] modifier is active. *)

    val get_modifier_state : t -> Jstr.t -> bool
    (** [get_modifier_state m key] is [true] if [key] is active.
        See {{:https://www.w3.org/TR/uievents-key/#keys-modifier}here} for
        [key] values. *)
  end

  (** Mouse events. *)
  module Mouse : sig
    type t
    (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent}
      [MouseEvent]} objects. *)

    val related_target : t -> target option
    (** [related_target e] is the target the pointer is entering (if any). *)

    (** {1:pos Position} *)

    val offset_x : t -> float
    (** [offset_x m] is the horizontal coordinate in target space. *)

    val offset_y : t -> float
    (** [offset_y m] is the vertical coordinate in target space. *)

    val client_x : t -> float
    (** [client_x m] is the horizontal coordinate in window viewport space. *)

    val client_y : t -> float
    (** [client_y m] is the vertical coordinate in window viewport space. *)

    val page_x : t -> float
    (** [page_x m] is the horizontal coordinate in document space. *)

    val page_y : t -> float
    (** [page_y m] is the vertical coordinate in document space. *)

    val screen_x : t -> float
    (** [screen_x m] is the horizontal coordinate in screen space. *)

    val screen_y : t -> float
    (** [screen_y m] is the vertical coordinate in screen space. *)

    val movement_x : t -> float
    (** [movement_x m] is the horizontal coordinate movement in screen space.
        This is {!screen_x} minus the previous event's one. *)

    val movement_y : t -> float
    (** [movement_x m] is the vertical coordinate movement in screen space.
        This is {!screen_y} minus the previous event's one. *)

    (** {1:button Buttons} *)

    val button : t -> int
    (** [button m]
        {{:https://w3c.github.io/uievents/#dom-mouseevent-button}indicates}
        the button for mouse button events. *)

    val buttons : t -> int
    (** [buttons m]
        {{:https://w3c.github.io/uievents/#dom-mouseevent-buttons}indicates}
        the current mouse buttons state. *)

    (** {1:key Keyboard} *)

    val alt_key : t -> bool
    (** [alt_key m] is [true] if [Alt] modifier is active. *)

    val ctrl_key : t -> bool
    (** [ctrl_key m] is [true] if [Control] modifier is active. *)

    val shift_key : t -> bool
    (** [shift_key m] is [true] if [Shift] modifier is active. *)

    val meta_key : t -> bool
    (** [meta_key m] is [true] if [Meta] modifier is active. *)

    val get_modifier_state : t -> Jstr.t -> bool
    (** [get_modifier_state m key] is [true] if [key] is active.
        See {{:https://www.w3.org/TR/uievents-key/#keys-modifier}here} for
        [key] values. *)
  end

  (** Drag events. *)
  module Drag : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/DragEvent}
        [DragEvent]} objects. *)

    external as_mouse : t -> Mouse.t = "%identity"
    (** [as_mouse d] is [d] as a mouse event. *)

    val data_transfer : t -> Data_transfer.t option
    (** [data_transfer d] is the data transfer of the drag event. *)
  end

    (** Pointer events *)
  module Pointer : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent}
        [PointerEvent]} objects. *)

    external as_mouse : t -> Mouse.t = "%identity"
    (** [as_mouse d] is [d] as a mouse event. *)

    val id : t -> int
    (** [id p] is the {{:https://w3c.github.io/pointerevents/#dom-pointerevent-pointerid}identifier} of the pointer causing the event
        ([id]s can get recycled but they are unique among active pointers). *)

    val width : t -> float
    (** [width p] is the {{:https://w3c.github.io/pointerevents/#dom-pointerevent-width}width} in CSS pixels of the contact geometry of
        the pointer. *)

    val height : t -> float
    (** [height p] is the {{:https://w3c.github.io/pointerevents/#dom-pointerevent-height}height} in CSS pixels of the contact geometry
        of the pointer. *)

    val pressure : t -> float
    (** [pressure p] is the normalized {{:https://w3c.github.io/pointerevents/#dom-pointerevent-pressure}pressure} of the pointer in the range
        [0.] to [1.]. For things like mices this is [0.5] when
        buttons are depressed and [0.] otherwise. All {!pointerup} events
        have that to [0.]. *)

    val tangential_pressure : t -> float
    (** [tanganital_pressure p] is the normalized {{:https://w3c.github.io/pointerevents/#dom-pointerevent-tangentialpressure}tangential pressure}
        of the pointer in the range [-1.] to [1.] with [0.] the neutral
        position of the control. If the hardware has no support this must
        be [0.]. *)

    val tilt_x : t -> int
    (** [tilt_x p] is the {{:https://w3c.github.io/pointerevents/#dom-pointerevent-tiltx}plane angle} in degree in the range [-90] to [90]
        between the Y-Z plane and the plane containing the transducer
        axis and the Y axis. Positive tilt is to the right and [0]
        if unsupported. *)

    val tilt_y : t -> int
    (** [tilt_y p] is the {{:https://w3c.github.io/pointerevents/#dom-pointerevent-tilty}plane angle} in degree in the range [-90] to
        [90] between the X-Z plane and the plane containing the
        transducer axis and the X axis. Positive tilt is towards the
        user and [0] if unsupported. *)

    val twist : t -> int
    (** [twist p] is the {{:https://w3c.github.io/pointerevents/#dom-pointerevent-twist}rotation} in degree in the range [0;359] of the
        transducer around its own major axis. If unsupported this
        must be [0]. *)

    val altitude_angle : t -> float
    (** [altitude_angle p] is the {{:https://w3c.github.io/pointerevents/#dom-pointerevent-altitudeangle}altitude} in radians of the transducer
        in the range 0. to [π/2] where [0] is parallel to the surface
        X-Y plane and [π/2] is perpendicular to the surface. If unsupported
        this must be [π/2]. *)

    val azimuth_angle : t -> float
    (** [azimuth_angle p] is the {{:https://w3c.github.io/pointerevents/#dom-pointerevent-azimuthangle}azimuth angle} in radians in the range
        0. to [2π] where [0] represents a transducer whose cap
        is pointing in the direction of increasing X values on the XY-plane.
        If unsupported must be [0]. *)

    val type' : t -> Jstr.t
    (** [type' p] is the {{:https://w3c.github.io/pointerevents/#dom-pointerevent-pointertype}pointer type}. *)

    val is_primary : t -> bool
    (** [is_primary p] is [true] if the pointer represents the
        {{:https://w3c.github.io/pointerevents/#dfn-primary-pointer}primary
        pointer}. *)

    val get_coalesced_events : t -> t event list
   (** [get_coalesced_events p] is the list of events that
       were {{:https://w3c.github.io/pointerevents/#dfn-coalesced-event-list}coalesced} into [p]. *)

    val get_predicted_events : t -> t event list
    (** [get_predicted_events p] is the list of
        {{:https://w3c.github.io/pointerevents/#dfn-predicted-event-list}predicted events} for [p]. *)
  end

  (** Wheel events. *)
  module Wheel : sig

    (** Delta unit specification. *)
    module Delta_mode : sig
      type t = int
      (** The type delta mode {{:https://developer.mozilla.org/en-US/docs/Web/API/WheelEvent/deltaMode}values}. *)

      val pixel : int
      val line : int
      val page : int
    end

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/WheelEvent}
        WheelEvent} objects. *)

    external as_mouse : t -> Mouse.t = "%identity"
    (** [as_mouse w] is [w] as a mouse event. *)

    val delta_x : t -> float
    (** [delta_x w] is the amount to be scrolled on the x-axis. *)

    val delta_y : t -> float
    (** [delta_x w] is the amount to be scrolled on the y-axis. *)

    val delta_z : t -> float
    (** [delta_z w] is the amount to be scrolled on the z-axis. *)

    val delta_mode : t -> Delta_mode.t
    (** [delta_mode w] is the unit of measurement for {!delta_x},
        {!delta_y} and {!delta_z}. *)
  end

  (** {1:predefined_types Predefined types}

      Due to type dependencies some events are defined in their dedicated
      modules:
      {ul
      {- {{!Window.History.Ev}History events}}
      {- {{!Brr_io.Fetch.Ev}Fetch events}}
      {- {{!Brr_io.Form.Ev}Form events}}
      {- {{!Brr_io.Media.Devices.Ev}Media device events}}
      {- {{!Brr_io.Media.Recorder.Ev}Media recorder events}}
      {- {{!Brr_io.Media.Stream.Ev}Media stream events}}
      {- {{!Brr_io.Media.Track.Ev}Media track events}}
      {- {{!Brr_io.Message.Ev}Message events}}
      {- {{!Brr_io.Notification.Ev}Notification events}}
      {- {{!Brr_io.Storage.Ev}Storage events}}}

      Events that have no special type dependencies are defined here,
      in alphabetic order. *)

  val abort : void
  (** [abort] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/abort_event}[abort]} events. *)

  val activate : Extendable.t type'
  (** [activate] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerGlobalScope/activate_event}[activate]} event. *)

  val auxclick : Mouse.t type'
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/auxclick_event}[auxclick]} events. *)

  val beforeinput : Input.t type'
   (** [beforeinput] is the
       {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/beforeinput_event}[beforeinput]} event. *)

  val beforeunload : void
 (** [beforeunload] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Widow/beforunload_event}[beforeunload]} event. *)

  val blur : Focus.t type'
  (** [blur] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/blur_event}[blur]} event. *)

  val canplay : void
  (** [canplay] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/canplay_event}[canplay]} events *)

  val canplaythrough : void
  (** [canplaythrough] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/canplaythrough_event}[canplaythrough]} events *)

  val change : void
  (** [change] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/change_event}[change]} event. *)

  val click : Mouse.t type'
  (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/click_event}[click]} events. *)

  val clipboardchange : Clipboard.t type'
  (** [change] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/clipboardchange_event}[clipboardchange]} event. *)

  val close : void
  (** [close] is the type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/close_event}[close]} events. *)

  val compositionend : Composition.t type'
  (** [compositionstend] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/compositionend_event}[compositionend]} event. *)

  val compositionstart : Composition.t type'
  (** [compositionstart] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/compositionstart_event}[compositionstart]} event. *)

  val compositionudpate : Composition.t type'
  (** [compositionstupdate] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/compositionend_event}[compositionupdate]} event. *)

  val controllerchange : void
  (** [controllerchange] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerContainer/oncontrollerchange}[controllerchange]} event. *)

  val copy : Clipboard.t type'
  (** [copy] is the
      {{:hccttps://developer.mozilla.org/en-US/docs/Web/API/Element/copy_event}
      [copy]} event. *)

  val cut : Clipboard.t type'
  (** [cut] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/cut_event}
      [cut]} event. *)

  val dblclick : Mouse.t type'
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/dblclick_event}[dblclick]} events. *)

  val dom_content_loaded : void
  (** [dom_content_loaded] is the type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/DOMContentLoaded_event}[DOMContentLoaded_event]} events. *)

  val drag : Drag.t type'
  (** [drag] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/drag_event}[drag]} event. *)

  val dragend : Drag.t type'
  (** [dragend] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/dragend_event}[dragend]} event. *)

  val dragenter : Drag.t type'
  (** [dragenter] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/dragenter_event}[dragenter]} event. *)

  val dragexit : Drag.t type'
  (** [dragexit] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/dragexit_event}[dragexit]} event. *)

  val dragleave : Drag.t type'
  (** [dragleave] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/dragleave_event}[dragleave]} event. *)

  val dragover : Drag.t type'
  (** [dragover] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/dragover_event}[dragover]} event. *)

  val dragstart : Drag.t type'
  (** [dragstart] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/dragstart_event}[dragstart]} event. *)

  val drop : Drag.t type'
  (** [drop] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/drop_event}[drop]} event. *)

  val durationchange : void
  (** [durationchange] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/durationchange_event}[durationchange]} events *)

  val emptied : void
  (** [emptied] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/emptied_event}[emptied]} events *)

  val ended : void
  (** [ended] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/ended_event}[ended]} events *)

  val error : Error.t type'
  (** [error] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/error_event}[error]} events. *)

  val focus : Focus.t type'
  (** [focus] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/focus_event}focus} event. *)

  val focusin : Focus.t type'
  (** [focusin] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/focusin_event}focusin} event. *)

  val focusout : Focus.t type'
  (** [focusout] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/focusout_event}focusout} event. *)

  val fullscreenchange : void
  (** [fullscreenchange] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/fullscreenchange_event}[fullscreenchange]} event. *)

  val fullscreenerror : void
  (** [fullscreenerror] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/fullscreenerror_event}[fullscreenerror]} event. *)

  val gotpointercapture : Pointer.t type'
  (** [gotpointercaputer] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/gotpointercapture_event}[gotpointercapture]} event. *)

  val hashchange : Hash_change.t type'
  (** [hashchange] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/hashchange_event}[hashchange]} events *)

  val input : Input.t type'
  (** [input] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/input_event}[input]} event. *)

  val install : Extendable.t type'
  (** [install] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerGlobalScope/install_event}[install]} event. *)

  val keydown : Keyboard.t type'
  (** [keydown] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/keydown_event}[keydown]} event *)

  val keyup : Keyboard.t type'
  (** [keyup] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/keyup_event}[keyup]} event *)

  val languagechange : void
  (** [languagechange] is the type type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/languagechange_event}[languagechange]} events. *)

  val load : void
  (** [load] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/load_event}[load]} events. *)

  val loadeddata : void
  (** [loadeddata] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/loadeddata_event}[loadeddata]} events *)

  val loadedmetadata : void
  (** [loadedmetadata] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/loadedmetadata_event}[loadedmetadata]} events *)

  val loadstart : void
  (** [loadstart] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/loadstart_event}[loadstart]} events *)

  val lostpointercapture : Pointer.t type'
  (** [lostpointercapture] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/lostpointercapture_event}[lostpointercaptpure]} event. *)

  val mousedown : Mouse.t type'
  (** [mousedown] is the type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/mousedown_event}[mousedown]} events. *)

  val mouseenter : Mouse.t type'
  (** [mouseenter] is the type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/mouseenter_event}[mouseenter]} events. *)

  val mouseleave : Mouse.t type'
  (** [mouseleave] is the type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/mouseleave_event}[mouseleave]} events. *)

  val mousemove : Mouse.t type'
  (** [mousemove] is the type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/mousemove_evenwt}[mousemove]} events. *)

  val mouseout : Mouse.t type'
  (** [mouseout] is the type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/mouseout_event}[mouseout]} events. *)

  val mouseover : Mouse.t type'
  (** [mouseover] is the type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/mouseover_event}[mouseover]} events. *)

  val mouseup : Mouse.t type'
  (** [mouseup] is the type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/mouseup_event}[mouseup]} events. *)

  val open' : void
  (** [open'] is the type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/open_event}
      [open]} events. *)

  val paste : Clipboard.t type'
  (** [paste] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/paste_event}
      [paste]} event. *)

  val pause : void
  (** [pause] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/pause_event}[pause]} events *)

  val play : void
  (** [play] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/play_event}[play]} events *)

  val playing : void
  (** [playing] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/playing_event}[playing]} events *)

  val pointercancel : Pointer.t type'
  (** [pointercancel] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/pointercancel_event}[pointercancel]} event. *)

  val pointerdown : Pointer.t type'
  (** [pointerdown] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/pointerdown_event}[pointerdown]} event. *)

  val pointerenter : Pointer.t type'
  (** [pointerneter] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/pointerenter_event}[pointerenter]} event. *)

  val pointerleave : Pointer.t type'
  (** [pointerleave] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/pointerleave_event}[pointerleave]} event. *)

  val pointerlockchange : void
  (** [pointerlockchange] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/pointerlockchange_event}[pointerlockchange]} event. *)

  val pointerlockerror : void
  (** [pointerlockerror] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/pointerlockchange_event}[pointerlockerror]} event. *)

  val pointermove : Pointer.t type'
  (** [pointemove] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/pointermove_event}[pointermove]} event. *)

  val pointerout : Pointer.t type'
  (** [pointerout] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/pointerout_event}[pointerout]} event. *)

  val pointerover : Pointer.t type'
  (** [pointerover] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/pointerover_event}[pointerover]} event. *)

  val pointerrawupdate : Pointer.t type'
  (** [pointerrawupdate] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/pointerrawupdate_event}[pointerrawupdate]} event. *)

  val pointerup : Pointer.t type'
  (** [pointerup] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/pointerup_event}[pointerup]} event. *)

  val progress : void
  (** [progress] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/progress_event}[progress]} events *)

  val ratechange : void
  (** [ratechange] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/ratechange_event}[ratechange]} events *)

  val reset : void
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/reset_event}[reset]} events. *)

  val resize : void
  (** [resize] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/resize_event}[resize]} event. *)

  val scroll : void
  (** [scroll] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/scroll_event}[scroll]} event. *)

  val seeked : void
  (** [seeked] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/seeked_event}[seeked]} events *)

  val seeking : void
  (** [seeking] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/seeking_event}[seeking]} events *)

  val select : void
  (** [select] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/select_event}[select]} events. *)

  val statechange : void
  (** [statechange] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/RTCIceTransport/statechange_event}[statechange]} events. *)

  val stalled : void
  (** [stalled] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/stalled_event}[stalled]} events *)

  val suspend : void
  (** [suspend] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/suspend_event}[suspend]} events *)

  val timeupdate : void
  (** [timeupdate] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/timeupdate_event}[timeupdate]} events *)

  val unload : void
  (** [unload] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/unload_event}[unload]} events. *)

  val updatefound : void
  (** [updatefound] is the type for [updatefound] events. *)

  val visibilitychange : void
  (** [visibilitychange] is the type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/visibilitychange_event}[visibilitychange]} events. *)

  val volumechange : void
  (** [volumechange] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/volumechange_event}[volumechange]} events *)

  val waiting : void
  (** [waiting] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/waiting_event}[waiting]} events *)

  val wheel : Wheel.t type'
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/wheel_event}[wheel]} events. *)

  (**/**)
  external target_to_jv : target -> Jv.t = "%identity"
  external target_of_jv : Jv.t -> target = "%identity"
  external to_jv : 'a t -> Jv.t = "%identity"
  external of_jv : Jv.t -> 'a t = "%identity"
  (**/**)
end

(** DOM element attributes. *)
module At : sig

  (** {1:atts Attributes} *)

  type name = Jstr.t
  (** The type for attribute names. *)

  type t
  (** The type for attributes. *)

  val v : name -> Jstr.t -> t
  (** [v n value] is an attribute named [n] with value [value]. *)

  val void : t
  (** [void] is an attribute that doesn't exist. It is ignored by
      functions like {!El.v}. This is [v Jstr.empty Jstr.empty]. *)

  val is_void : t -> bool
  (** [is_void a] is [true] iff [a] is {!void}. *)

  val true' : name -> t
  (** [true' n] is [v n Jstr.empty]. This sets the
      {{:https://html.spec.whatwg.org/multipage/common-microsyntaxes.html#boolean-attributes}boolean attribute}
      [n] to true. The attribute must be omitted to be false. *)

  val int : name -> int -> t
  (** [int n i] is [v n (Jstr.of_int i)]. *)

  val float : name -> float -> t
  (** [float n f] is [v n (Jstr.of_float f)]. *)

  val if' : bool -> t -> t
  (** [if' b a] is [a] if [b] is [true] and {!void} otherwise. *)

  val if_some : t option -> t
  (** [if_some o] is [a] if [o] is [Some a] and {!void} if [o] is [None]. *)

  val to_pair : t -> Jstr.t * Jstr.t
  (** [to_pair at] is [(n,v)] the name and value of the attribute. *)

  val add_if : bool -> t -> t list -> t list
  [@@ocaml.deprecated "use Brr.At.if' instead."]
  (** [add_if c att atts] is [att :: atts] if [c] is [true] and [atts]
        otherwise. *)

  val add_if_some : name -> Jstr.t option -> t list -> t list
  [@@ocaml.deprecated "use Brr.At.if_some instead."]
  (** [add_if_some n o atts] is [(v n value) :: atts] if [o] is [Some
      value] and [atts] otherwise. *)

  (** {1:names_cons Attribute names and constructors}

      See the
      {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes}MDN
      HTML attribute reference}.

      {b Convention.} Whenever an attribute name conflicts with
      an OCaml keyword we prime it, see for example {!class'}. *)

  (** Attribute names. *)
  module Name : sig
    val accesskey : name
    val action : name
    val autocomplete : name
    val autofocus : name
    val charset : name
    val checked : name
    val class' : name
    val cols : name
    val content : name
    val contenteditable : name
    val defer : name
    val dir : name
    val disabled : name
    val download : name
    val draggable : name
    val for' : name
    val height : name
    val hidden : name
    val href : name
    val id : name
    val lang : name
    val list : name
    val media : name
    val method' : name
    val name : name
    val placeholder : name
    val rel : name
    val required : name
    val rows : name
    val selected : name
    val spellcheck : name
    val src : name
    val style : name
    val tabindex : name
    val title : name
    val type' : name
    val value : name
    val width : name
    val wrap : name
  end

  type 'a cons = 'a -> t
  (** The type for attribute constructors with value of type ['a]. *)

  val accesskey : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/accesskey}accesskey} *)

  val action : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#attr-action}action} *)

  val autocomplete : Jstr.t cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete}autocomplete} *)

  val autofocus : t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/autofocus}autofocus} *)

  val charset : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes}
      charset} *)

  val checked : t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input#checked}checked} *)

  val class' : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/class}class} *)

  val cols : int cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/textarea#attr-cols}cols} *)

  val content : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta#attr-content}content} *)

  val contenteditable : bool cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/contenteditable}contenteditable} *)

  val defer : t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script#attr-defer}defer} *)

  val dir : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/dir}dir} *)

  val disabled : t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/disabled}
      disabled} *)

  val download : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a#download}
      download} *)

  val draggable : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/draggable}draggable}
  *)

  val for' : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/for}
      for'} *)

  val height : int cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes}height} *)

  val hidden : t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/hidden}hidden} *)

  val href : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes}href} *)

  val id : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/id}
      id} *)

  val lang : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/lang}lang} *)

  val list : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input#attr-list}list} *)

  val media : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes}media} *)

  val method' : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#attr-method}method}. *)

  val name : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes}name} *)

  val placeholder : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes}
      placeholder} *)

  val rel : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel}
      rel} *)

  val required : t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/required}
      required} *)

  val rows : int cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/textarea#attr-rows}rows} *)

  val selected : t
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/option#attr-selected}selected} *)

  val spellcheck : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/spellcheck}spellcheck} *)

  val src : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes}src} *)

  val style : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/style}style} *)

  val tabindex : int cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/tabindex}tabindex} *)

  val title : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/title}title} *)

  val type' : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes}
      type} *)

  val value : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes}value} *)

  val wrap : Jstr.t cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/textarea#attr-wrap}wrap} *)

  val width : int cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes}
      width} *)
end

(** DOM elements.

    The type {!El.t} technically represents DOM Node objects.
    However most of DOM processing happens on elements. So
    we make it as if {!El.t} values were just elements and most of the
    functions of this module will fail on text nodes. Except on
    {!El.val-children} where you may see them you'll likely never run into
    problems. The {!El.is_txt} function can be used to check for
    textiness. *)
module El : sig

  type document
  (** See {!Brr.Document.t} this is a forward declaration. *)

  type window
  (** See {!Brr.Window.t} this is a forward declaration. *)

  type tag_name = Jstr.t
  (** The type for element tag names. *)

  type t
  (** The type for elements. Technically this is a DOM
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Node}[Node]}
      object. But we focus on DOM manipulation via elements, not the
      various kind of nodes that may exist. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)

  type el = t
  (** See {!t}. *)

  val v : ?ns:[`HTML | `SVG | `MathML] -> ?d:document -> ?at:At.t list -> tag_name -> t list -> t
  (** [v ?d ?at name cs] is an element [name] with attribute [at]
      (defaults to [[]]) and children [cs]. If [at] specifies an
      attribute more than once, the last one takes over with the
      exception of {!At.class'} and {!At.style} whose occurences
      accumulate to define the final value. [d] is the document on which the
      element is defined it defaults {!Brr.G.document}. *)

  val txt : ?d:document -> Jstr.t -> t
  (** [txt s] is the text [s]. [d] is the document on which the element is
      defined it defaults {!Brr.G.document}. {b WARNING} This is not
      strictly speaking an element most function of this
      module will error with this value. *)

  val txt' : ?d:document -> string -> t
  (** [txt' s] is [txt (Jstr.v s)]. *)

  val sp : ?d:document -> unit -> t
  (** [sp ()] is [El.txt Jstr.sp] *)

  val nbsp : ?d:document -> unit -> t
  (** [nbsp ()] is [El.txt' "\u{00A0}"]. *)

  val is_txt : t -> bool
  (** [is_txt e] is [true] iff [e] is a text node. Note
      that in this cases many of the function below fail. *)

  val is_el : t -> bool
  (** [is_el e] is [true] iff [e] is an element node. *)

  val is_content_editable : t -> bool
  (** [is_content_editable e] is [true] iff the content of [e] is editable (see
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/isContentEditable}the
      relevant doc}). *)

  val tag_name : t -> tag_name
  (** [name e] is the tag name of element [e] lowercased. For {!is_txt}
      nodes this returns ["#text"]. *)

  val has_tag_name : tag_name -> t -> bool
  (** [has_tag_name n e] is [Jstr.equal n (name e)]. *)

  val txt_text : t -> Jstr.t
  (** [txt_text e] is the text of [e] if [e] is a {{!is_txt}text node}
      and the empty string otherwise. *)

  val document : t -> document
  (** [document e] is the document of [e]. *)

  external as_target : t -> Ev.target = "%identity"
  (** [as_target d] is the document as an event target. *)

  (** {1:el_lookups Element lookups}

      See also {{!Document.el_lookups}document element lookups}. *)

  val find_by_class : ?root:t -> Jstr.t -> t list
  (** [els_by_class ~root c] are the elements with class [c] that
      are descendents of [root] (defaults to {!Document.root}). *)

  val find_by_tag_name : ?root:t -> Jstr.t -> t list
  (** [find_by_tag_name ~root n] are the elements with tag name [t] that
      are descendents of [root] (defaults to {!Document.root}). *)

  val find_first_by_selector : ?root:t -> Jstr.t -> t option
  (** [find_first_by_selector ~root sel] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector}first element selected} by the CSS selector [sel] that is descendent
      of [root] (defaults to {!Document.root}). *)

  val fold_find_by_selector : ?root:t -> (t -> 'a -> 'a) -> Jstr.t -> 'a -> 'a
  (** [fold_find_by_selector ~root f sel acc] folds [f] over the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelectorAll}elements selected} by the CSS selector [sel] that are descendent of [root]
      (defaults to {!Document.root}). *)

  (** {1:tree Parent, children and siblings} *)

  val parent : t -> t option
  (** [parent e] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Node/parentNode}
      parent} {e element} of [e] (if any). *)

  val children : ?only_els:bool -> t -> t list
  (** [children e] are [e]'s children. {b Warning}, unless [only_els]
      is [true] (defaults to [false]) not all returned elements will
      satisfy {!is_el} here. *)

  val contains : t -> child:t -> bool
  (** [contains p ~child] indicates whether a node is a descendant of a given
      node, that is the node itself, one of its direct children, one of the
      children's direct children, and so on.

      It uses the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Node/contains}contains}
      method of the parent.  *)

  val set_children : t -> t list -> unit
  (** [set_children e l] sets the children of [e] to [l]. *)

  val prepend_children : t -> t list -> unit
  (** [prepend e l] prepends [l] to [e]'s children. *)

  val append_children : t -> t list -> unit
  (** [append_children e l] appends [l] to [e]'s children. *)

  val previous_sibling : t -> t option
  (** [previous_sibling e] is [e]'s previous sibling element (if any). *)

  val next_sibling : t -> t option
  (** [next_sibling e] is [e]'s next sibling element (if any). *)

  val insert_siblings : [ `Before | `After | `Replace ] -> t -> t list -> unit
  (** [insert_siblings loc e l] inserts [l] before, after or instead of
      element [e] according to [loc]. *)

  val remove : t -> unit
  (** [remove e] removes [e] from the document. *)

  (** {1:ats_and_props Attributes and properties} *)

  val at : At.name -> t -> Jstr.t option
  (** [at a e] is the attribute [a] of [e] (if any). *)

  val set_at : ?ns:[`HTML | `SVG | `MathML] -> At.name -> Jstr.t option -> t -> unit
  (** [set_at a v e] sets the attribute [a] of [e] to [v]. If [v]
      is [None] the attribute is removed. If [a] is empty, this has not
      effect. *)

  (** Some attributes are reflected as JavaScript properties in
      elements see
      {{:https://html.spec.whatwg.org/multipage/common-dom-interfaces.html#reflecting-content-attributes-in-idl-attributes}here}
      for details.  The following gives a quick way of accessing these
      properties for elements whose interface which, unlike {!Brr_canvas.Canvas}
      and {!Brr_io.Media.El}, are not necessarily bound by Brr for the time
      being (or will never be). *)

  (** Element properties. *)
  module Prop : sig

    type 'a t
    (** The type for element properties of type ['a]. *)

    val bool : Jstr.t -> bool t
    (** [bool n] is a property named [n] accessed as a [bool] and
        returning [false] on undefined. *)

    val int : Jstr.t -> int t
    (** [int n] is a property named [n] accessed as an [int] and
        returning [0] on undefined. *)

    val float : Jstr.t -> float t
    (** [float n] is a property named [n] accessed as a [float] and
        returning [0.] on undefined. *)

    val jstr : Jstr.t -> Jstr.t t
    (** [jstr n] is the property named [n] accessed as a {!Jstr.t}
        and returning {!Jstr.empty} on undefined. *)

    (** {1:predef Predefined properties} *)

    val checked : bool t
    val height : int t
    val id : Jstr.t t
    val name : Jstr.t t
    val title : Jstr.t t
    val value : Jstr.t t
    val width : int t
  end

  val prop : 'a Prop.t -> t -> 'a
  (** [prop p e] is the property [p] of [e] if defined and [false],
      [0], [0.] or {!Jstr.empty} as applicable if undefined. *)

  val set_prop : 'a Prop.t -> 'a -> t -> unit
  (** [set_prop p v o] sets property [p] of [e] to [v]. *)

  (** {1:class Classes} *)

  val class' : Jstr.t -> t -> bool
  (** [class' c e] is the membership of [e] to class [c]. *)

  val set_class : Jstr.t -> bool -> t -> unit
  (** [set_class c b e] sets the membership of [e] to class [c] to [b]. *)

  (** {1:style Style} *)

  (** Style property names. *)
  module Style : sig
    type prop = Jstr.t
    val background_color : prop
    val bottom : prop
    val color : prop
    val cursor : prop
    val display : prop
    val height : prop
    val left : prop
    val position : prop
    val right : prop
    val top : prop
    val visibility : prop
    val width : prop
    val z_index : prop
    val zoom : prop
  end

  val computed_style : ?w:window -> Style.prop -> t -> Jstr.t
  (** [computed_style ?w p e] is the computed style property [p] of [e] in
      window [w] (defaults to {!G.window}). *)

  val inline_style : Style.prop -> t -> Jstr.t
  (** [inline_style p e] is the inline style property [p] of [e]. *)

  val set_inline_style : ?important:bool -> Style.prop -> Jstr.t -> t -> unit
  (** [set_inline_style ~important p v e] sets the inline style property [p] of
      [e] to [v] with priority [important] (defaults to [false]). *)

  val remove_inline_style : Style.prop -> t -> unit
  (** [remove_inline_style p e] removes the inline style property [p]
      of [e]. *)

  (** {1:layout Layout} *)

  (** The {e inner bound} of an element includes its content and
      padding but not its border. We use the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/clientWidth}
      [client*]} properties to get it. These only have integral CSS pixel
      precision. *)

  val inner_x : t -> float
  (** [inner_x e] is the horizontal coordinate in the viewport of
      [e]'s inner bound. Add {!Window.scroll_x} to get the position
      relative to the document. *)

  val inner_y : t -> float
  (** [inner_y e] is the vertical coordinate in the viewport of [e]'s
      inner bound. Add {!Window.scroll_y} to get the position relative
      to the document. *)

  val inner_w : t -> float
  (** [inner_w e] is [e]'s inner bound width. *)

  val inner_h : t -> float
  (** [inner_h e] is [e]'s inner bound height. *)

  (** The {e bound} of an element includes its content, padding and border.
      We use {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/getBoundingClientRect}[getBoundingClientRect]} to get it. These have CSS subpixel
      precision. *)

  val bound_x : t -> float
  (** [bound_x e] is the horizontal coordinate in the viewport of
      [e]'s bound.  Add {!Window.scroll_x} to get the position
      relative to the document. *)

  val bound_y : t -> float
  (** [bound_y e] is the vertical coordinate in the viewport of [e]'s
      bound. Add {!Window.scroll_y} to get the position relative to
      the document. *)

  val bound_w : t -> float
  (** [bound_w e] is [e]'s bound width. *)

  val bound_h : t -> float
  (** [bound_h e] is [e]'s bound height. *)

  (** {1 Offset} *)

  val offset_h : t -> int
  val offset_w : t -> int
  val offset_top : t -> int
  val offset_left : t -> int
  val offset_parent : t -> t option

  (** {1:scrolling Scrolling} *)

  val scroll_x : t -> float
  (** [scroll_x e] is the number of pixels scrolled horizontally. *)

  val scroll_y : t -> float
  (** [scroll_y e] is the number of pixels scrolled vertically. *)

  val scroll_w : t -> float
  (** [scroll_w e] is the minimum width the element would require
      to display without a vertical scrollbar. *)

  val scroll_h : t -> float
  (** [scroll_h e] is the minimum height the element would require
      to display without a vertical scrollbar. *)

  val scroll_into_view :
    ?align_v:[ `Center | `End | `Nearest | `Start ] ->
    ?behavior:[< `Auto | `Instant | `Smooth ] ->
    t ->
    unit
  (** [scroll_into_view ~align_v ~behavior e]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoView}scrolls}
      [e] into view.

      [align_v] controls the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoView#block}block}
      option:
      - with [`Start] (default) the top of the element is align with to to the
        top of the scrollable area.
      - with [`End] the bottom of the element is
        aligned with the bottom of the scrollable area.

      [behavior] controls the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoView#behavior}behavior}
      option:
      - with [`Auto] (default) scroll behavior is determined by the computed value of [scroll-behavior].
      - with [`Smooth] scrolling should animate smoothly.
      - with [`Instant] scrolling should happen instantly in a single jump.
  *)

  (** {1:focus Focus} *)

  val has_focus : t -> bool
  (** [has_focus e] is [true] if [e] has focus in the document it belongs
      to. *)

  val set_has_focus : bool -> t -> unit
  (** [set_has_focus b e] sets the focus of [e] to [b] in the document
      it belongs do. *)

  (** {1:pointerlock Pointer locking} *)

  val is_locking_pointer : t -> bool
  (** [is_locking_pointer  e] is [true] if [e] is the element which locked
      the pointer. *)

  val request_pointer_lock : t -> unit Fut.or_error
  (** [request_pointer_lock e] requests the pointer to be locked
      to [e] in the document it belongs to. This listens on the
      document for the next {!Ev.pointerlockchange} and
      {!Ev.pointerlockerror} to resolve the future appropriately. *)

  (** {1:shadowroot Shadow root} *)

  module Shadow_root : sig
    type t

    val active_element : t -> el option

    (**/**)
    include Jv.CONV with type t := t
    (**/**)

  end

  val shadow_root : t -> Shadow_root.t option

  (** {1:fullscreen Fullscreen} *)

  (** Fullscreen navigation enum. *)
  module Navigation_ui : sig
    type t = Jstr.t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FullscreenOptions/navigationUI#Value}[navigationUI]} values. *)

    val auto : t
    val hide : t
    val show : t
  end

  type fullscreen_opts
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/FullscreenOptions}
      FullscreenOptions} objects. *)

  val fullscreen_opts :
    ?navigation_ui:Navigation_ui.t -> unit -> fullscreen_opts
  (** [fullscreen_opts ()] are options for fullscreen with given
      {{:https://developer.mozilla.org/en-US/docs/Web/API/FullscreenOptions}
      parameters}. *)

  val request_fullscreen : ?opts:fullscreen_opts -> t -> unit Fut.or_error
  (** [request_fullscreen e] requests to make the element
      to be displayed in fullscreen mode. *)

  (** {1:click Click simulation} *)

  val click : t -> unit
  (** [click e] simulates a click on [e]. *)

  val select_text : t -> unit
  (** [select_text e] selects the textual contents of [e]. If the DOM
      element [e] has no [select] method this does nothing. *)

  (** {1:ifaces Element interfaces}

      Some interfaces are in other modules. See for example
      {!Brr_io.Media.El} for the media element interface,
      {!Brr_canvas.Canvas} for the canvas element interface and
      {!Brr_io.Form} for the form element interface. *)

  (** The HTML
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement}
      input element interface} . *)
  module Input : sig
    val files : t -> File.t list
    (** [files e] is the file list held by element [e]. Usually [e]
        is an {!El.input} of {!At.type'} file. The empty list is
        returned if [e] has no such list. *)
  end

  (** {1:els Element names and constructors}

      See the
      {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element}MDN
      HTML element reference}.

      {b Convention.} Whenever an element name conflicts with an OCaml
      keyword we prime it, see for example {!object'}. *)

  (** Element names *)
  module Name : sig
    val a : tag_name
    val abbr : tag_name
    val address : tag_name
    val area : tag_name
    val article : tag_name
    val aside : tag_name
    val audio : tag_name
    val b : tag_name
    val base : tag_name
    val bdi : tag_name
    val bdo : tag_name
    val blockquote : tag_name
    val body : tag_name
    val br : tag_name
    val button : tag_name
    val canvas : tag_name
    val caption : tag_name
    val cite : tag_name
    val code : tag_name
    val col : tag_name
    val colgroup : tag_name
    val command : tag_name
    val datalist : tag_name
    val dd : tag_name
    val del : tag_name
    val details : tag_name
    val dfn : tag_name
    val div : tag_name
    val dl : tag_name
    val dt : tag_name
    val em : tag_name
    val embed : tag_name
    val fieldset : tag_name
    val figcaption : tag_name
    val figure : tag_name
    val footer : tag_name
    val form : tag_name
    val h1 : tag_name
    val h2 : tag_name
    val h3 : tag_name
    val h4 : tag_name
    val h5 : tag_name
    val h6 : tag_name
    val head : tag_name
    val header : tag_name
    val hgroup : tag_name
    val hr : tag_name
    val html : tag_name
    val i : tag_name
    val iframe : tag_name
    val img : tag_name
    val input : tag_name
    val ins : tag_name
    val kbd : tag_name
    val keygen : tag_name
    val label : tag_name
    val legend : tag_name
    val li : tag_name
    val link : tag_name
    val map : tag_name
    val mark : tag_name
    val menu : tag_name
    val meta : tag_name
    val meter : tag_name
    val nav : tag_name
    val noscript : tag_name
    val object' : tag_name
    val ol : tag_name
    val optgroup : tag_name
    val option : tag_name
    val output : tag_name
    val p : tag_name
    val param : tag_name
    val pre : tag_name
    val progress : tag_name
    val q : tag_name
    val rp : tag_name
    val rt : tag_name
    val ruby : tag_name
    val s : tag_name
    val samp : tag_name
    val script : tag_name
    val section : tag_name
    val select : tag_name
    val small : tag_name
    val source : tag_name
    val span : tag_name
    val strong : tag_name
    val style : tag_name
    val sub : tag_name
    val summary : tag_name
    val sup : tag_name
    val table : tag_name
    val tbody : tag_name
    val td : tag_name
    val textarea : tag_name
    val tfoot : tag_name
    val th : tag_name
    val thead : tag_name
    val time : tag_name
    val title : tag_name
    val tr : tag_name
    val track : tag_name
    val u : tag_name
    val ul : tag_name
    val var : tag_name
    val video : tag_name
    val wbr : tag_name
  end

  type cons =  ?d:document -> ?at:At.t list -> t list -> t
  (** The type for element constructors. This is simply {!v} with a
      pre-applied element name. *)

  type void_cons = ?d:document -> ?at:At.t list -> unit -> t
  (** The type for void element constructors. This is simply {!v}
      with a pre-applied element name and without children. *)

  val a : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a}a} *)

  val abbr : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/abbr}abbr} *)

  val address : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/address}
      address} *)

  val area : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/area}
      area} *)

  val article : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/article}
      article} *)

  val aside : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/aside}
      aside} *)

  val audio : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/audio}
      audio} *)

  val b : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/b}b} *)

  val base : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base}
      base} *)

  val bdi : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/bdi}
      bdi} *)

  val bdo : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/bdo}
      bdo} *)

  val blockquote : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/blockquote}
      blockquote} *)

  val body : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/body}
      body} *)

  val br : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/br}br} *)

  val button : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button}
      button} *)

  val canvas : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/canvas}
      canvas} *)

  val caption : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/caption}
      caption} *)

  val cite : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/cite}
      cite} *)

  val code : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/code}
      code} *)

  val col : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/col}
      col} *)

  val colgroup : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/colgroup}
      colgroup} *)

  val command : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/command}
        command} *)

  val datalist : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/datalist}
      datalist} *)

  val dd : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dd}dd} *)

  val del : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/del}
      del} *)

  val details : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/details}
      details} *)

  val dfn : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dfn}
      dfn} *)

  val div : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/div}
      div} *)

  val dl : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dl}dl} *)

  val dt : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dt}dt} *)

  val em : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/em}em} *)

  val embed : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/embed}
      embed} *)

  val fieldset : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/fieldset}
      fieldset} *)

  val figcaption : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/figcaption}
      figcaption} *)

  val figure : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/figure}
      figure} *)

  val footer : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/footer}
      footer} *)

  val form : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form}
        form} *)

  val h1 : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h1}h1} *)

  val h2 : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h2}h2} *)

  val h3 : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h3}h3} *)

  val h4 : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h4}h4} *)

  val h5 : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h5}h5} *)

  val h6 : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h6}h6} *)

  val head : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/head}
      head} *)

  val header : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/header}
      header} *)

  val hgroup : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/hgroup}
        hgroup} *)

  val hr : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/hr}hr} *)

  val html : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/html}
        html} *)

  val i : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/i}i} *)

  val iframe : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe}
        iframe} *)

  val img : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/img}
        img} *)

  val input : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input}
        input} *)

  val ins : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ins}
        ins} *)

  val kbd : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/kbd}
        kbd} *)

  val keygen : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/keygen}
        keygen} *)

  val label : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/label}
        label} *)

  val legend : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/legend}
      legend} *)

  val li : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/li}li} *)

  val link : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/link}link} *)

  val map : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/map}map} *)

  val mark : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/mark}mark} *)

  val menu : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/menu}menu} *)

  val meta : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta}meta} *)

  val meter : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meter}
      meter} *)

  val nav : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/nav}nav} *)

  val noscript : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/noscript}
      noscript} *)

  val object' : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/object}
      object} *)

  val ol : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ol}ol} *)

  val optgroup : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/optgroup}
      optgroup} *)

  val option : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/option}
      option} *)

  val output : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/output}
      output} *)

  val p : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/p}p} *)

  val param : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/param}
      param} *)

  val pre : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/pre}
      pre} *)

  val progress : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/progress}
      progress} *)

  val q : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/q}q} *)

  val rp : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/rp}rp} *)

  val rt : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/rt}rt} *)

  val ruby : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ruby}ruby} *)

  val s : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/s}s} *)

  val samp : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/samp}
      samp} *)

  val script : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script}
      script} *)

  val section : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/section}
      section} *)

  val select : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/select}
      select} *)

  val small : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/small}
      small} *)

  val source : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/source}
      source} *)

  val span : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/span}
      span} *)

  val strong : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/strong}
      strong} *)

  val style : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/style}
      style} *)

  val sub : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/sub}
      sub} *)

  val summary : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/summary}
      summary} *)

  val sup : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/sup}
      sup} *)

  val table : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/table}
      table} *)

  val tbody : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tbody}
      tbody} *)

  val td : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/td}td} *)

  val textarea : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/textarea}
      textarea} *)

  val tfoot : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tfoot}
      tfoot} *)

  val th : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/th}th} *)

  val thead : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/thead}
      thead} *)

  val time : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/time}
      time} *)

  val title : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/title}
      title} *)

  val tr : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tr}tr} *)

  val track : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/track}
      track} *)

  val u : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/u}u} *)

  val ul : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ul}ul} *)

  val var : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/var}
      var} *)

  val video : cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video}
      video} *)

  val wbr : void_cons
  (** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/wbr}
      wbr} *)
end

(** [Document] objects *)
module Document : sig

  type t = El.document
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document}Document}
      objects. See {!G.document} for the global object. *)

  val as_target : t -> Ev.target
  (** [as_target d] is the document as an event target. *)

  val element : t -> El.t
  (** [element d] is the element that is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/documentElement}root
      element} of the document (for example, the [<html>] element for HTML
      documents). *)

  (** {1:el_lookups Element lookups} *)

  val find_el_by_id : t -> Jstr.t -> El.t option
  (** [find_el_by_id d id] is the element of the document with [id] attribute
      equal to [id] (if any). *)

  val find_els_by_name : t -> Jstr.t -> El.t list
  (** [find_els_by_name d n] is the list of elements of the document with
      [name] attribute equal to [n]. *)

  val root : t -> El.t
  (** [root d] is the document's
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/documentElement}root element}. *)

  val body : t -> El.t
  (** [body d] is the document's {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/body}body element}.

      {b Warning.} Technically this could be [null] if your script
      loads too early. It's a bit inconvenient to have it as an option
      though so we raise a {{!Jv.exception-Error}JavaScript error} if that
      happens; see {{!page-web_page_howto}here} on the way to load your
      script so that it does not. *)

  val head : t -> El.t
  (** [head d] is the document's
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/head}head
      element}. *)

  val active_el : t -> El.t option
  (** [active_el d] is the document's
        {{:https://developer.mozilla.org/en-US/docs/Web/API/DocumentOrShadowRoot/activeElement}active element}, that is the one that has the focus (if any). *)

  (** {1:props Properties} *)

  val referrer : t -> Jstr.t
  (** [referrer d] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/referrer}
      referrer}. *)

  val title : t -> Jstr.t
  (** [title d] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/title}
      document title}. *)

  val set_title : t -> Jstr.t -> unit
  (** [set_title d t] sets the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/title}
      document title}. *)

  (** Visibility state enumeration. *)
  module Visibility_state : sig
    type t = Jstr.t
    (** The type for {{:https://www.w3.org/TR/page-visibility/#visibility-states-and-the-visibilitystate-enum}visibility state} values. *)

    val hidden : t
    val visible : t
  end

  val visibility_state : t -> Visibility_state.t
  (** [visibility_state d] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/visibilityState}visibility state} of [d].
      Use the {!Ev.visibilitychange} event to watch for changes. *)

  (** {1:pointerlock Pointer locking} *)

  val pointer_lock_element : t -> El.t option
  (** [pointer_lock_element d] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/DocumentOrShadowRoot/pointerLockElement}element} that currently locks the pointer (if any). *)

  val exit_pointer_lock : t -> unit Fut.t
  (** [exit_pointer_lock d] {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/exitPointerLock}exits} pointer lock mode. The future determines
      when the corresponding {!Ev.pointerlockchange} on [d] has fired. *)

  (** {1:fullscreen Fullscreen}

      Use {!El.request_fullscreen} to get into fullscreen mode. *)

  val fullscreen_available : t -> bool
  (** [fullscreen_available d] is [true] if fullscreen functionality is
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/fullscreenEnabled}supported} and can be used. *)

  val fullscreen_element : t -> El.t option
  (** [fullscreen_element d] is the element that is being
      currently
      {{:https://developer.mozilla.org/en-US/docs/Web/API/DocumentOrShadowRoot/fullscreenElement}presented} in fullscreen mode (if any). *)

  val exit_fullscreen : t -> unit Fut.or_error
  (** [exit_fullscreen d]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Document/exitFullscreen}exits} fullscreen mode. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** {1:browser Browser interaction} *)

(** Aborting browser activities.

    This mecanism provides a way to abort futures with
    a {!Jv.Error.t} named [AbortError] ([`Abort_error] in
    {!Jv.Error.type-enum}). *)
module Abort : sig

  (** Abort signals. *)
  module Signal : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal}
        [AbortSignal]} objects. *)

    external as_target : t -> Ev.target = "%identity"
    (** [as_target s] is the signal as an event target. *)

    val aborted : t -> bool
    (** [aborted s] is [true] if [s] has
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/aborted}signaled} to abort. *)

    val abort : Ev.void
    (** [abort] is the type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/abort_event}[abort]} events. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/AbortController}
      [AbortController]} objects. *)

  val controller : unit -> t
  (** [controller ()] is a new abort {{:https://developer.mozilla.org/en-US/docs/Web/API/AbortController}controller}. *)

  val signal : t -> Signal.t
  (** [signal c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AbortController/signal}signal} associated to abort controller [c]. *)

  val abort : t -> unit
  (** [abort c]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/AbortController/abort}
      aborts} the signal of [c] and informs its observers the
      associated activity is to be aborted. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** Browser console.

    See {{:https://developer.mozilla.org/en-US/docs/Web/API/console}
    [Console]}. Take a few minutes to {{!Console.val-log}understand this}. *)
module Console : sig

  type t
  (** The type for
    {{:https://developer.mozilla.org/en-US/docs/Web/API/console}[console]}
    objects. See {!G.console} for the global console object. *)

  val get : unit -> t
  (** [get ()] is the console object on which the functions below act.
      Initially this is {!G.console}. *)

  val set : t -> unit
  (** [set o] sets the console object to [o]. *)

  val clear : unit -> unit
  (** [clear ()]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/clear}clears}
      the console. *)

  (** {1:log_funs Log functions} *)

  type msg =
  | [] : msg
  | ( :: ) : 'a * msg -> msg (** *)
  (** The type for log messages. *)

  type 'a msgr = 'a -> msg
  (** The type for functions turning values of type ['a] into log
      messages. *)

  val msg : 'a msgr
  (** [msg v] is [[v]]. *)

  type log = msg -> unit
  (** The type for log functions.

      Log messages rebind OCaml's list syntax. This allows to
      write heterogeneous logging statements concisely.

{[
let () = Console.(log [1; 2.; true; Jv.true'; str "🐫"; G.navigator])
]}

      The console logs JavaScript values. For OCaml values this means
      that their [js_of_ocaml] representation is logged; see the
      {{!page-ffi_manual}FFI manual} for details.  Most OCaml values
      behind [Brr] types are however direct JavaScript values and
      logging them as is will be valuable. For other values you can
      use the {!str} function which invokes the JavaScript [toString]
      method on the value. It works on OCaml strings and is mostly
      equivalent and shorter than calling {!Jstr.v} before logging
      them.

      In the JavaScript [console] API, if the first argument is a JavaScript
      string it can have
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console#Using_string_substitutions}formatting
      specifications}.  Just remember this should be a JavaScript string, so
      wrap OCaml literals by {!str} or {!Jstr.v}:
{[
let () = Console.(log [str "This is:\n%o\n the navigator"; G.navigator])
]}
*)

  val str : 'a -> Jstr.t
  (** [str v] is the result of invoking the JavaScript [toString] method on
      the representation of [v]. If [v] is {!Jv.null} and {!Jv.undefined}
      a string representing them is directly returned. *)

  (** {1:result [Result] logging} *)

  val log_result :
    ?ok:'a msgr -> ?error:'b msgr -> ('a, 'b) result -> ('a, 'b) result

  (** [log_result ~ok ~error r] is [r] but logs [r] using {!val-log} and
      [ok] to format [Ok v] and {!error} and [error] for [Error
      e]. [ok] defaults to [[v]] and [error] to [[str e]]. *)

  val log_if_error :
    ?l:log -> ?error_msg:'b msgr -> use:'a -> ('a, 'b) result -> 'a
  (** [log_if_error ~l ~error_msg ~use r] is [v] if [r] is [Ok v]
      and [use] if [r] is [Error e]. In this case [e] is logged with [l]
      (defaults to {!error}) and [error_msg] (defaults to [str e]). *)

  val log_if_error' :
    ?l:log -> ?error_msg:'b msgr -> use:'a -> ('a, 'b) result ->
    ('a, 'b) result
  (** [log_if_error'] is {!log_if_error} wrapped by {!Result.ok}. *)

  (** {1:logging Levelled logging} *)

  val log : log
  (** [log m]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/log}logs}
      [m] with no specific level. *)

  val trace : log
  (** [trace m] logs [m] with no specific level but with a
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/trace}
      stack trace}, like {!error} and {!warn} do. *)

  val error : log
  (** [error m] logs [m] with level
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/error}
      error}. *)

  val warn : log
  (** [warn m] logs [m] with level
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/warn}
      warn}. *)

  val info : log
  (** [warn m] logs [m] with level
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/info}
      info}. *)

  val debug : log
  (** [debug m] logs [m] with level
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/debug}
      debug}. *)

  (** {1:assert_dump Asserting and dumping} *)

  val assert' : bool -> log
  (** [assert' c m]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/assert}
      asserts} [c] and logs [m] with a stack trace iff [c] is [false]. *)

  val dir : 'a -> unit
  (** [dir o] logs a
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/dir}
      listing} of the properties of the object [o] –
      {{:https://stackoverflow.com/a/11954537}this} explains
      the difference with [Console.(log [o])]. *)

  val table : ?cols:Jstr.t list -> 'a -> unit
  (** [table v] outputs [v] as
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/table}
      tabular data}. If [cols] is specified only the specified
      properties are printed. *)

  (** {1:grouping Grouping} *)

  val group : ?closed:bool -> log
  (** [group ~closed msg] logs [msg] and pushes a new inline
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/group}group}
      in the console. This indents messages until {!group_end} is called. If
      [closed] is [true] (defaults to [false]) the group's content is hidden
      behind a {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/groupCollapsed}disclosure button}. *)

  val group_end : unit -> unit
  (** [group_end ()]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/groupEnd}
      pops} the last inline group. *)

  (** {1:count Counting} *)

  val count : Jstr.t -> unit
  (** [count label] logs [label] with the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/count}
      number of times} [count label] was called. *)

  val count_reset : Jstr.t -> unit
  (** [count_reset label]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/countReset}
      resets} the counter for [count label]. *)

  (** {1:timing Timing} *)

  val time : Jstr.t -> unit
  (** [time label]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/time}starts}
      a timer named [label]. *)

  val time_log : Jstr.t -> log
  (** [time_log label msg]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/timeLog}
      reports} the timer value of [label] with [msg] appended to the
      report. *)

  val time_end : Jstr.t -> unit
  (** [time_end label]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/timeEnd}
      ends} the timer named [label]. *)

  (** {1:profiling Profiling} *)

  val profile : Jstr.t -> unit
  (** [profile label]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/profile}
      starts} a new profile labelled [label]. *)

  val profile_end : Jstr.t -> unit
  (** [profile_end label]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/profileEnd}
      ends} ends the new profile labelled [label]. *)

  val time_stamp : Jstr.t -> unit
  (** [time_stamp label]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Console/timeStamp}
      adds} a marker labeled by [label] in the waterfall view. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** [Window] objects.

    Some of the objects and methods that are accessed from Window objects
    are in other modules:
    {ul
    {- {!Brr_io.Storage.local} and {!Brr_io.Storage.session}}
    {- {!Brr_io.Message.window_post}}}
*)
module Window : sig

  type t = El.window
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window}[Window]}
      objects. See {!G.window} for the global window object. *)

  val as_target : t -> Ev.target
  (** [as_target w] is the window as an event target. *)

  val closed : t -> bool
  (** [closed w] is [true] if [w] is
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/closed}
      closed}. *)

  val scroll_x : t -> float
  (** [scroll_x w] is the number of (sub)pixels the window is
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollX}
      horizontally scrolled} by. *)

  val scroll_y : t -> float
  (** [scroll_y w] is the number of (sub)pixels the window is
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollY}
      vertically scrolled} by. *)

  val inner_width : t -> int
  (** [inner_width w] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/innerWidth}interior
      height} of the window in pixels, including the width of the vertical
      scroll bar, if present. *)

  val inner_height : t -> int
  (** [inner_height w] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/innerHeight}interior
      height} of the window in pixels, including the height of the horizontal
      scroll bar, if present. *)

  val document : t -> Document.t
  (** [document w] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/document}document
      of the window}. *)

  val parent : t -> t option
  (** [parent w] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/parent}parent}
      of the window, if it has one.

      When a window is loaded in an [<iframe>], [<object>], or [<frame>], its
      parent is the window with the element embedding the window. *)

  val name : t -> Jstr.t
  (** [name w] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/name}
      name} of [w]. *)

  val set_name : Jstr.t -> t -> unit
  (** [set_name w] sets the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/name}
      name} of [w]. *)

  val post_message : t -> msg:Jv.t -> unit
  (** [post_message w ~msg]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage}dispatches}
      a {{!Brr_io.Message.Ev}Message events} on [w]. *)

  (** {1:media Media properties} *)

  val device_pixel_ratio : t -> float
  (** [device_pixel_ratio w] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/devicePixelRatio}ratio} between physical and CSS
      pixels. A value of [2.] indicates that two physical pixels are
      used to draw a single CSS pixel. *)

  val matches_media : t -> Jstr.t -> bool
  (** [matches_media w mq] is [true] if the media query [mq] matches.
      See {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/matchMedia}
      [Window.matchMedia]}. *)

  val prefers_dark_color_scheme : t -> bool
  (** [prefers_dark_scheme w] is [true] if the ["(prefers-color-scheme:
      dark)"] media query matches. *)

  (** {1:ops Operations} *)

  val open' : ?features:Jstr.t -> ?name:Jstr.t -> t -> Jstr.t -> t option
  (** [open' w url ~name ~features]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/open}
      loads the specified resource} [url] into a new or existing browsing
      context with the specified [name] and
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/open#windowfeatures}
      window features}. [None] is returned if the window could not be
      opened.*)

  val close : t -> unit
  (** [close w]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/close}
      closes} window [w]. *)

  val print : t -> unit
  (** [print w] opens the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/print}
      print dialog} to print the window document. *)

  val reload : t -> unit
  (** [reload w]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Location/reload}
      reloads} [w] (on its [location] property). *)

  (** {1:loc Location and history} *)

  val location : t -> Uri.t
  (** [location w] is the window's
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/location}
      location}.

      Note we do not bind the [Location] object, everything you need
      can be done with {!Uri}, {!set_location}, {!reload} and possibly
      {!History}. *)

  val set_location : t -> Uri.t -> unit
  (** [set_location w l] sets the window location to [l]. *)

  (** Browser history. *)
  module History : sig

    (** The scroll restoration enum. *)
    module Scroll_restoration : sig
      type t = Jstr.t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/History/scrollRestoration#Values}scroll restoration} values. *)

      val auto : t
      val manual : t
    end

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/History}[History]}
        objects. See {!Window.history} to get one. *)

    val length : t -> int
    (** [length h] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/History/length}
        number} of elements in history including the currently loaded page. *)

    val scroll_restoration : t -> Scroll_restoration.t
    (** [scroll_restoration h] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/History/scrollRestoration}scroll restoration} behaviour of [h]. *)

    val set_scroll_restoration : t -> Scroll_restoration.t -> unit
    (** [set_scroll_restoration h r] sets the {!scroll_restoration}
        of [h] to [r]. *)

    (** {1:moving Moving in history} *)

    val back : t -> unit
    (** [back h] goes
        {{:https://developer.mozilla.org/en-US/docs/Web/API/History/back}back}
        in history. *)

    val forward : t -> unit
    (** [forward h] goes
        {{:https://developer.mozilla.org/en-US/docs/Web/API/History/forward}
        forward} in history. *)

    val go : t -> int -> unit
    (** [go delta]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/History/go}goes}
        forward or backward in history by [delta] steps. [0] reloads
        the current page. *)

    (** {1:making Making history}

        {b Warning.} This may become typed in the future. Note that
        the specifiation mandates {!type-state} values to be serializable. *)

    type state = Jv.t
    (** The type for history state. *)

    val state : t -> Jv.t
    (** [state h] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/History/state}state}
        at the top of the history stack.
        {b Warning.} This can be {!Jv.null} *)

    val push_state : ?state:state -> ?title:Jstr.t -> ?uri:Uri.t -> t -> unit
    (** [push_state h ~state ~title ~uri h]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/History/pushState}
        pushes} state [state] with title [title] and URI [uri] (if any).
        Any of these can be omitted.

        {b Warning.} The [title] argument seems to be ignored by
        browsers. Use {!Document.set_title} to change the title. *)

    val replace_state : ?state:state -> ?title:Jstr.t -> ?uri:Uri.t -> t -> unit
    (** [replace_state h ~state ~title ~uri]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/History/replaceState}replaces} state [state] with title [title] and URI [uri] (if any).
        Any of these can be omitted.

        {b Warning.} The [title] argument seems to be ignored by
        browsers. Use {!Document.set_title} to change the title. *)

    (** {1:events Events} *)

    (** History events. *)
    module Ev : sig

      (** Popstate events. *)
      module Popstate : sig
        type t
        (** The type for
            {{:https://developer.mozilla.org/en-US/docs/Web/API/PopStateEvent}
            [PopStateEvent]} objects. *)

        val state : t -> state
        (** [state e] is the new history state. *)
      end

      val popstate : Popstate.t Ev.type'
      (** [popstate] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/PopStateEvent}popstate} event. Note this should be listened to on the
          window. *)
    end
    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  val history : t -> History.t
  (** [history w] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/history}
      history} of [w]. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** [Navigator] objects.

    Some of the objects that are accessed from Navigator objects have
    the accessor in the module that handles them:
    {ul
    {- {!Brr_io.Clipboard.of_navigator}}
    {- {!Brr_io.Geolocation.of_navigator}}
    {- {!Brr_io.Media.Devices.of_navigator}}
    {- {!Brr_webmidi.Midi.Access.of_navigator}}} *)
module Navigator : sig

  type t
  (** The type for navigator
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Navigator}[Navigator]}
      objects. See {!G.navigator} for the global navigator object. *)

  val languages : t -> Jstr.t list
  (** [languages n] is the user's preferred languages as BCP 47
      language tags ordered by decreasing preference.

      This consults [navigator.languages] and [navigator.language].
      See also {!Ev.languagechange} *)

  val max_touch_points : t -> int
  (** [max_touch_points n] is the maximum number of simultaneous
      touch contacts supported by the user agent.  See the
      {{:https://www.w3.org/TR/pointerevents2/#extensions-to-the-navigator-interface}pointer
      events spec}. *)

  val online : t -> bool
  (** [online n] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/NavigatorOnLine/onLine} online status} of the browser. See the docs, the semantics is
      browser dependent. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** [Performance] objects.

    See the {{:https://developer.mozilla.org/en-US/docs/Web/API/Performance_API}
    Peformance API} and {{:https://developer.mozilla.org/en-US/docs/Web/API/Performance_Timeline}Peformance Timeline API}. *)
module Performance : sig

  (** Performance entry objects. *)
  module Entry : sig

    (** Entry type enum. *)
    module Type : sig
      type t = Jstr.t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceEntry/entryType#Performance_entry_type_names}entry type} values. *)

      val frame : t
      val navigation : t
      val resource : t
      val mark : t
      val measure : t
      val paint : t
      val longtask : t
    end

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceEntry}
        [PerformanceEntry]} objects. *)

    val name : t -> Jstr.t
    (** [name e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceEntry/name}name} of [e]. *)

    val type' : t -> Type.t
    (** [type' e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceEntry/entryType}type} of [e]. *)

    val start_time : t -> float
    (** [start_time e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceEntry/startTime}start time} of [e]. *)

    val end_time : t -> float
    (** [end_time e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceEntry/startTime}end time} of [e]. *)

    val duration : t -> float
    (** [duration e] is the duration of
        {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceEntry/duration}duration} of [e]. *)

    val to_json : t -> Json.t
    (** [to_json e] is a JSON {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceEntry/toJSON}representation} of [e]. *)

    (** {1:entry_types Entry types}

        Always check the {!type'} before coercing an entry type
        to its subtype. Objects of type
        {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceMark}[PerformanceMark]},
{{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceMeasure}[PerformanceMeasure]},
        {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceFrameTiming}[PerformanceFrameTiming]}, and {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformancePaintTiming}[PerformancePaintTiming]}
        do not provide additional properties, so no modules are provided
        for them. *)

    type entry = t
    (** See {!t}. *)

    (** Resource timing entries. *)
    module Resource_timing : sig
      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceResourceTiming}[PerformanceResourceTiming]} objects. *)

      val as_entry : t -> entry
      (** [as_entry m] is [m] as an entry. *)

      val initiator_type : t -> Jstr.t
      val next_hop_protocol : t -> Jstr.t
      val worker_start : t -> float
      val redirect_start : t -> float
      val redirect_end : t -> float
      val fetch_start : t -> float
      val domain_lookup_start : t -> float
      val domain_lookup_end : t -> float
      val connect_start : t -> float
      val connect_end : t -> float
      val secure_connection_start : t -> float
      val request_start : t -> float
      val response_start : t -> float
      val response_end : t -> float
      val transfer_size : t -> int
      val encoded_body_size : t -> int
      val decoded_body_size : t -> int
      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Navigation timing entries. *)
    module Navigation_timing : sig

      (** Navigation type enum. *)
      module Type : sig
        type t = Jstr.t
        (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceNavigationTiming/type}entry type} values. *)

        val navigate : t
        val reload : t
        val back_forward : t
        val prerender : t
      end

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/PerformanceNavigationTiming}[PerformanceNavigationTiming]} objects. *)

      val as_entry : t -> entry
      (** [as_entry m] is [m] as an entry object. *)

      val as_resource_timing : t -> Resource_timing.t
      (** [as_resource_timing n] is [n] as a ressource timing object. *)

      val unload_event_start : t -> float
      val unload_event_end : t -> float
      val dom_interactive : t -> float
      val dom_content_loaded_event_start : t -> float
      val dom_content_loaded_event_end : t -> float
      val dom_complete : t -> float
      val load_event_start : t -> float
      val load_event_end : t -> float
      val type' : t -> Type.t
      val redirect_count : t -> int
      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    val as_resource_timing : t -> Resource_timing.t
    (** [as_resource_timing e] is [e] as a ressource timing entry. *)

    val as_navigation_timing : t -> Navigation_timing.t
    (** [as_navigation_timing e] is [e] as a navigation timing entry. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  type t
  (** The type for performance
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Performance}
      [Performance]} objects. See {!G.performance} for the global
      performance object. *)

  val time_origin_ms : t -> float
  (** [time_origin_ms p] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Performance/timeOrigin}start time} of the performance measurement. *)

  val clear_marks : t -> Jstr.t option -> unit
  (** [clear_marks p n] {{:https://developer.mozilla.org/en-US/docs/Web/API/Performance/clearMarks}clears} the marks named [n] or all of them on [None]. *)

  val clear_measures : t -> Jstr.t option -> unit
  (** [clear_measures p n] {{:https://developer.mozilla.org/en-US/docs/Web/API/Performance/clearMeasures}clears} the measures named [n] or all of them on
      [None]. *)

  val clear_resource_timings : t -> unit
  (** [clear_measures p n] {{:https://developer.mozilla.org/en-US/docs/Web/API/Performance/clearResourceTimings}clears} the resource. *)

  val get_entries : ?type':Entry.Type.t -> ?name:Jstr.t -> t -> Entry.t list
  (** [get_entries ~type' ~name' p] are [p]'s
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Performance/getEntriesByName}entries} in chronological
      order filtered by given [type'] and/or [name'] (both can be omited,
      possibly separately). *)

  val mark : t -> Jstr.t -> unit
  (** [mark p name] {{:https://developer.mozilla.org/en-US/docs/Web/API/Performance/mark}creates} an timestamped entry associated to name [name]. *)

  val measure : ?start:Jstr.t -> ?stop:Jstr.t -> t -> Jstr.t -> unit
  (** [measure p n ~start ~stop] {{:https://developer.mozilla.org/en-US/docs/Web/API/Performance/measure}creates} an entry to measure time between
      two marks. *)

  val now_ms : t -> float
  (** [now_ms p] is the number of millisecond elapsed since
      {!time_origin_ms}. *)

  val to_json : t -> Json.t
  (** [to_json p] is [p]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Performance/toJSON}
      converted} to a JSON object. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** The global object, its global objects and functions.

    If you are:
    {ul
    {- In Webworker context, see also {!Brr_webworkers.Worker.G}}
    {- In an audio worklet, see also {!Brr_webaudio.Audio.Worklet.G}}} *)
module G : sig

  (** {1:global_objects Global objects}

      Depending on the JavaScript environment theses values can be undefined.
      You should know what you are doing or use {!Jv.defined} to test
      the values.

      Because of type dependencies some global objects are defined
      in their dedicated modules:
      {ul
      {- {!Brr_io.Fetch.caches} is the global
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/caches}[caches]} object.}
      {- {!Brr_webcrypto.Crypto.crypto} is the global
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/crypto}
      [crypto]} object.}} *)

  val console : Console.t
  (** [console] is the global
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/console}
      [console]} object (if available). This
      is what {!Console.get} returns initially. *)

  val document  : Document.t
  (** [document] is the global
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/document}
      [document]} object (if available). *)

  val navigator : Navigator.t
  (** [navigator] is the global
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/navigator}
      [navigator]} object (if available). *)

  val performance : Performance.t
  (** [performance] is the global
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/performance}
      [performance]} object (if available). *)

  val window : Window.t
  (** [window] is the global
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/window}
      [window]} object (if available). *)

  (** {1:target Global event target and messaging} *)

  val target : Ev.target
  (** [target] is
      {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/globalThis}[globalThis]} as an event target. *)

  (** {1:global_props Global properties} *)

  val is_secure_context : bool
  (** [is_secure_context] is true [iff] the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/isSecureContext}current context is secure}. *)

  (** {1:timers Timers} *)

  type timer_id = int
  (** The type for timeout identifiers. *)

  val set_timeout : ms:int -> (unit -> unit) -> timer_id
  (** [set_timeout ~ms f] is a timer calling [f] in [ms] milliseconds unless
      {{!stop_timer}stopped} before. *)

  val set_interval : ms:int -> (unit -> unit) -> timer_id
  (** [set_interval ~ms f] is a timer calling [f] every [ms] milliseconds
      until it is {{!stop_timer}stopped}. *)

  val stop_timer : timer_id -> unit
  (** [stop_timer tid] stops timer [tid]. *)

  (** {1:anim Animation timing} *)

  type animation_frame_id = int
  (** The type for animation frame identifiers. *)

  val request_animation_frame : (float -> unit) -> animation_frame_id
  (** [request_animation_frame f] {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame}request} [f now] to be called before the next
      repaint. With [now] indicating the point in time in ms when the function
      is called. *)

  val cancel_animation_frame : animation_frame_id -> unit
  (** [cancel_animation_frame fid]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/cancelAnimationFrame}cancels} the animation frame request [a]. *)
end

module ResizeObserver : sig

  module Entry : sig
    type t

    val target : t -> El.t

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  type observer

  val create : (Entry.t list -> observer -> unit) -> observer

  val observe : observer -> El.t -> unit

  val unobserve : observer -> El.t -> unit

  val disconnect : observer -> unit

  (**/**)
  include Jv.CONV with type t := observer
  (**/**)
end
