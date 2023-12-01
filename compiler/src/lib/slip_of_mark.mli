type asset = Ast.asset =
  | Local of { mime_type : string option; content : string }
  | Remote of string

val convert :
  ?starting_state:int list * string ->
  ?math_link:asset ->
  ?slip_css_link:asset ->
  ?theorem_css_link:asset ->
  ?slipshow_js_link:asset ->
  ?resolve_images:(string -> asset) ->
  string ->
  string
