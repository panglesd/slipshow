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

val delayed :
  width:int ->
  height:int ->
  ?math_link:Asset.t ->
  ?css_links:Asset.t list ->
  ?theme:[ `Builtin of Themes.t | `External of Asset.t ] ->
  ?slipshow_js_link:Asset.t ->
  ?read_file:Compile.file_reader ->
  string ->
  delayed
(** This function is used to delay the decision on the starting state. It allows
    to run [convert] server-side (which is useful to get images and so on) but
    let the previewer decide on the starting state. *)

val add_starting_state : delayed -> starting_state option -> string

val convert :
  width:int ->
  height:int ->
  ?starting_state:starting_state ->
  ?math_link:Asset.t ->
  ?theme:[ `Builtin of Themes.t | `External of Asset.t ] ->
  ?css_links:Asset.t list ->
  ?slipshow_js_link:Asset.t ->
  ?read_file:Compile.file_reader ->
  string ->
  string

val convert_to_md : read_file:Compile.file_reader -> string -> string
