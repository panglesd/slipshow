module M : module type of Map.Make (String)

type id_map := ((string * Cmarkit.Meta.t) * Ast.Bol.t * Cmarkit.Meta.t) M.t
type check := id_map -> Cmarkit.Attributes.t -> Ast.Bol.t -> unit

val all_checks : check list
