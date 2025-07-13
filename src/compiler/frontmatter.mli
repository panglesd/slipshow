type resolved = [ `Resolved ]
type unresolved = [ `Unresolved ]

type 'a fm = {
  toplevel_attributes : Cmarkit.Attributes.t option;
  math_link : 'a option;
  theme : [ `Builtin of Themes.t | `External of string ] option;
  css_links : 'a list;
  dimension : (int * int) option;
}

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
  val toplevel_attributes :
    string -> (Cmarkit.Attributes.t, [> `Msg of string ]) result

  val math_link : 'a -> 'a
  val theme : string -> [> `Builtin of Themes.t | `External of string ]
  val css_link : 'a -> 'a
  val dimension : string -> (int * int, [> `Msg of string ]) result
end

module Yaml_to : sig
  val expect_string : string -> ('a, [> `Msg of string ]) result

  val toplevel_attributes :
    [> `String of string ] -> (Cmarkit.Attributes.t, [> `Msg of string ]) result

  val math_link : [> `String of 'a ] -> ('a, [> `Msg of string ]) result

  val theme :
    [> `String of string ] ->
    ( [> `Builtin of Themes.t | `External of string ],
      [> `Msg of string ] )
    result

  val css_link : [> `String of 'a ] -> ('a, [> `Msg of string ]) result
  val ( let* ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result

  val css_links :
    [> `A of [> `String of 'a ] list | `String of 'a ] ->
    ('a list, [> `Msg of string ]) result

  val dimension :
    [> `String of string ] -> (int * int, [> `Msg of string ]) result
end

val get : 'a * ('b -> 'c) -> ('a * 'b) list -> 'c option

val of_yaml :
  [> `O of
     (string * [> `A of [> `String of string ] list | `String of string ]) list
  ] ->
  (unresolved t, [> `Msg of string ]) result

val ( let* ) : 'a option -> ('a -> 'b option) -> 'b option
val ( let+ ) : 'a option -> ('a -> 'b) -> 'b option
val find_opening : string -> int option
val find_closing : string -> int -> (int * int) option
val extract : string -> (Yaml.value Yaml.res * string) option
val combine : resolved t -> resolved t -> resolved t
val resolve : unresolved t -> to_asset:(string -> Asset.t) -> resolved t
