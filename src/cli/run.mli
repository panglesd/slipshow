val go :
  markdown_mode:bool ->
  math_link:string option ->
  css_links:string list ->
  theme:[ `Default | `None | `Other of string ] ->
  slipshow_js_link:string option ->
  input:[< `File of Fpath.t | `Stdin ] ->
  output:[< `File of Fpath.t | `Stdout ] ->
  watch:bool ->
  serve:bool ->
  (unit, [ `Msg of string ]) result
