open Cmarkit

type t = { math : bool; pdf : bool }

let has =
  let block _ acc = function
    | Block.Ext_math_block _ -> Folder.ret { acc with math = true }
    | _ -> Folder.default
  in
  let inline _ acc = function
    | Inline.Ext_math_span _ -> Folder.ret { acc with math = true }
    | Ast.S_inline (Pdf _) -> Folder.ret { acc with pdf = true }
    | _ -> Folder.default
  in
  Ast.Folder.make ~block ~inline ()

let find_out (doc : Ast.t) =
  Cmarkit.Folder.fold_doc has { math = false; pdf = false } doc.doc
