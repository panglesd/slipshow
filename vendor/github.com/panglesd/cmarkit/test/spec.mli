(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Specification test parser *)

val version : string

type test =
  { markdown : string;
    html : string;
    example : int;
    start_line : int;
    end_line : int;
    section : string }

val parse_tests : string -> (test list, string) result

val diff : spec:string -> string -> string

val ok : string B0_std.Fmt.t
val fail : string B0_std.Fmt.t
val cli : exe:string -> unit -> bool * string * int list
