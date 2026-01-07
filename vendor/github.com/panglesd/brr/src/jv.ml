(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

external pure_js_expr : string -> 'a = "caml_pure_js_expr"
external js_expr : string -> 'a = "caml_js_expr"

(* Values *)

type t
type jv = t

external equal : t -> t -> bool = "caml_js_equals"
external strict_equal : t -> t -> bool = "caml_js_strict_equals"
external typeof : t -> Jstr.t = "caml_js_typeof"
external instanceof : t -> cons:t -> bool = "caml_js_instanceof"
external repr : 'a -> t = "%identity"

(* Null and undefined *)

let null = pure_js_expr "null"
let undefined = pure_js_expr "undefined"
let is_null v = strict_equal v null
let is_undefined v = strict_equal v undefined
let is_none v = is_null v || is_undefined v
let is_some v = not (is_none v)
let to_option conv v = if is_none v then None else Some (conv v)
let of_option ~none conv = function None -> none | Some v -> conv v

(* Objects *)

let global = pure_js_expr "globalThis"

(* Properties *)

type prop = string

external get : t -> prop -> t = "caml_js_get"
external set : t -> prop -> t -> unit = "caml_js_set"
external delete : t -> prop -> unit = "caml_js_delete"
let set_if_some o p = function None -> () | Some v -> set o p v
let find o p = let v = get o p in if is_none v then None else Some v
let find_map f o p = let v = get o p in if is_none v then None else Some (f v)
let rec find_path o = function
| [] -> Some o
| p :: ps -> match find o p with None -> None | Some o -> find_path o ps

(* Creating *)

external obj : (prop * t) array -> t = "caml_js_object"
external new' : t -> t array -> t = "caml_js_new"

(* Methods *)

external call : t -> string -> t array -> 'a = "caml_js_meth_call"

(* Booleans *)

let true' = pure_js_expr "true"
let false' = pure_js_expr "false"
external to_bool : t -> bool = "caml_js_to_bool"
external of_bool : bool -> t = "caml_js_from_bool"
module Bool = struct
  let find o p = let b = get o p in if is_none b then None else Some (to_bool b)
  let get o p = to_bool (get o p)
  let set o p b = set o p (of_bool b)
  let set_if_some o p = function None -> () | Some b -> set o p b
end

(* Integers *)

external to_int : t -> int = "%identity"
external of_int : int -> t = "%identity"
module Int = struct
  let find o p = let i = get o p in if is_none i then None else Some (to_int i)
  let get o p = to_int (get o p)
  let set o p i = set o p (of_int i)
  let set_if_some o p = function None -> () | Some i -> set o p i
end

(* Floats *)

external to_float : t -> float = "caml_js_to_float"
external of_float : float -> t = "caml_js_from_float"
module Float = struct
  let find o p = let f = get o p in if is_none f then None else Some(to_float f)
  let get o p = to_float (get o p)
  let set o p b = set o p (of_float b)
  let set_if_some o p = function None -> () | Some f -> set o p f
end

(* Int32 *)

external to_int32 : t -> int32 = "caml_js_to_int32"
external of_int32 : int32 -> t = "caml_js_from_int32"
module Int32 = struct
  let find o p = let f = get o p in if is_none f then None else Some(to_int32 f)
  let get o p = to_int32 (get o p)
  let set o p b = set o p (of_int32 b)
  let set_if_some o p = function None -> () | Some f -> set o p f
end

(* Jstr *)

external to_jstr : t -> Jstr.t = "%identity"
external of_jstr : Jstr.t -> t = "%identity"
module Jstr = struct
  let find o p = let s = get o p in if is_none s then None else Some (to_jstr s)
  let get o p = to_jstr (get o p)
  let set o p b = set o p (of_jstr b)
  let set_if_some o p = function None -> () | Some f -> set o p f

  (* When do we get ../ ? *)
  type t = Jstr.t
  let to_string = Jstr.to_string
end

(* String *)

external of_string : string -> t = "caml_jsstring_of_string"
external to_string : t -> string = "caml_string_of_jsstring"

(* Arrays *)

let is_array jv = to_bool (call (get global "Array") "isArray" [| jv |])

module Jarray = struct
  type t = jv
  let create n = new' (get global "Array") [| of_int n |]
  let length a = to_int (get a "length")
  external get : t -> int -> t = "caml_js_get"
  external set : t -> int -> t -> unit = "caml_js_set"
end

let to_array conv v =
  let len = Jarray.length v in
  Array.init len (fun i -> conv (Jarray.get v i))

let of_array conv a =
  let len = Array.length a in
  let ja = Jarray.create len in
  for i = 0 to len - 1 do Jarray.set ja i (conv (Array.get a i)) done;
  ja

let to_list conv v =
  let len = Jarray.length v in
  List.init len (fun i -> conv (Jarray.get v i))

let of_list conv l =
  (* Should be benchmarked checking length of [l] first may be faster
       than extending the array repeatedly *)
  let rec loop i ja = function
  | [] -> ja
  | v :: vs -> Jarray.set ja i (conv v); loop (i + 1) ja vs
  in
  loop 0 (Jarray.create 0) l

external to_jv_array : t -> t array = "caml_js_to_array"
external of_jv_array : t array -> t = "caml_js_from_array"
external to_jv_list : t -> t list = "caml_list_of_js_array"
external of_jv_list : t list -> t = "caml_list_to_js_array"
external to_jstr_array : t -> Jstr.t array = "caml_js_to_array"
external of_jstr_array : Jstr.t array -> t = "caml_js_from_array"
external to_jstr_list : t -> Jstr.t list = "caml_list_of_js_array"
external of_jstr_list : Jstr.t list -> t = "caml_list_to_js_array"

(* Functions *)

external apply : t -> t array -> 'a = "caml_js_fun_call"
external callback : arity:int -> (_ -> _) -> t = "caml_js_wrap_callback_strict"

module Function = struct
  type _ args =
    | [] : jv args
    | (::) : (string * ('a -> jv)) * 'b args -> ('a -> 'b) args

  let rec args_to_list : type a. a args -> jv list =
    fun args ->
    match args with
    | [] -> []
    | (s, _conv) :: q -> of_string s :: args_to_list q

  let global' = global

  let v : type a . ?global:t -> args:(a args) -> body:Jstr.t -> a =
    fun ?(global) ~args ~body ->
    let global = Option.value global ~default:global' in
    let jstr_args = Array.of_list @@ args_to_list args @ [ of_jstr body ] in
    let res = new' (get global "Function") jstr_args in
    let rec c : type a. jv list -> a args -> a = fun args -> function
      | [] -> apply res (args |> List.rev |> Array.of_list)
      | (_, conv) :: q -> fun x -> c (conv x :: args) q in
    c [] args
end

(* Errors *)

module Error = struct
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
  | `Version_error | `Wrong_document_error | `Other ]

  type t = Jsoo_runtime.Error.t
  let v ?name msg : t =
    let e = new' (get global "Error") [| of_jstr msg |] in
    match name with
    | None -> Obj.magic e
    | Some n -> set e "name" (of_jstr n); Obj.magic e

  let name (e : t) = to_jstr (get (Obj.magic e) "name")
  let enum e = match to_string (get (Obj.magic e) "name") with
  | "AbortError" -> `Abort_error
  | "ConstraintError" -> `Constraint_error
  | "DataCloneError" -> `Data_clone_error
  | "DataError" -> `Data_error
  | "EncodingError" -> `Encoding_error
  | "HierarchyRequestError" -> `Hierarchy_request_error
  | "IndexSizeError" -> `Index_size_error
  | "InvalidAccessError" -> `Invalid_access_error
  | "InvalidCharacterError" -> `Invalid_character_error
  | "InvalidModificationError" -> `Invalid_modification_error
  | "InvalidNodeTypeError" -> `Invalid_node_type_error
  | "InvalidStateError" -> `Invalid_state_error
  | "NamespaceError" -> `Namespace_error
  | "NetworkError" -> `Network_error
  | "NoModificationAllowedError" -> `No_modification_allowed_error
  | "NotAllowedError" -> `Not_allowed_error
  | "NotFoundError" -> `Not_found_error
  | "NotReadableError" -> `Not_readable_error
  | "NotSupportedError" -> `Not_supported_error
  | "OperationError" -> `Operation_error
  | "QuotaExceededError" -> `Quota_exceeded_error
  | "ReadOnlyError" -> `Read_only_error
  | "SecurityError" -> `Security_error
  | "SyntaxError" -> `Syntax_error
  | "TimeoutError" -> `Timeout_error
  | "TransactionInactiveError" -> `Transaction_inactive_error
  | "TypeMismatchError" -> `Type_mismatch_error
  | "URLMismatchError" -> `Url_mismatch_error
  | "UnknownError" -> `Unknown_error
  | "VersionError" -> `Version_error
  | "WrongDocumentError" -> `Wrong_document_error
  | _ -> `Other

  let message e = to_jstr (get (Obj.magic e) "message")
  let stack e = to_jstr (get (Obj.magic e) "stack")
  let _to_result e = Error e
end

external of_error : Error.t -> t = "%identity"
external to_error : t -> Error.t = "%identity"

let throw ?name msg =
  let e = Error.v ?name msg in
  (js_expr "(function (exn) { throw exn })" : Error.t -> 'a) e

exception Error = Jsoo_runtime.Error.Exn

(* Iterable and iterator *)

module It = struct
  type t = jv
  type result = jv

  let symbol : jv = pure_js_expr "Symbol.iterator"
  external get_symbol : jv -> jv -> jv = "caml_js_get"

  let iterable o = match to_option Fun.id (get_symbol o symbol) with
  | None -> None | Some func -> apply func [||]

  let iterator o = apply (get_symbol o symbol) [||]

  let next it = call it "next" [||]

  let result_done o = match to_option to_bool (get o "done") with
  | None -> false | Some d -> d

  let result_value o = to_option Fun.id (get o "value")
  let get_result_value o = get o "value"

  let fold of_jv f it acc =
    let rec loop it acc =
      let r = next it in
      if result_done r then acc else
      loop it (f (of_jv (get_result_value r)) acc)
    in
    loop it acc

  let fold_bindings ~key ~value f it acc =
    let rec loop it acc =
      let r = next it in
      if result_done r then acc else
      let arr = get_result_value r in
      loop it (f (key (Jarray.get arr 0)) (value (Jarray.get arr 1)) acc)
    in
    loop it acc
end

(* Promises *)

module Promise = struct
  type t = jv
  let promise = get global "Promise"
  let create f =
    let g res rej =
      f (fun x -> apply res [|repr x|]) (fun x -> apply rej [|repr x|]) in
    new' promise [| callback ~arity:2 g |]
  let resolve v = call promise "resolve" [| repr v |]
  let reject v = call promise "reject" [| repr v |]
  let await p k = ignore (call p "then" [| callback ~arity:1 k |])
  let bind p res = call p "then" [| callback ~arity:1 res |]
  let then' p res rej =
    call p "then" [| callback ~arity:1 res; callback ~arity:1 rej|]

  let all arr = call promise "all" [| repr arr |]
end

(* Unicode identifiers *)

type prop' = Jstr.t
external get' : t -> prop' -> t = "caml_js_get"
external set' : t -> prop' -> t -> unit = "caml_js_set"
external delete' : t -> prop' -> unit = "caml_js_delete"
let find' o p = let v = get' o p in if is_none v then None else Some v
let find_map' f o p = let v = get' o p in if is_none v then None else Some (f v)

(* XXX the following were supposed to be direct call to externals like for
   the above but they are not implemented that way for now. See discussion here:
   https://github.com/ocsigen/js_of_ocaml/pull/997#issuecomment-694925765.
   It would likely need a bit of upstream cajoling to move on – OTOH
   these should end up being used pervasively. *)

let obj' props = obj (Array.map (fun (p, v) -> Jstr.to_string p, v) props)
let call' o m args = call o (Jstr.to_string m) args

(* Debugger *)

external debugger : unit -> unit = "debugger"

(* Feature detection *)

let has p v = is_some (get (repr v) p)
let defined v = is_some (repr v)

(* Conversion interface *)

module type CONV = sig
  type t
  external to_jv : t -> jv = "%identity"
  external of_jv : jv -> t = "%identity"
end

module Id = struct
  external to_jv : 'a -> t = "%identity"
  external of_jv : t -> 'a = "%identity"
end
