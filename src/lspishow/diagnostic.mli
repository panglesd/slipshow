val linoloc_of_textloc :
  source:string ->
  positionEncoding:[ `UTF8 | `UTF16 ] ->
  Diagnosis.loc ->
  Linol_lwt.Range.t

val of_error :
  positionEncoding:[ `UTF8 | `UTF16 ] ->
  units:Slipshow.Ast.unit' Fpath.map ->
  root:Fpath.t ->
  file:Fpath.t ->
  Diagnosis.t ->
  Linol_lwt.Diagnostic.t list
