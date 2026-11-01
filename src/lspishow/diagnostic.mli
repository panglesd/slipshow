val linoloc_of_textloc :
  source:string ->
  positionEncoding:[ `UTF8 | `UTF16 ] ->
  Diagnosis.loc ->
  Linol.Lsp.Types.Range.t

val of_error :
  positionEncoding:[ `UTF8 | `UTF16 ] ->
  units:Slipshow.Ast.unit' Fpath.map ->
  root:Fpath.t ->
  file:Fpath.t ->
  Diagnosis.t ->
  Linol.Lsp.Types.Diagnostic.t list
