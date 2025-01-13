open Cmarkit

exception Has_math

let has_math =
  let block _ _ = function
    | Block.Ext_math_block _ -> raise Has_math
    | _ -> Folder.default
  in
  let inline _ _ = function
    | Inline.Ext_math_span _ -> raise Has_math
    | _ -> Folder.default
  in
  Ast.Folder.make ~block ~inline ()

let has_math doc =
  try Cmarkit.Folder.fold_doc has_math false doc with Has_math -> true
