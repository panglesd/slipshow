val compile :
  dimension:(int * int) option ->
  input:[ `File of Fpath.t | `Stdin ] ->
  output:[ `File of Fpath.t | `Stdout ] ->
  math_link:string option ->
  css_links:string list ->
  theme:string option ->
  (Fpath.Set.t, [ `Msg of string ]) result

val watch :
  dimension:(int * int) option ->
  input:Fpath.t ->
  output:Fpath.t ->
  math_link:string option ->
  css_links:string list ->
  theme:string option ->
  (unit, [ `Msg of string ]) result

val serve :
  dimension:(int * int) option ->
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
