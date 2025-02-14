(** Extensions to the Cmarkit AST *)

type asset =
  | Local of { mime_type : string option; content : string }
  | Remote of string

open Cmarkit

type Block.t +=
  | Div of Block.t attributed node
  | SlipScript of Block.Code_block.t attributed node
  | Subslip of Block.t attributed node

module Folder = struct
  let block_ext_default f acc = function
    | Subslip ((b, _), _) | Div ((b, _), _) -> Folder.fold_block f acc b
    | SlipScript _ -> acc
    | _ -> assert false

  let make = Folder.make ~block_ext_default
end

module Mapper = struct
  let ( let* ) = Option.bind

  let block_ext_default m = function
    | Div ((b, attrs), meta) ->
        let* b = Mapper.map_block m b in
        Some (Div ((b, attrs), meta))
    | Subslip ((b, attrs), meta) ->
        let* b = Mapper.map_block m b in
        Some (Subslip ((b, attrs), meta))
    | SlipScript _ as b -> Some b
    | _ -> assert false

  let make = Mapper.make ~block_ext_default
end
