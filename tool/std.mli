(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

type fpath = string

module Result : sig
  include module type of Result
  val to_failure : ('a, string) result -> 'a

  module Syntax : sig
    val (let*) : ('a, 'e) result -> ('a -> ('b, 'e) result) -> ('b, 'e) result
  end
end

module Log : sig
  val err : ('a, Format.formatter, unit, unit) format4 -> 'a
  val warn : ('a, Format.formatter, unit, unit) format4 -> 'a
  val on_error : use:'a -> ('b, string) result -> ('b -> 'a) -> 'a
end

module Label_resolver : sig
  val v : quiet:bool -> Cmarkit.Label.resolver
end

module Os : sig
  val read_file : fpath -> (string, string) result
  val write_file : fpath -> string -> (unit, string) result
  val with_tmp_dir : (fpath -> 'a) -> ('a, string) result
  val with_cwd : fpath -> (unit -> 'a) -> ('a, string) result
end

module Exit : sig
  type code = Cmdliner.Cmd.Exit.code
  val err_file : code
  val err_diff : code
  val exits : Cmdliner.Cmd.Exit.info list
  val exits_with_err_diff : Cmdliner.Cmd.Exit.info list
end

val process_files : (file:fpath -> string -> 'a) -> string list -> Exit.code

module Cli : sig
  open Cmdliner

  val accumulate_defs : bool Term.t
  val backend_blocks : doc:string -> bool Term.t
  val docu : bool Term.t
  val files : string list Term.t
  val heading_auto_ids : bool Term.t
  val lang : string Term.t
  val no_layout : bool Term.t
  val quiet : bool Term.t
  val safe : bool Term.t
  val strict : bool Term.t
  val title : string option Term.t

  val common_man : Manpage.block list
end
