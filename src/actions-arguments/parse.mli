module W := Warnings

val id : string (* node *) -> string (* node *)

type 'a description_named_atom =
  string * (string W.node -> ('a, [ `Msg of string ]) result)

type _ descr_tuple =
  | [] : unit descr_tuple
  | ( :: ) : 'a description_named_atom * 'b descr_tuple -> ('a * 'b) descr_tuple

type _ output_tuple =
  | [] : unit output_tuple
  | ( :: ) : 'a W.node option * 'b output_tuple -> ('a * 'b) output_tuple

type 'a non_empty_list = 'a * 'a list

type ('named, 'positional) parsed = {
  p_named : 'named output_tuple;
  p_pos : 'positional W.node list;
}

val parse :
  action_name:string ->
  named:'named descr_tuple ->
  positional:(string -> 'pos) ->
  string ->
  (('named, 'pos) parsed W.node non_empty_list W.t, [> `Msg of string ]) result

val require_single_action :
  action_name:string -> 'a W.node non_empty_list -> 'a W.node W.t

val require_single_positional :
  action_name:string -> 'a W.node list -> 'a W.node option W.t

val no_args :
  action_name:string -> string -> (unit W.t, [> `Msg of string ]) result

val parse_only_els :
  action_name:string ->
  string ->
  ([ `Self | `Ids of string W.node list ] W.t, [> `Msg of string ]) result

val parse_only_el :
  action_name:string ->
  string ->
  ([ `Self | `Id of string W.node ] W.t, [> `Msg of string ]) result

val option_to_error : 'a -> 'b option -> ('b, [> `Msg of 'a ]) result
val duration : string * (string W.node -> (float, [> `Msg of string ]) result)
val margin : string * (string W.node -> (float, [> `Msg of string ]) result)
