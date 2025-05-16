(** Extensions to the Cmarkit AST *)

open Cmarkit

type Block.t +=
  | Included of Block.t attributed node
  | Div of Block.t attributed node
  | Slide of Block.t attributed node
  | Slip of Block.t attributed node
  | SlipScript of Block.Code_block.t attributed node

module Folder = struct
  let block_ext_default f acc = function
    | Div ((b, _), _)
    | Included ((b, _), _)
    | Slide ((b, _), _)
    | Slip ((b, _), _) ->
        Folder.fold_block f acc b
    | SlipScript _ -> acc
    | _ -> assert false

  let make = Folder.make ~block_ext_default
end

module Mapper = struct
  let ( let* ) = Option.bind

  let block_ext_default m = function
    | Div ((b, attrs), meta) ->
        let* b = Mapper.map_block m b in
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        Some (Div ((b, attrs), meta))
    | Included ((b, attrs), meta) ->
        let* b = Mapper.map_block m b in
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        Some (Included ((b, attrs), meta))
    | Slide ((b, attrs), meta) ->
        let* b = Mapper.map_block m b in
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        Some (Slide ((b, attrs), meta))
    | Slip ((b, attrs), meta) ->
        let* b = Mapper.map_block m b in
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        Some (Slip ((b, attrs), meta))
    | SlipScript ((s, attrs), meta) ->
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        Some (SlipScript ((s, attrs), meta))
    | _ -> assert false

  let make = Mapper.make ~block_ext_default
end
