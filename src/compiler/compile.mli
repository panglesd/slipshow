type file_reader = Fpath.t -> (string option, [ `Msg of string ]) result

val of_cmarkit :
  read_file:file_reader ->
  fm:Frontmatter.t ->
  Cmarkit.Doc.t ->
  Ast.t * (string, string) Hashtbl.t * Frontmatter.t

val to_cmarkit : Ast.t -> Cmarkit.Doc.t

val compile :
  ?file:string ->
  ?read_file:file_reader ->
  string ->
  (Ast.t * (string, string) Hashtbl.t * Frontmatter.t) * Diagnosis.t list
