type file_reader = Fpath.t -> (string option, [ `Msg of string ]) result

type t = {
  ast : Ast.t;
  included_files : string Fpath.Map.t;
  id_map : Id_map.t;
  action_plan : Action_plan.t;
}

val to_cmarkit : Ast.t -> Cmarkit.Doc.t

val compile :
  ?file:Fpath.t -> ?read_file:file_reader -> string -> t * Diagnosis.t list
