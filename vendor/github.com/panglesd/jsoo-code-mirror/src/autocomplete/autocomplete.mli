open Code_mirror

(** Most of this documention originate from the code-mirror reference.

  {{:https://codemirror.net/6/docs/ref/#autocomplete} Visit the
  reference directly for additional information.}  *)

val autocomplete : Jv.t
(** Global autocomplete value *)

module RegExp = RegExp

module Completion : sig
  (** Represents individual completions. *)

  type t
  (** Completion *)

  include Jv.CONV with type t := t

  val create :
    label:string ->
    ?detail:string ->
    ?info:string ->
    ?apply:t ->
    ?type_:string ->
    ?boost:int ->
    unit ->
    t
  (** Creates a completion.

    @param label The label to show in the completion picker.
    @param detail An optional short piece of information to show after the
    label.
    @param info Additional info to show when the completion is selected.
    @param apply (todo) How to apply the completion.
    @param type     The type of the completion. This is used to pick an icon to
    show for the completion.
    @param boost

    {{:https://codemirror.net/6/docs/ref/#autocomplete.Completion} See the
    reference for additional information.} *)
end

module Context : sig
  (** An instance of this is passed to completion source functions. *)

  type t
  (** Completion context *)

  include Jv.CONV with type t := t

  val state : t -> Editor.State.t
  (** The editor state that the completion happens in. *)

  val pos : t -> int
  (** The position at which the completion is happening. *)

  val explicit : t -> bool
  (** Indicates whether completion was activated explicitly, or implicitly by
    typing. The usual way to respond to this is to only return completions when
    either there is part of a completable entity before the cursor, or explicit
    is true. *)

  val token_before : t -> string list -> Jv.t option
  (** Get the extent, content, and (if there is a token) type of the token
    before this.pos. *)

  val match_before : t -> RegExp.t -> Jv.t option
  (** Get the match of the given expression directly before the cursor. *)

  val aborted : t -> bool
  (** Yields true when the query has been aborted. Can be useful in
    asynchronous queries to avoid doing work that will be ignored. *)
end

module Result : sig
  (** Objects returned by completion sources. *)

  type t
  (** Completion result *)

  include Jv.CONV with type t := t

  val create :
    from:int ->
    ?to_:int ->
    options:Completion.t list ->
    ?span:RegExp.t ->
    ?filter:bool ->
    unit ->
    t
  (** Creating a new completion result (see {{: https://codemirror.net/6/docs/ref/#autocomplete.CompletionResult} the docs}).
    @param from The start of the range that is being completed.
    @param to_ The end of the range that is being completed. Defaults to the
      main cursor position.
    @param options The completions returned.
    @param span When given, further input that causes the part of the document
      between [from] and [to_] to match this regular expression will not query
      the completion source again
    @param filter By default, the library filters and scores completions. Set
      filter to false to disable this, and cause your completions to all be
      included, in the order they were given.
  *)
end

module Source : sig
  type t
  (** Completion source *)

  include Jv.CONV with type t := t

  val create : (Context.t -> Result.t option Fut.t) -> t

  val from_list : Completion.t list -> t
  (** Given a a fixed array of options, return an autocompleter that completes
    them. *)
end

type config

val config :
  ?activate_on_typing:bool ->
  ?override:Source.t list ->
  ?max_rendered_options:int ->
  ?default_key_map:bool ->
  ?above_cursor:bool ->
  ?option_class:Jv.t ->
  ?icons:bool ->
  ?add_to_options:Jv.t ->
  unit ->
  config
(** Configuration options for your autocompleter, see {{: https://codemirror.net/6/docs/ref/#autocomplete.autocompletion^config} the online docs}.*)

val create : ?config:config -> unit -> Code_mirror.Extension.t
(** Autocompleter *)
