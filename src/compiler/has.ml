open Cmarkit
module StringSet = Set.Make (String)

type t = { math : bool; pdf : bool; mermaid : bool; code_blocks : StringSet.t }

let has =
  let block f acc = function
    | Ast.Block.Math_block _ -> { acc with math = true }
    | MermaidJS _ -> { acc with mermaid = true }
    | Code_block ((cb, _), _) -> (
        match Block.Code_block.info_string cb with
        | None -> acc
        | Some (info_string, _) -> (
            match Block.Code_block.language_of_info_string info_string with
            | None -> acc
            | Some (lang, _) ->
                { acc with code_blocks = StringSet.add lang acc.code_blocks }))
    | b -> Iterators.Folder.default.block f acc b
  in
  let inline f acc = function
    | Ast.Inline.Math_span _ -> { acc with math = true }
    | Pdf _ -> { acc with pdf = true }
    | i -> Iterators.Folder.default.inline f acc i
  in
  { Iterators.Folder.default with block; inline }

let find_out (doc : Ast.t) =
  has.block has
    {
      math = false;
      pdf = false;
      code_blocks = StringSet.empty;
      mermaid = false;
    }
    doc.doc
