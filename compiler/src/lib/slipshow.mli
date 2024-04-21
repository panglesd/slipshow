type asset = Ast.asset =
  | Local of { mime_type : string option; content : string }
  | Remote of string

type starting_state = int list * string
type delayed

val delayed :
  ?math_link:asset ->
  ?slip_css_link:asset ->
  ?theorem_css_link:asset ->
  ?slipshow_js_link:asset ->
  ?resolve_images:(string -> asset) ->
  string ->
  delayed
(** This function is used to delay the decision on the starting state. It allows
    to run [convert] server-side (which is useful to get images and so on) but
    let the previewer decide on the starting state. *)

val add_starting_state : delayed -> starting_state option -> string

val convert :
  ?starting_state:starting_state ->
  ?math_link:asset ->
  ?slip_css_link:asset ->
  ?theorem_css_link:asset ->
  ?slipshow_js_link:asset ->
  ?resolve_images:(string -> asset) ->
  string ->
  string
