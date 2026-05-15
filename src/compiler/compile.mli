type file_reader = Fpath.t -> (string option, [ `Msg of string ]) result

(* val included_files : *)
(*   ?file:string -> ?read_file:file_reader -> string -> string list *)

val to_cmarkit : Ast.units -> Cmarkit.Doc.t

val unit :
  read_file:file_reader -> Fpath.t -> (Ast.unit', [ `Msg of string ]) result

(* val add_to_compile : *)
(*   Fpath.t -> *)
(*   Ast.units -> *)
(*   read_file:file_reader -> *)
(*   (Ast.units, [ `Msg of string ]) result * Diagnosis.t list *)

val compile_all :
  read_file:file_reader ->
  Ast.unit' Fpath.Map.t ->
  Fpath.t ->
  (Ast.units, [ `Msg of string ]) result * Diagnosis.t list

val action_plan : Ast.units -> Ast.Action_plan.t
