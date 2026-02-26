type file_reader = Fpath.t -> (string option, [ `Msg of string ]) result

val of_cmarkit :
  read_file:file_reader ->
  fm:Frontmatter.resolved Frontmatter.t ->
  Cmarkit.Doc.t ->
  Ast.t * (string, string) Hashtbl.t

val to_cmarkit : Ast.t -> Cmarkit.Doc.t

val compile :
  ?file:string ->
  ?loc_offset:int * int ->
  attrs:Cmarkit.Attributes.t ->
  fm:Frontmatter.resolved Frontmatter.t ->
  ?read_file:file_reader ->
  string ->
  (Ast.t * (string, string) Hashtbl.t) * Diagnosis.t list
