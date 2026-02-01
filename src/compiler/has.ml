open Cmarkit
module StringSet = Set.Make (String)

type t = { math : bool; pdf : bool; code_blocks : StringSet.t }

let has =
  let block _ acc = function
    | Block.Ext_math_block _ -> Folder.ret { acc with math = true }
    | Block.Code_block ((cb, _), _) -> (
        match Block.Code_block.info_string cb with
        | None -> Folder.default
        | Some (info_string, _) -> (
            match Block.Code_block.language_of_info_string info_string with
            | None -> Folder.default
            | Some (lang, _) ->
                Folder.ret
                  { acc with code_blocks = StringSet.add lang acc.code_blocks })
        )
    | _ -> Folder.default
  in
  let inline _ acc = function
    | Inline.Ext_math_span _ -> Folder.ret { acc with math = true }
    | Ast.S_inline (Pdf _) -> Folder.ret { acc with pdf = true }
    | _ -> Folder.default
  in
  Ast.Folder.make ~block ~inline ()

let find_out (doc : Ast.t) =
  Cmarkit.Folder.fold_doc has
    { math = false; pdf = false; code_blocks = StringSet.empty }
    doc.doc
