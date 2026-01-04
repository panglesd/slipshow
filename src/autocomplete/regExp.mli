type t
(** A regular expression *)

include Jv.CONV with type t := t

type opts = Indices | Global | Ignore | Multiline | DotAll | Unicode | Sticky

val create : ?opts:opts list -> string -> t
(** Create a regular expression from a string. Internally this uses
    [new RegExp(s)] which
    {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp/RegExp}
    has it's own documentation}. Note we pass noo flags at the moment. *)

type result
(** The result of executing a regular expression search on a string *)

val get_full_string_match : result -> string
(** The matched text *)

val get_index : result -> int
(** 0-based index of the match in the string *)

val get_indices : result -> (int * int) list
(** Each entry is a substring match of [(start, end_)] *)

val get_substring_matches : result -> string list
(** The matches for the parennthetical capture groups *)

val exec : t -> string -> result option
(** [exec t s] using the regular expression [t] to execute a search for a match
    in a specified string [s]. *)

val exec' : t -> Jstr.t -> result option
(** Same as {!exec} only you can pass a {!Jstr.t} instead. *)
