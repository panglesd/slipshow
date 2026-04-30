module M : module type of Map.Make (String)

type id_map :=
  (string Cmarkit.node * [ Iterators.Bol.t | `External ] * Cmarkit.Meta.t) M.t

type check := id_map -> Cmarkit.Attributes.t -> Iterators.Bol.t -> unit

val all_checks : check list
