type 'a node = 'a * Cmarkit.Textloc.t

val id : string (* node *) -> string (* node *)

type 'a description_named_atom =
  string * (string -> ('a, [ `Msg of string ]) result)

type _ descr_tuple =
  | [] : unit descr_tuple
  | ( :: ) : 'a description_named_atom * 'b descr_tuple -> ('a * 'b) descr_tuple

type _ output_tuple =
  | [] : unit output_tuple
  | ( :: ) : 'a option * 'b output_tuple -> ('a * 'b) output_tuple

type 'a non_empty_list = 'a * 'a list

type ('named, 'positional) parsed = {
  p_named : 'named output_tuple;
  p_pos : 'positional node list;
}

val parse :
  named:'named descr_tuple ->
  positional:(string (* node *) -> 'pos (* node *)) ->
  string node ->
  (('named, 'pos) parsed non_empty_list, [> `Msg of string ]) result

val require_single_action : action_name:string -> 'a * 'b list -> 'a
val require_single_positional : action_name:string -> 'a list -> 'a option

val no_args :
  action_name:string -> string node -> (unit, [> `Msg of string ]) result

val parse_only_els :
  string node ->
  ([ `Self | `Ids of string node list ], [> `Msg of string ]) result

val parse_only_el :
  string node -> ([ `Self | `Id of string node ], [> `Msg of string ]) result

val option_to_error : 'a -> 'b option -> ('b, [> `Msg of 'a ]) result
val duration : string * (string -> (float, [> `Msg of string ]) result)
val margin : string * (string -> (float, [> `Msg of string ]) result)
