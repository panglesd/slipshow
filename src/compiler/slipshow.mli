module Default : sig
  val dimension : int * int
end

module Asset : sig
  module Uri : sig
    type t = Link of string | Path of Fpath.t

    val of_string : string -> t
  end

  type t =
    | Local of { mime_type : string option; content : string }
    | Remote of string

  val of_uri :
    read_file:(Fpath.t -> (string option, [< `Msg of string ]) result) ->
    Uri.t ->
    t

  val of_string :
    read_file:(Fpath.t -> (string option, [< `Msg of string ]) result) ->
    string ->
    t
end

type starting_state = int * string
type delayed

val delayed_to_string : delayed -> string
val string_to_delayed : string -> delayed

type file_reader = Fpath.t -> (string option, [ `Msg of string ]) result
(** A value of type [file_reader], given a path [p], outputs:
    - [Ok (Some content)] if it could read the file, [content] is the content.
      In this case, the content will be included in the output.
    - [Ok None] if it decided not to read the file. In this case, the file will
      be linked.
    - [Error (`Msg m)] if it decided to try to read the file, but got an error.
      In this case, the error is reported, and the file is linked (just as
      [Ok None]). *)

val delayed :
  ?dimension:int * int ->
  ?math_link:Asset.t ->
  ?css_links:Asset.t list ->
  ?theme:[ `Builtin of Themes.t | `External of Asset.t ] ->
  ?slipshow_js_link:Asset.t ->
  ?read_file:file_reader ->
  string ->
  delayed
(** This function is used to delay the decision on the starting state. It allows
    to run [convert] server-side (which is useful to get images and so on) but
    let the previewer decide on the starting state. *)

val add_starting_state : delayed -> starting_state option -> string

val convert :
  ?dimension:int * int ->
  ?starting_state:starting_state ->
  ?math_link:Asset.t ->
  ?theme:[ `Builtin of Themes.t | `External of Asset.t ] ->
  ?css_links:Asset.t list ->
  ?slipshow_js_link:Asset.t ->
  ?read_file:Compile.file_reader ->
  string ->
  string

val convert_to_md : read_file:Compile.file_reader -> string -> string
