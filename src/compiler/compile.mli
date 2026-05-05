type file_reader = Fpath.t -> (string option, [ `Msg of string ]) result

type t = {
  ast : Ast.t;
  included_files : (string, string) Hashtbl.t;
  id_map : Id_map.t;
  action_plan : Action_plan.t;
}

val of_cmarkit :
  read_file:file_reader ->
  fm:Frontmatter.t ->
  Cmarkit.Doc.t ->
  t

val to_cmarkit : Ast.t -> Cmarkit.Doc.t

val compile :
  ?file:string ->
  ?read_file:file_reader ->
  string ->
  t * Diagnosis.t list
