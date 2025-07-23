(*---------------------------------------------------------------------------
   Copyright (c) 2018 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

type level = Quiet | App | Error | Warning | Info | Debug
let _level = ref Debug
let level () = !_level
let set_level l = _level := l

type ('a, 'b) msgf =
  (?header:string -> ('a, Format.formatter, unit, 'b) format4 -> 'a) -> 'b

type 'a log = ('a, unit) msgf -> unit
type kmsg = { kmsg : 'a 'b. (unit -> 'b) -> level -> ('a, 'b) msgf -> 'b }

let pp_header ppf = function
| None -> ()
| Some v -> Format.fprintf ppf "[%s] " v

let console : level -> string -> unit =
  fun level s ->
  let meth = match level with
  | Error -> "error"
  | Warning -> "warn"
  | Info -> "info"
  | Debug -> "debug"
  | App -> "log"
  | Quiet -> assert false
  in
  ignore @@ Jv.call Brr.Console.(to_jv (get ())) meth [| Jv.of_string s |]


let report level k msgf =
  msgf @@ fun ?header fmt ->
  let k str = console level str; k () in
  Format.kasprintf k ("%a@[" ^^ fmt ^^ "@]@.") pp_header header

let nop_kmsg =
  let kmsg k level msgf = k () in
  { kmsg }

let default_kmsg =
  let kmsg k level msgf = match !_level with
  | Quiet -> k ()
  | level' when level > level' -> k ()
  | _ -> report level k msgf
  in
  { kmsg }

let _kmsg = ref default_kmsg
let set_kmsg kmsg = _kmsg := kmsg

let kunit _ = ()
let msg level msgf = !_kmsg.kmsg kunit level msgf
let app msgf = !_kmsg.kmsg kunit App msgf
let err msgf = !_kmsg.kmsg kunit Error msgf
let warn msgf = !_kmsg.kmsg kunit Warning msgf
let info msgf = !_kmsg.kmsg kunit Info msgf
let debug msgf = !_kmsg.kmsg kunit Debug msgf
let kmsg k level msgf = !_kmsg.kmsg k level msgf
