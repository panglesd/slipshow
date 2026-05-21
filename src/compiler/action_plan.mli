open Ast.Action_plan
open Actions_arguments

val targets : arg -> string W.node list

(* val merge_id_maps : Ast.unit' -> Ast.unit' Fpath.Map.t -> Id_map.t *)

val execute :
  Ast.unit' ->
  Ast.unit' Fpath.Map.t ->
  (* Frontmatter.Toplevel_attributes.t -> *)
  t * Id_map.t
