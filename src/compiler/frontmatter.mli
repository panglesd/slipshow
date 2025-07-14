type resolved = [ `Resolved ]
type unresolved = [ `Unresolved ]

type 'a fm = {
  toplevel_attributes : Cmarkit.Attributes.t option;
  math_link : 'a option;
  theme : [ `Builtin of Themes.t | `External of string ] option;
  css_links : 'a list;
  dimension : (int * int) option;
}

(** We use this trick to only allow [string fm] and [Asset.t fm], but it is
    completely unnecessary and a flagrant example of useless over-engineering.
*)
type 'a t =
  | Unresolved : string fm -> unresolved t
  | Resolved : Asset.t fm -> resolved t

module Default : sig
  val dimension : int * int
  val toplevel_attributes : Cmarkit.Attributes.t
  val theme : [> `Builtin of Themes.t ]
end

val empty : resolved t

module String_to : sig
  (** This is used to convert each field from a string to its unresolved ocaml
      value. Used internally by {!extract}, but also externally by the CLI
      converters. *)

  val toplevel_attributes :
    string -> (Cmarkit.Attributes.t, [> `Msg of string ]) result

  val math_link : string -> string
  val theme : string -> [> `Builtin of Themes.t | `External of string ]
  val css_link : string -> string
  val dimension : string -> (int * int, [> `Msg of string ]) result
end

val of_yaml :
  [> `O of
     (string * [> `A of [> `String of string ] list | `String of string ]) list
  ] ->
  (unresolved t, [> `Msg of string ]) result

val extract : string -> (Yaml.value Yaml.res * string) option
val combine : resolved t -> resolved t -> resolved t
val resolve : unresolved t -> to_asset:(string -> Asset.t) -> resolved t
