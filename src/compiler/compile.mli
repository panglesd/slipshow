type file_reader = Fpath.t -> (string option, [ `Msg of string ]) result

val of_cmarkit : read_file:file_reader -> Cmarkit.Doc.t -> Ast.t
val to_cmarkit : Ast.t -> Cmarkit.Doc.t

val compile :
  ?file:string ->
  attrs:Cmarkit.Attributes.t ->
  ?read_file:file_reader ->
  string ->
  Ast.t * Errors.t list
