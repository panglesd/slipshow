val compile :
  input:[ `File of Fpath.t | `Stdin ] ->
  output:[ `File of Fpath.t | `Stdout ] ->
  math_link:string option ->
  css_links:string list ->
  theme:string option ->
  (unit, [ `Msg of string ]) result

val watch :
  input:Fpath.t ->
  output:Fpath.t ->
  math_link:string option ->
  css_links:string list ->
  theme:string option ->
  (unit, [ `Msg of string ]) result

val serve :
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
