type t = Cmarkit.Doc.t
type file_reader = Fpath.t -> (string option, [ `Msg of string ]) result

val of_cmarkit : read_file:file_reader -> Cmarkit.Doc.t -> t
val to_cmarkit : t -> Cmarkit.Doc.t

val compile :
  attrs:Cmarkit.Attributes.t -> ?read_file:file_reader -> string -> t
