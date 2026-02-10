val compile :
  input:[ `File of Fpath.t | `Stdin ] ->
  output:[ `File of Fpath.t | `Stdout ] ->
  cli_frontmatter:Slipshow.Frontmatter.unresolved Slipshow.Frontmatter.t ->
  (Fpath.Set.t, [ `Msg of string ]) result

val watch :
  input:Fpath.t ->
  output:Fpath.t ->
  cli_frontmatter:Slipshow.Frontmatter.unresolved Slipshow.Frontmatter.t ->
  (unit, [ `Msg of string ]) result

val serve :
  input:Fpath.t ->
  output:Fpath.t ->
  cli_frontmatter:Slipshow.Frontmatter.unresolved Slipshow.Frontmatter.t ->
  port:int ->
  (unit, [ `Msg of string ]) result

val markdown_compile :
  input:[< `File of Fpath.t | `Stdin ] ->
  output:[< `File of Fpath.t | `Stdout ] ->
  (unit, [ `Msg of string ]) result

val present : Fpath.t -> (unit, [ `Msg of string ]) result
