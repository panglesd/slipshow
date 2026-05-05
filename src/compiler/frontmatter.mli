type 'a loced := 'a * Cmarkit.Textloc.t

module Local : sig
  type t = { toplevel_attributes : Cmarkit.Attributes.t Cmarkit.node option }
  type 'a with_ = { x : 'a; fm : t }

  val empty : t
  val with_empty : 'a -> 'a with_
end

module Global : sig
  type t = {
    math_link : Asset.t loced option;
    theme : [ `Builtin of Themes.t | `External of string ] loced option;
    dimension : (int * int) loced option;
    highlightjs_theme : string loced option;
    math_mode : [ `Mathjax | `Katex ] loced option;
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

module Math_link : Field with type t = Asset.t loced

module Theme :
  Field_with_default
    with type t = [ `Builtin of Themes.t | `External of string ] loced

module Css_links : Field with type t = Asset.t list
module Js_links : Field with type t = Asset.t list

module Dimension : sig
  include Field_with_default with type t = (int * int) loced

  val of_string' : string * Cmarkit.Textloc.t -> (t, [ `Msg of string ]) result
end

module Hljs_theme : Field_with_default with type t = string loced
module Math_mode : Field_with_default with type t = [ `Mathjax | `Katex ] loced

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
