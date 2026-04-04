open Cmarkit
module SMap = Map.Make (String)

type id_map_entry = {
  id : string node;
  elem : [ `Block of Block.t | `External | `Inline of Inline.t ];
  meta : Meta.t;
}

type t = id_map_entry SMap.t
