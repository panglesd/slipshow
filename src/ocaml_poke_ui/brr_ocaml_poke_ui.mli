(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Interactive toplevel HTML interface for poke objects. *)

open Brr

(** {1:storage Persistent storage} *)

(** Persistent storage.

    Basic interface to abstract over {!Brr_io.Storage}
    and {{:https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/storage}Web extension storage}. *)
module Store : sig
  type t
  (** The type for persistent storage. *)

  val create :
    get:(Jstr.t -> Jstr.t option Fut.or_error) ->
    set:(Jstr.t -> Jstr.t -> unit Fut.or_error) -> t
  (** [store] is a store with given [get] and [set] functions. *)

  val page : ?key_prefix:Jstr.t -> Brr_io.Storage.t -> t
  (** [local_store] is a store that uses {!Brr_io.Storage.local}, with
      keys prefixed by [key_prefix] (defaults to ["ocaml-repl-"]). *)

  val webext : ?key_prefix:Jstr.t -> unit -> t
  (** [webext_store] is a store using the
      {{:https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/storage}Web extension} storage. The ["storage"] premission must be
      added to the manifest. *)

  val get : t -> Jstr.t -> Jstr.t option Fut.or_error
  (** [get s k] is the value of key [k] in [s] (if any). *)

  val set : t -> Jstr.t -> Jstr.t -> unit Fut.or_error
  (** [set s k v] sets the value of [k] in [s] to [v]. *)
end

(** {1:prompt_history Prompt history} *)

(** Prompt history data structure. *)
module History : sig

  type t
  (** The type for prompt histories. *)

  val v : prev:Jstr.t list -> t
  (** [v ~prev] initializes the toplevel with previous entries
      [prev] (later elements are older). *)

  val empty : t
  (** [empty] is an empty history. *)

  val entries : t -> Jstr.t list
  (** [entries h] are all the entries in the history. *)

  val add : t -> Jstr.t -> t
  (** [add h e] makes adds entry [v] to history. *)

  val restart : t -> t
  (** [restart] *)

  val prev : t -> Jstr.t -> (t * Jstr.t) option
  (** [prev h current] makes [current] the next entry of the resulting history
      and returns the previous entry of [h] (if any). *)

  val next : t -> Jstr.t -> (t * Jstr.t) option
  (** [next h current] makes [current] the previous entry of the resulting
      history and returns the next entry of [h] (if any). *)

  val to_string : sep:Jstr.t -> t -> Jstr.t
  (** [to_string ~sep t] is a string with the entries of [t] separated
      by {e lines} that contain [sep]. *)

  val of_string : sep:Jstr.t -> Jstr.t -> t
  (** [of_string ~sep s] is history from [s] assumed to be entries seperated
      by {e lines} that contain [sep]. *)
end

(** {1:toplevel Toplevel user interface} *)

type t
(** The type for representing a toplevel user interface over a poke
    object. *)

val create : ?store:Store.t -> El.t -> t Fut.or_error
(** [create ~store view] creates a toplevel interface using the
    children of the [view] element whose content model should be flow
    content.  [view]'s children are erased and the class [.ocaml-ui]
    is set on element. [store] is used to store the toplevel history
    and user settings. *)

type output_kind =
  [ `Past_input | `Reply | `Warning | `Error | `Info | `Announce ]
(** The type for specifiyng kinds of output messages. *)

val output : t -> kind:output_kind -> El.t list -> unit
(** [output r ~kind msg] outputs message [msg] with [kind] to the
    user interface. *)

val run :
  ?drop_target:Ev.target -> ?buttons:El.t list -> t -> Brr_ocaml_poke.t -> unit
(** [run t poke ~drop_target ~buttons] runs the toplevel with poke
    object [poke]. [buttons] are prepended to the buttons
    panel. [drop_target] is the target on which ml files can be droped
    (defaults to the view). *)
