(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* open Brr *)

(* Poke objects

   A poke object is a JavaScript object with the following members and
   types.

   type poke =
   { ocaml_version : Jstr.t;
     jsoo_version : Jstr.t;
     init : unit -> unit; (* Raises Jv.Error *)
     eval : Jstr.t -> Jstr.t; (* Raises Jv.Error *)
     use : Jstr.t -> Jstr.t.t; (* Riases Jv.Error *) }

   The type [t] is how we interact with it after we found, either
   in the current global context or in another one in case of the
   web extension. *)

let poke_version = 0
type t =
  { version : int;
    ocaml_version : Jstr.t;
    jsoo_version : Jstr.t;
    eval : Jstr.t -> Brr.Json.t Fut.or_error;
    use : Jstr.t -> Brr.Json.t Fut.or_error; }

let version p = p.version
let ocaml_version p = p.ocaml_version
let jsoo_version p = p.jsoo_version
let eval p = p.eval
let use p = p.use

let err_version version =
  Jstr.(v "Page poke version mismatch. Should be v" +
        of_int poke_version + v " but found v" + of_int version +
        v ".\n\nTry to upgrade the OCaml console web extension to the \
           latest version.")

let err_miss_prop p =
  Jstr.(v "Page poke property ocaml_poke." + v p + v " is missing.")

let find () = match Jv.find Jv.global "ocaml_poke" with
| None -> Fut.ok None
| Some o ->
    try
      let get p o = match Jv.find o p with
      | None -> Jv.throw (err_miss_prop p) | Some v -> v
      in
      let version = Jv.to_int (get "version" o) in
      if version > poke_version then Jv.throw (err_version version) else
      let ocaml_version = Jv.to_jstr (get "ocaml_version" o) in
      let jsoo_version = Jv.to_jstr (get "jsoo_version" o) in
      let eval = get "eval" o in
      let eval s = try Fut.ok (Jv.apply eval [| Jv.of_jstr s |]) with
      | Jv.Error e -> Fut.error e
      in
      let use = get "use" o in
      let use s = try Fut.ok (Jv.apply use [| Jv.of_jstr s |]) with
      | Jv.Error e -> Fut.error e
      in
      let () = ignore (Jv.apply (get "init" o) [||]) in
      Fut.ok (Some { version;  ocaml_version; jsoo_version; eval; use })
    with Jv.Error e -> Fut.error e

let find_eval'd ~eval:js_eval =
  let open Fut.Result_syntax in
  let* undef = js_eval (Jstr.v "globalThis.ocaml_poke == undefined") in
  if Jv.to_bool undef then Fut.ok None else
  let get to_t prop =
    let* v = js_eval Jstr.(v "ocaml_poke." + v prop) in
    match Jv.to_option to_t v with
    | None -> Fut.error (Jv.Error.v (err_miss_prop prop))
    | Some v -> Fut.ok v
  in
  let* version = get Jv.to_int "version" in
  if version > poke_version
  then Fut.error (Jv.Error.v (err_version version)) else
  let* ocaml_version = get Jv.to_jstr "ocaml_version" in
  let* jsoo_version = get Jv.to_jstr "jsoo_version" in
  let eval s =
    let ocaml = Brr.Json.encode (* escapes properly *) (Jv.of_jstr s) in
    let expr = Jstr.(v "ocaml_poke.eval (" + ocaml + Jstr.v ")") in
    (js_eval expr)
  in
  let use s =
    let ocaml = Brr.Json.encode (* escapes properly *) (Jv.of_jstr s) in
    let expr = Jstr.(v "ocaml_poke.use (" + ocaml + Jstr.v ")") in
    (js_eval expr)
  in
  let* _unit = js_eval (Jstr.v "ocaml_poke.init ()") in
  Fut.ok (Some { version; ocaml_version; jsoo_version; eval; use })
