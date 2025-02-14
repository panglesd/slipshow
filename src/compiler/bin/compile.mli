val compile :
  math_link:string option ->
  slip_css_link:string option ->
  slipshow_js_link:string option ->
  input:[< `File of Fpath.t | `Stdin ] ->
  output:[< `File of Fpath.t | `Stdout ] ->
  watch:bool ->
  serve:bool ->
  (unit, [ `Msg of string ]) result
