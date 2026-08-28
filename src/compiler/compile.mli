type file_reader = Fpath.t -> (string option, [ `Msg of string ]) result

(* val included_files : *)
(*   ?file:string -> ?read_file:file_reader -> string -> string list *)

val to_cmarkit : Ast.units -> Cmarkit.Doc.t

val unit :
  ?locs:Cmarkit.Textloc.t list ->
  read_file:file_reader ->
  embed_loc:bool ->
  Fpath.t ->
  Ast.unit' * Diagnosis.t list

(* val add_to_compile : *)
(*   Fpath.t -> *)
(*   Ast.units -> *)
(*   read_file:file_reader -> *)
(*   (Ast.units, [ `Msg of string ]) result * Diagnosis.t list *)

val compile_all :
  read_file:file_reader ->
  directory:Fpath.t ->
  embed_loc:bool ->
  (Ast.unit' * Diagnosis.t list) Fpath.Map.t ->
  Fpath.t ->
  Ast.units * Diagnosis.t list
(** [compile_all ~read_file ~embed_loc units_cache file] will compile [file] and
    all the units it depends on, using [units_cache] if some units already have
    been compiled. *)

val action_plan : Ast.units -> Ast.Action_plan.t
