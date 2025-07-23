(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** [ocaml_poke] object for OCaml console.

    See the {{!page-ocaml_console}OCaml console manual}
    for more information. *)

(** {1:poke Poke objects} *)

type t
(** The type for OCaml poke objects. Note that the actual object
    may live in another global context. *)

val version : t -> int
(** [version p] is the version of the poke object interface. *)

val ocaml_version : t -> Jstr.t
(** [ocaml_version p] is the OCaml version being poked by [p]. *)

val jsoo_version : t -> Jstr.t
(** [jsoo_version p] is the [js_of_ocaml] version being poked by [p]. *)

val eval : t -> Jstr.t -> Brr.Json.t Fut.or_error
(** [eval expr] evaluates the given OCaml toplevel phrase in the poke
    object and returns the result as a JSON string. *)

val use : t -> Jstr.t -> Brr.Json.t Fut.or_error
(** [use phrases] silently evaluates the given OCaml toplevel phrases in
    the poke object and returns possible errors via a JSON string. *)

(** {1:finding Finding poke objects} *)

val find : unit -> t option Fut.or_error
(** [find ()] looks for and initalizes an OCaml poke object in the global
    context of the caller. *)

val find_eval'd :
  eval:(Jstr.t -> Brr.Json.t Fut.or_error) -> t option Fut.or_error
(** [find_eval'd] looks for and initializes an OCaml poke object by using
    the given JavaScript [eval] function. *)
