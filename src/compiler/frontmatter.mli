type resolved = [ `Resolved ]
type unresolved = [ `Unresolved ]

type 'a fm = {
  toplevel_attributes : Cmarkit.Attributes.t option;
  math_link : 'a option;
  theme : [ `Builtin of Themes.t | `External of string ] option;
  css_links : 'a list;
  js_links : 'a list;
  dimension : (int * int) option;
  highlightjs_theme : string option;
  math_mode : [ `Mathjax | `Katex ] option;
  external_ids : string list;
}

(** We use this trick to only allow [string fm] and [Asset.t fm], but it is
    completely unnecessary and a flagrant example of useless over-engineering.
*)
type 'a t =
  | Unresolved : string fm -> unresolved t
  | Resolved : Asset.t fm -> resolved t

module type Field = sig
  type t

  val key : string
  val of_string : string -> (t, [ `Msg of string ]) result
  val update_frontmatter : string fm -> t -> string fm
end

module type Field_with_default := sig
  include Field

  val default : t
end

module Toplevel_attributes :
  Field_with_default with type t = Cmarkit.Attributes.t

module Math_link : Field with type t = string

module Theme :
  Field_with_default with type t = [ `Builtin of Themes.t | `External of string ]

module Css_links : Field with type t = string list
module Js_links : Field with type t = string list
module Dimension : Field_with_default with type t = int * int
module Hljs_theme : Field_with_default with type t = string
module Math_mode : Field_with_default with type t = [ `Mathjax | `Katex ]

val empty : resolved t
val of_string : string -> int -> string -> unresolved t

val extract : string -> (string * string * (int * int) * int) option
(** The first string is the frontmatter, the second one the original string with
    the frontmatter and separator stripped *)

val combine : resolved t -> resolved t -> resolved t
val resolve : unresolved t -> to_asset:(string -> Asset.t) -> resolved t
