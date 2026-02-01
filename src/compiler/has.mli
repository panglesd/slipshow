module StringSet : module type of Set.Make (String)

type t = { math : bool; pdf : bool; code_blocks : StringSet.t }

val find_out : Ast.t -> t
