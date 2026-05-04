module Local : sig
  type t = { toplevel_attributes : Cmarkit.Attributes.t Cmarkit.node option }
  type 'a with_ = { x : 'a; fm : t }

  val empty : t
  val with_empty : 'a -> 'a with_
end

module Global : sig
  type t = {
    math_link : Asset.t option;
    theme : [ `Builtin of Themes.t | `External of string ] option;
    dimension : (int * int) option;
    highlightjs_theme : string option;
    math_mode : [ `Mathjax | `Katex ] option;
    css_links : Asset.t list;
    js_links : Asset.t list;
    external_ids : string list;
  }

  type 'a with_ = { x : 'a; fm : t }

  val empty : t
  val with_empty : 'a -> 'a with_
  val combine : t -> t -> t
end

type t = { local : Local.t; global : Global.t }

val empty : t

type fm := t

module type Field := sig
  type t

  val key : string

  val of_string :
    to_asset:(string -> Asset.t) ->
    string * Cmarkit.Textloc.t ->
    (t, [ `Msg of string ]) result

  val update_frontmatter : fm -> t -> fm
end

module type Field_with_default := sig
  include Field

  val default : t
end

module Toplevel_attributes :
  Field_with_default with type t = Cmarkit.Attributes.t Cmarkit.node

module Math_link : Field with type t = Asset.t

module Theme :
  Field_with_default with type t = [ `Builtin of Themes.t | `External of string ]

module Css_links : Field with type t = Asset.t list
module Js_links : Field with type t = Asset.t list

module Dimension : sig
  include Field_with_default with type t = int * int

  val of_string' : string * Cmarkit.Textloc.t -> (t, [ `Msg of string ]) result
end

module Hljs_theme : Field_with_default with type t = string
module Math_mode : Field_with_default with type t = [ `Mathjax | `Katex ]

val of_string : to_asset:(string -> Asset.t) -> string -> int -> string -> t

type extraction = {
  frontmatter : string;
  rest : string;
  rest_offset : int * int;
  fm_offset : int;
}

val extract : string -> extraction option
(** Split the frontmatter and the rest of the input string, still computing
    offsets *)
