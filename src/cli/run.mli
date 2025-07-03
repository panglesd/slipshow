val compile :
  width:int ->
  height:int ->
  input:[ `File of Fpath.t | `Stdin ] ->
  output:[ `File of Fpath.t | `Stdout ] ->
  math_link:string option ->
  css_links:string list ->
  theme:string option ->
  (Fpath.Set.t, [ `Msg of string ]) result

val watch :
  width:int ->
  height:int ->
  input:Fpath.t ->
  output:Fpath.t ->
  math_link:string option ->
  css_links:string list ->
  theme:string option ->
  (unit, [ `Msg of string ]) result

val serve :
  width:int ->
  height:int ->
  input:Fpath.t ->
  output:Fpath.t ->
  math_link:string option ->
  css_links:string list ->
  theme:string option ->
  (unit, [ `Msg of string ]) result

val markdown_compile :
  input:[< `File of Fpath.t | `Stdin ] ->
  output:[< `File of Fpath.t | `Stdout ] ->
  (unit, [ `Msg of string ]) result
