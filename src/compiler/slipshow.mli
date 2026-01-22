module Asset = Asset
module Frontmatter = Frontmatter
module Compile = Compile
module Ast = Ast
module Errors = Errors
module Renderers = Renderers
module Has = Has

type starting_state = int
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

val embed_in_page :
  slipshow_js:Asset.t option ->
  string ->
  has:Has.t ->
  math_link:Asset.t option ->
  css_links:Asset.t list ->
  js_links:Asset.t list ->
  theme:[< `Builtin of Themes.t | `External of Asset.t ] ->
  dimension:int * int ->
  delayed

val delayed :
  ?slipshow_js:Asset.t ->
  ?frontmatter:Frontmatter.resolved Frontmatter.t ->
  ?read_file:file_reader ->
  string ->
  delayed
(** This function is used to delay the decision on the starting state. It allows
    to run [convert] server-side (which is useful to get images and so on) but
    let the previewer decide on the starting state. *)

val add_starting_state :
  include_speaker_view:bool ->
  ?autofocus:bool ->
  delayed ->
  starting_state option ->
  string

val convert :
  include_speaker_view:bool ->
  ?autofocus:bool ->
  ?slipshow_js:Asset.t ->
  ?frontmatter:Frontmatter.resolved Frontmatter.t ->
  ?starting_state:starting_state ->
  ?read_file:file_reader ->
  string ->
  string

val convert_to_md : read_file:file_reader -> string -> string
