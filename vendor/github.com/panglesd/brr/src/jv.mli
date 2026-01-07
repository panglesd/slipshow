(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** JavaScript values.

    See the FFI {{!page-ffi_manual}manual} and {{!page-ffi_cookbook}
    cookbook} for a gentle introduction. *)

(** {1:values Values} *)

type t
(** The type for JavaScript values. A value of this
    type represents a value of any
{{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#Data_and_Structure_types}JavaScript primitive type}. *)

type jv = t
(** See {!t}. *)

external equal : t -> t -> bool = "caml_js_equals"
(** [equal v0 v1] is JavaScript {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Equality}[==] equality}. *)

val strict_equal : t -> t -> bool
(** [strict_equal v0 v1] is JavaScript's {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Strict_equality}strict equality}.
    OCaml's [(==)] is mapped on that equality. *)

val typeof : t -> Jstr.t
(** [typeof] is the JavaScript
      {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/typeof}[typeof]} operator. *)

val instanceof : t -> cons:t -> bool
(** [instanceof o c] is [true] if [o] is an instance of constructor [c]. *)

external repr : 'a -> t = "%identity"
(** [repr v] is the OCaml value [v] as its JavaScript value representation. *)

(** {1:null_undefined Null and undefined} *)

val null : t
(** [null] is JavaScript {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/null}[null]}. *)

val undefined : t
(** [undefined] is JavaScript {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/undefined}[undefined]}. *)

val is_null : t -> bool
(** [is_null v] is [true] iff [v] is {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Strict_equality}strictly equal} to {!null}.
*)

val is_undefined : t -> bool
(** [is_undefined v] is [true] iff [v] is {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Strict_equality}strictly equal} to {!undefined}. *)

val is_none : t -> bool
(** [is_none v] is [is_null v || is_undefined v]. *)

val is_some : t -> bool
(** [is_some v] is [not (is_none v)]. *)

val to_option : (t -> 'a) -> t -> 'a option
(** [to_option conv v] is [None] if [v] is {!null} or {!undefined}
    and [Some (conv v)] if it is not. *)

val of_option : none:t -> ('a -> t) -> 'a option -> t
(** [of_option ~none conv o] is [none] if [o] is [None] and [conv v]
    if [o] is [Some v]. *)

(** {1:objects Objects} *)

val global : t
(** [global] refers to the {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/globalThis}global object}. *)

(** {2:props Properties} *)

type prop = string
(** The type for US-ASCII JavaScript object property names. *)

external get : t -> prop -> t = "caml_js_get"
(** [get o p] is the property [p] of [o]. {b Warning}, the result can
    be {!null} or {!undefined}. See also {!find}. *)

external set : t -> prop -> t -> unit = "caml_js_set"
(** [set o p v] sets property [p] of [o] to the value [v]. *)

external delete : t -> prop -> unit = "caml_js_delete"
(** [delete o p] deletes property [p] of [o]. The property [p] or [o]
    becomes {!undefined}. *)

val find : t -> prop -> t option
(** [find o p] is property [p] of [o]. If the property is {!null} or
     {!undefined}, the result is [None]. See also {!get}. *)

val find_map : (t -> 'a) -> t -> prop -> 'a option
(** [find_map f o p] is Option.map f (find o p). *)

val find_path : t -> prop list -> t option
(** [find_path o l] looks up the path [l] in [o]. This returns [None]
    if any segment is {!null} or {!undefined}. {b Note.} Useful for
    probing for functionality but rather inefficient. *)

val set_if_some : t -> prop -> t option -> unit
(** [set_if_some o p v] sets property [p] of [o] if [v] is [Some p]. Otherwise
    the [p] is left untouched in [o]. *)

(** {2:create Creating} *)

external obj : (prop * t) array -> t = "caml_js_object"
(** [obj props] is an object with properties [prop]. *)

external new' : t -> t array -> t = "caml_js_new"
(** [new' c args] creates an object with constructor function [c]
    and arguments [args]. {{!page-ffi_manual.create}Lookup} contructor
    functions in the {!Jv.global} object. *)

(** {2:methods Methods} *)

external call : t -> string -> t array -> t = "caml_js_meth_call"
(** [call o m args] calls the method named [m] on [o] with arguments
    [m]. [m] is assumed to be made of US-ASCII characters only, use
    {!call'} if that is not the case. *)

(** {1:bools Booleans} *)

val true' : t
(** [true] is JavaScript [true]. *)

val false' : t
(** [false'] is JavaScript [false]. *)

external to_bool : t -> bool = "caml_js_to_bool"
(** [to_bool v] is the JavaScript [Boolean] value [v] as a [bool]
    value.  {b This is unsafe}, only use if [v] is guaranted to be a
    JavaScript boolean. *)

external of_bool : bool -> t = "caml_js_from_bool"
(** [of_bool b] is the [bool] value [b] as a JavaScript [Boolean] value. *)

(** [bool] properties accessors. *)
module Bool : sig

  val find : t -> prop -> bool option
  (** [find o p] is [Option.map to_bool (find o p)]. {b This is
      unsafe}, only use if you know that if [o] defines [p] it is
      guaranteed to be a JavaScript boolean. *)

  val get : t -> prop -> bool
  (** [get o p] is [to_bool (get o p)]. {b This is unsafe}, only use
      if you know [o] has [p] and it is guaranteed to be a JavaScript
      boolean. *)

  val set : t -> prop -> bool -> unit
  (** [set o p b] is [set o p (of_bool b)]. *)

  val set_if_some : t -> prop -> bool option -> unit
  (** [set_if_some o p b] is [set_if_some o p (Option.map of_bool b)]. *)
end

(** {1:ints Integers} *)

external to_int : t -> int = "%identity"
(** [to_int v] is the JavaScript [Number] value [v] as an [int] value. The
    conversion is lossless provided [v] is integral. {b This is
    unsafe}, only use if [v] is guaranteed to be a JavaScript number. *)

external of_int : int -> t = "%identity"
(** [of_int i] is the [int] value [i] as a JavaScript [Number] value. The
    conversion is lossess. *)

(** [int] properties accessors. *)
module Int : sig
  val find : t -> prop -> int option
  (** [find o p] is [find_map to_int o p]. {b This is
      unsafe}, only use if you know that if [o] defines [p] it is
      guaranteed to be a JavaScript number. *)

  val get : t -> prop -> int
  (** [get o p] is [to_int (get o p)]. {b This is unsafe}, only use
      if you know [o] has [p] and it is guaranteed to be a JavaScript
      number. *)

  val set : t -> prop -> int -> unit
  (** [set o p b] is [set o p (of_int b)]. *)

  val set_if_some : t -> prop -> int option -> unit
  (** [set_if_some o p b] is [set_if_some o p (Option.map of_int b)]. *)
end

(** {1:floats Floating points} *)

external to_float : t -> float = "caml_js_to_float"
(** [to_float v] is the JavaScript [Number] value [v] as a [float] value. The
    conversion is lossless. *)

external of_float : float -> t = "caml_js_from_float"
(** [of_float f] is the [float] value [f] as a JavaScript [Number] value. The
    conversion is lossless. *)

(** [float] object properties. *)
module Float : sig
  val find : t -> prop -> float option
  (** [find o p] is [find_map to_float o p]. {b This is
      unsafe}, only use if you know that if [o] defines [p] it is
      guaranteed to be a JavaScript number. *)

  val get : t -> prop -> float
  (** [get o p] is [to_float (get o p)]. {b This is unsafe}, only use
      if you know [o] has [p] and it is guaranteed to be a JavaScript
      number. *)

  val set : t -> prop -> float -> unit
  (** [set o p b] is [set o p (of_float b)]. *)

  val set_if_some : t -> prop -> float option -> unit
  (** [set_if_some o p b] is [set_if_some o p (Option.map of_float b)]. *)
end

(** {1:int32 32-bits integers} *)

external to_int32 : t -> int32 = "caml_js_to_int32"
(** [to_int32 v] is the JavaScript [Number] value [v] as an [int32] value. The
    conversion is lossless provided [v] is a 32-bit signed integer. *)

external of_int32 : int32 -> t = "caml_js_from_int32"
(** [of_int32 f] is the [int32] value [f] as a JavaScript [Number] value. The
    conversion is lossless. *)

(** [int32] object properties. *)
module Int32 : sig
  val find : t -> prop -> int32 option
  (** [find o p] is [find_map to_int32 o p]. {b This is
      unsafe}, only use if you know that if [o] defines [p] it is
      guaranteed to be a JavaScript number. *)

  val get : t -> prop -> int32
  (** [get o p] is [to_int32 (get o p)]. {b This is unsafe}, only use
      if you know [o] has [p] and it is guaranteed to be a JavaScript
      number. *)

  val set : t -> prop -> int32 -> unit
  (** [set o p b] is [set o p (of_int32 b)]. *)

  val set_if_some : t -> prop -> int32 option -> unit
  (** [set_if_some o p b] is [set_if_some o p (Option.map of_int32 b)]. *)
end

(** {1:jstr JavaScript strings} *)

external to_jstr : t -> Jstr.t = "%identity"
(** [to_jstr v] is the JavaScript string value [v] as a [jstr] value. *)

external of_jstr : Jstr.t -> t = "%identity"
(** [of_jstr v] is the [jstr] value [v] as a JavaScript value. *)

(** [Jstr] object properties. *)
module Jstr : sig

  val find : t -> prop -> Jstr.t option
  (** [find o p] is [find_map of_jstr Jv.find o p]. {b This is
      unsafe}, only use if you know that if [o] defines [p] it is
      guaranteed to be a JavaScript string. *)

  val get : t -> prop -> Jstr.t
  (** [get o p] is [of_jv (Jv.get o p)]. {b This is unsafe}, only use
      if you know [o] has [p] and it is guaranteed to be a JavaScript
      string. *)

  val set : t -> prop -> Jstr.t -> unit
  (** [set o p b] is [Jv.set o p (to_jv b)]. *)

  val set_if_some : t -> prop -> Jstr.t option -> unit
  (** [set_if_some o p b] is [Jv.set_if_some o p (Option.map to_jv b)]. *)

  type t = Jstr.t
  (** Just here because we can't refer to the outer Jstr after
      this module definition. *)
end

(** {1:ocaml_jstr OCaml strings} *)

val of_string : string -> t
(** [of_string v] is a JavaScript string from the UTF-8 encoded
    OCaml string [v]. Shortcut for [of_jstr (Jstr.v v)]. *)

val to_string : t -> string
(** [to_string v] is an UTF-8 encoded OCaml string from the JavaScript
    string [v]. Shortcut for [Jstr.to_string (to_jstr v)]. *)

(** {1:arrays Arrays} *)

val is_array : jv -> bool
(** [is_array v] determines if [v] is a JavaScript array using the
    {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/isArray}
    Array.isArray} function. *)

val to_array : (t -> 'a) -> t -> 'a array
(** [to_array conv a] is an [array] value made of the JavaScript array
    [a] whose elements are converted with [conv]. *)

val of_array : ('a -> t) -> 'a array -> t
(** [of_array conv a] is a JavaScript [Array] value made of the
    [array] value [a] whose element are converted to JavaScript values
    with [conv]. *)

val to_list : (t -> 'a) -> t -> 'a list
(** [to_list conv a] is a [list] value made of the JavaScript array
    [a] whose elements are converted with [conv]. *)

val of_list : ('a -> t) -> 'a list -> t
(** [of_list conv l] is the JavaScript [Array] value made of the
    [list] value [l] whose element are converted to JavaScript values
    with [conv]. *)

(** {2:array_special Specialized conversions}

    Can be faster. *)

external to_jv_array : t -> t array = "caml_js_to_array"
(** [to_jv_array] is [to_array Fun.id]. *)

external of_jv_array : t array -> t = "caml_js_from_array"
(** [of_jv_array] is [of_array Fun.id]. *)

external to_jv_list : t -> t list = "caml_list_of_js_array"
(** [to_jv_list a] is [to_list Fun.id]. *)

external of_jv_list : t list -> t = "caml_list_to_js_array"
(** [of_jv_array a] is [of_list Fun.id]. *)

external to_jstr_array : t -> Jstr.t array = "caml_js_to_array"
(** [to_jstr_array] is [to_array to_jstr]. *)

external of_jstr_array : Jstr.t array -> t = "caml_js_from_array"
(** [of_jstr_array a] is [of_array of_jstr]. *)

external to_jstr_list : t -> Jstr.t list = "caml_list_of_js_array"
(** [to_jv_array a] is [a] as [list] of JavaScript values. *)

external of_jstr_list : Jstr.t list ->  t = "caml_list_to_js_array"
(** [of_jv_array a] is [a] as a JavaScript array of JavaScript values. *)

(** {2:jarr JavaScript array manipulation} *)

(** JavaScript arrays. *)
module Jarray : sig

  (** {1:arrays Arrays} *)

  type t = jv
  (** The type for JavaScript arrays. *)

  val create : int -> t
  (** [create n] is an array of length [n]. *)

  val length : t -> int
  (** [length a] is the array length. *)

  (** {1:access Accessors} *)

  external get : t -> int -> t = "caml_js_get"
  (** [get a i] is the value of array [a] at index [i]. *)

  external set : t -> int -> t -> unit = "caml_js_set"
  (** [set a i] sets the value of array [a] at index [i] to [v]. *)
end

(** {1:functions Functions} *)

external apply : t -> t array -> t = "caml_js_fun_call"
(** [apply f args] calls function [f] with arguments [args].
    {{!page-ffi_manual.funcs}Lookup} functions names in the {!Jv.global}
    object. *)

external callback : arity:int -> (_ -> _) -> t = "caml_js_wrap_callback_strict"
(** [callback ~arity f] makes function [f] with arity [arity] callable
    from JavaScript. *)

module Function : sig
  type _ args =
    | [] : jv args
    | (::) : (string * ('a -> jv)) * 'b args -> ('a -> 'b) args

  val v : ?global:t -> args:('a args) -> body:Jstr.t -> 'a
  (** Creates a function with the given body. For instance:

      {[
        let body = Jstr.v "console.log(x, y + 2) ; return x" in
        let args = Function.[("x", of_string) ; ("y", of_int)] in
        let f = Function.v ~body ~args in
        f "Hello" 42
      ]}
  *)

end

(** {1:exns Errors and exceptions} *)

(** Error objects. *)
module Error : sig

  type enum =
  [ `Abort_error | `Constraint_error | `Data_clone_error | `Data_error
  | `Encoding_error | `Hierarchy_request_error | `Index_size_error
  | `Invalid_access_error | `Invalid_character_error
  | `Invalid_modification_error | `Invalid_node_type_error
  | `Invalid_state_error | `Namespace_error | `Network_error
  | `No_modification_allowed_error | `Not_allowed_error | `Not_found_error
  | `Not_readable_error | `Not_supported_error | `Operation_error
  | `Quota_exceeded_error | `Read_only_error | `Security_error
  | `Syntax_error | `Timeout_error | `Transaction_inactive_error
  | `Type_mismatch_error | `Url_mismatch_error | `Unknown_error
  | `Version_error | `Wrong_document_error
  | `Other (** If not listed. {b Do not match on this !} *) ]
  (** The type for a selection of
      {{:https://developer.mozilla.org/en-US/docs/Web/API/DOMException#Error_names}
      DOMException error names}.
      Do not match on [`Other] if your error is not listed,
      use a {b catch all} [_] branch and consult {!name}. This makes
      sure you code will work correctly if new cases are added in the
      future. *)

  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error}[Error]} objects. *)

  val v : ?name:Jstr.t -> Jstr.t -> t
  (** [v ~name msg] is an error with message [msg] and name [name]
      (defaults to ["Error"]). *)

  (** {1:props Properties} *)

  val name : t -> Jstr.t
  (** [name e] is the exception name as a string. *)

  val enum : t -> enum
  (** [enum e] is [name e] parsed into the {!type-enum} type. *)

  val message : t -> Jstr.t
  (** [msg exn] is the exception message as a string. *)

  val stack : t -> Jstr.t
  (** [stack v] is the stack trace as a string. This
      includes [name] and [message]. *)
end

external of_error : Error.t -> t = "%identity"
(** [of_error e] is [e] as a JavaScript value. *)

external to_error : t -> Error.t = "%identity"
(** [to_error v] is [v] as a JavaScript error. *)

exception Error of Error.t
(** This OCaml exception represents any exception thrown by JavaScript
    code that is an instance of the Error exception. You should match
    on this exception in OCaml code to catch JavaScript exceptions. *)

val throw : ?name:Jstr.t -> Jstr.t -> 'a
(** [throw ?name msg] throws a JavaScript exception with error object
    {!Jv.Error.v} [?name msg]. *)

(** {1:iterators Iterator protocol} *)

(** JavaScript iterator protocol. *)
module It : sig

  (** {1:result Iterator results} *)

  type result = jv
  (** The type for objects satisfying the
      {{:https://tc39.es/ecma262/#sec-iteratorresult-interface}IteratorResult}
      interface. *)

  val result_done : result -> bool
  (** [result_done r] is [true] iff [r] has a [done] property and its
      value is [true]. *)

  val result_value : result -> jv option
  (** [result_value r] is the [value] property of [r] (if any).
      This may only be [None] if [result_done r] is [true]. *)

  val get_result_value : result -> jv
  (** [get_result_value r] is the [value] property of [r]. This
      should always be well defined as long as [result_done r] is [false]. *)

  (** {1:iterators Iterators} *)

  type t = jv
  (** The type for objects satisfying the
      {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#The_iterator_protocol}iterator protocol}. *)

  val iterable : jv -> t option
  (** [iterable v] is [v]'s iterator object (if any) looked up according to
      the {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols#The_iterable_protocol}iterable protocol}. *)

  val iterator : jv -> t
  (** [iterator jv] is [Option.get (iterable jv)]. *)

  val next : t -> result
  (** [next it] is the next result of iterator [it]. *)

  val fold : (jv -> 'a) -> ('a -> 'b -> 'b) -> t -> 'b -> 'b
  (** [fold of_jv f it] folds [f] over the results provided by [it]
      and converted with [of_jv] until one is [done]. The return value of
      the iterator is ignored. *)

  val fold_bindings :
    key:(jv -> 'a) -> value:(jv -> 'b) ->
    ('a -> 'b -> 'c -> 'c) -> t -> 'c -> 'c
  (** [fold_bindings] is like {!fold} except it assumes the iterator
      values are two-element arrays whose values are directly given to
      [f] in order. The return value of the iterator is ignored. *)
end

(** {1:promises Promises} *)

(** JavaScript promise support.

    In bindings do not use this directly use {!Fut}. *)
module Promise : sig

  type t = jv
  (** The type for JavaScript promises. *)

  val create : (('a -> unit) -> ('b -> unit) -> unit) -> t
  (** [create (fun res rej -> ...)] is a promise that can be resolved
      with [res] and rejected with [rej]. Note that [res] has a weird
      semantics see {!resolve} for details. *)

  val resolve : 'a -> t
  (** [resolve v] is a promise that resolve with [v]. {b Warning.}
      this is not a monadic [return] it also [join]s. Use {!Fut}
      for a sound typed semantics of promises. *)

  val reject : 'a -> t
  (** [reject v] is a promise that rejects with [v]. *)

  val await : t -> ('a -> unit) -> unit
  (** [await p k] waits for [p] to {e resolve} and continues with
      [k]. *)

  val bind : t -> ('a -> t) -> t
  (** [bind p fn] binds [p]'s resolution to function [fn]. *)

  val then' : t -> ('a -> t) -> ('b -> t) -> t
  (** [then' p res rej] binds [p]'s resolution to [res] and [p]'s
      rejection to [rej]. *)

  val all : jv -> t
  (** [all arr] is a promise that resolves all the promises in the
      array [arr] to an array of values. *)
end

(** {1:unicode JavaScript Unicode identifiers}

    The functions above only work with US-ASCII OCaml string literals.
    If you hit general Unicode identifiers create JavaScript strings
    representing them with [Jstr.v] and use the following functions. *)

type prop' = Jstr.t
(** The type for full Unicode JavaScript object property names. *)

external get' : t -> prop' -> t = "caml_js_get"
(** [get' o p] is the property [p] of [o]. {b Warning}, the result can
      be {!null} or {!undefined}. See also {!find}. *)

external set' : t -> prop' -> t -> unit = "caml_js_set"
(** [se't o p v] sets property [p] of [o] to the value [v]. *)

external delete' : t -> prop' -> unit = "caml_js_delete"
(** [delete' o p] deletes property [p] of [o]. The property [p] or [o]
      becomes {!undefined}. *)

val find' : t -> prop' -> t option
(** [find' p o] is property [p] of [o]. If the property is {!null} or
     {!undefined}, the result is [None]. See also {!get'}. *)

val find_map' : (t -> 'a) -> t -> prop' -> 'a option
(** [find_map' f p o] is Option.map f (find' p o). *)

val obj' : (prop' * t) array -> t
(** [obj props] is an object with properties [prop]. *)

val call' : t -> Jstr.t -> t array -> 'a
(** [call' o m args] calls method [m] on [o] with arguments [m]. [m]
    must be a JavaScript string. *)

(** {1:debugger Entering the debugger} *)

external debugger : unit -> unit = "debugger"
(** [debugger ()] stops and enters the JavaScript debugger
    (if available). *)

(** {1:feature_detection Feature detection} *)

val has : string -> 'a -> bool
(** [has p v] tests whether [Jv.repr v] has a member or
    method [p] *)

val defined : 'a -> bool
(** [defined v] is [Jv.is_some (J.repr v)]. Tests whether [v] is
    neither null nor undefined. *)

(** {1:convert Conversion interface} *)

(** Abstract type conversion iterface.

    This interface can be used to provide conversion functions for
    {!Jv.t} and abstract OCaml types.  An identity implementation of
    the functions of this interface is provided by {!Id}.

    This is typically used to provide an escape hatch a bit more
    formal and controlled than {!Jv.repr} and {!Obj.magic}.
{[
module Mymodule : sig
  type t
  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end = struct
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
end
]}
*)
module type CONV = sig
  type t
  (** The abtract datatype. *)

  external to_jv : t -> jv = "%identity"
  (** [to_jv] reveals the JavaScript implementation. *)

  external of_jv : jv -> t = "%identity"
  (** [of_jv] hides the JavaScript implementation. Implementations
      usually do not guarantee type safety. *)
end

(** Identity implementation of {!CONV}. *)
module Id : sig
  external to_jv : 'a -> t = "%identity"
  (** See {!CONV.to_jv}. *)

  external of_jv : t -> 'a = "%identity"
  (** See {!CONV.of_jv}. *)
end
