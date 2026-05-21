open Cmarkit
module SMap = Map.Make (String)

module Unionable_set = struct
  type 'a t = Union of 'a t * 'a t | Non_empty of 'a * 'a list

  let rec add e unionable =
    match unionable with
    | Non_empty (x, l) -> Non_empty (x, e :: l)
    | Union (x, y) -> Union (add e x, y)

  let singleton e = Non_empty (e, [])
  let union x y = Union (x, y)
  let rec get = function Non_empty (e, _) -> e | Union (x, _) -> get x

  let to_list u =
    let rec loop acc = function
      | Non_empty (x, l) -> (x :: l) :: acc
      | Union (x, y) ->
          let acc = loop acc x in
          loop acc y
    in
    let acc = loop [] u in
    List.concat acc
end

type definition = {
  id : string node;
  elem : [ `Block of Block.t | `External | `Inline of Inline.t ];
  meta : Meta.t;
}

type definitions = definition Unionable_set.t SMap.t

type id_map_entry = {
  definition : definition Unionable_set.t;
  usage : Textloc.t list;
}

type t = id_map_entry SMap.t
