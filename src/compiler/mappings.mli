val of_cmarkit :
  (Fpath.t -> (string option, [< `Msg of string ]) result) ->
  Cmarkit.Doc.t ->
  Cmarkit.Doc.t * Cmarkit.Doc.t

val to_cmarkit : Cmarkit.Doc.t -> Cmarkit.Doc.t
