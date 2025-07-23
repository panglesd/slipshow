(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* Mini Jv, this allows us to use Jstr in Jv *)

type jv
external jv_call : jv -> string -> jv array -> 'a = "caml_js_meth_call"
external jv_apply : jv -> jv array -> 'a = "caml_js_fun_call"
external jv_get : jv -> string -> jv = "caml_js_get"
external jv_of_int : int -> jv = "%identity"
external jv_to_int : jv -> int = "%identity"
external jv_of_float : float -> jv = "caml_js_from_float"
external jv_to_float : jv -> float = "caml_js_to_float"
external jv_to_bool : jv -> bool = "caml_js_to_bool"
external jv_pure_js_expr : string -> 'a = "caml_pure_js_expr"
let jv_global = jv_pure_js_expr "globalThis"

(* Strings *)

type t = jv
external jv_to_jstr_list : jv -> t list = "caml_list_of_js_array"
external jv_of_jstr_list : t list -> jv = "caml_list_to_js_array"
external v : string -> t = "caml_jsstring_of_string"
let length s = jv_to_int (jv_get s "length")

external jstr_to_string : t -> string = "caml_string_of_jsstring"
let jstr_of_int ?(base = 10) i =
  jv_call (jv_of_int i) "toString" [| jv_of_int base |]

let err_bounds i len =
  let ( + ) s0 s1 = jv_call s0 "concat" [| s1 |] in
  jstr_to_string @@
  v "index " + jstr_of_int i + v " not in bounds [0;" +
  jstr_of_int (len - 1) + v "]"

let get s i =
  if i >= length s then invalid_arg (err_bounds i (length s)) else
  let u = jv_to_int (jv_call s "codePointAt" [|jv_of_int i|]) in
  let u = if u < 0xD800 || u > 0xDFFF then u else 0xFFFD (* Uchar.rep *) in
  Uchar.unsafe_of_int u

let jstr_of_uchar_int i =
  jv_call (jv_get jv_global "String") "fromCodePoint" [| jv_of_int i |]

let get_jstr s i = jstr_of_uchar_int (Uchar.to_int (get s i))

(* Constants *)

let empty = v ""
let sp = v " "
let nl = v "\n"

(* Assembling *)

let append s0 s1 = jv_call s0 "concat" [| s1 |]
let ( + ) = append
let concat ?(sep = empty) ss = jv_call (jv_of_jstr_list ss) "join" [| sep |]
let pad_start ?(pad = sp) len s = jv_call s "padStart" [| jv_of_int len; pad |]
let pad_end ?(pad = sp) len s = jv_call s "padEnd" [| jv_of_int len; pad |]
let repeat n s = jv_call s "repeat" [| jv_of_int n |]

(* Finding *)

let find_sub ?(start = 0) ~sub s =
  let i = jv_to_int (jv_call s "indexOf" [| sub; jv_of_int start |]) in
  if i = -1 then None else Some i

let find_last_sub ?before ~sub s =
  let before = match before with None -> length s | Some b -> b in
  let pos = before - length sub in
  if pos < 0 then None else
  let i = jv_to_int (jv_call s "lastIndexOf" [|sub; jv_of_int pos|]) in
  if i = -1 then None else Some i

(* Breaking *)

let slice ?(start = 0) ?stop s =
  let args = match stop with
  | None -> [| jv_of_int start |]
  | Some stop -> [| jv_of_int start; jv_of_int stop |]
  in
  jv_call s "slice" args

let sub ?(start = 0) ?len s =
  let args = match len with
  | None -> [| jv_of_int start |]
  | Some len -> [| jv_of_int start; jv_of_int len |]
  in
  jv_call s "substr" args

let cuts ~sep s = jv_to_jstr_list (jv_call s "split" [| sep |])

(* Traversing and transforming *)

let iterator : jv = jv_pure_js_expr "Symbol.iterator"
external get_symbol : jv -> jv -> jv = "caml_js_get"

let fold_uchars f s acc =
  let rec loop it acc =
    let r = jv_call it "next" [||] in
    if jv_to_bool (jv_get r "done") then acc else
    let u = jv_call (jv_get r "value") "codePointAt" [| jv_of_int 0 |] in
    let u = if u < 0xD800 || u > 0xDFFF then u else 0xFFFD (* Uchar.rep *) in
    loop it (f (Uchar.unsafe_of_int u) acc)
  in
  loop (jv_apply (get_symbol s iterator) [||]) acc

let fold_jstr_uchars f s acc =
  let f' u acc = f (jstr_of_uchar_int (Uchar.to_int u)) acc in
  fold_uchars f' s acc

let trim s = jv_call s "trim" [||]

(* Normalization *)

type normalization = [ `NFD | `NFC | `NFKD | `NFKC ]

let normalized nf s =
  let nf = match nf with
  | `NFD -> v "NFD" | `NFC -> v "NFC" | `NFKD -> v "NFKD" | `NFKC -> v "NFKC"
  in
  jv_call s "normalize" [| nf |]

(* Case mapping *)

let lowercased s = jv_call s "toLowerCase" [||]
let uppercased s = jv_call s "toUpperCase" [||]

(* Predicates and comparisons *)

let is_empty s = length s = 0
let starts_with ~prefix s = jv_to_bool @@ jv_call s "startsWith" [| prefix |]
let includes ~affix s = jv_to_bool @@ jv_call s "includes" [| affix |]
let ends_with ~suffix s = jv_to_bool @@ jv_call s "endsWith" [| suffix |]
let equal = ( = )
let compare = compare

(* Conversions *)

let of_uchar u = jstr_of_uchar_int (Uchar.to_int u)
let of_char c = jstr_of_uchar_int (Char.code c)

external of_string : string -> t = "caml_jsstring_of_string"
external to_string : t -> string = "caml_string_of_jsstring"
external binary_to_octets : t -> string = "caml_string_of_jsbytes"
external binary_of_octets : string -> t = "caml_jsbytes_of_string"

let number = jv_get jv_global "Number"

let of_int = jstr_of_int
let to_int ?base s =
  let args = match base with None -> [| s |] | Some b -> [| s; jv_of_int b |] in
  let n = jv_call number "parseInt" args in
  if not (n = n) then (* NaN *) None else Some (jv_to_int n)

let to_float s = jv_to_float @@ jv_call number "parseFloat" [| s |]
let of_float ?frac n = match frac with
| None -> jv_call (jv_of_float n) "toString" [||]
| Some frac -> jv_call (jv_of_float n) "toFixed" [|jv_of_int frac|]
