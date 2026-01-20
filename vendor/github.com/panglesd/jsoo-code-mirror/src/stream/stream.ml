let g = Jv.get Jv.global "__CM__stream_parser"

module Language = struct
  type t

  include (Jv.Id : Jv.CONV with type t := t)

  let g = Jv.get g "StreamLanguage"

  let define (l : t) =
    Jv.call g "define" [| to_jv l |] |> Code_mirror.Extension.of_jv
end
