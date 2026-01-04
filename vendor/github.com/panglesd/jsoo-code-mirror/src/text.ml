type t = Jv.t

include (Jv.Id : Jv.CONV with type t := t)

module Line = struct
  type t = Jv.t

  let from t = Jv.Int.get t "from"
  let to_ t = Jv.Int.get t "to"
  let number t = Jv.Int.get t "number"
  let text t = Jv.Jstr.get t "text"
  let length t = Jv.Int.get t "length"
end

let length t = Jv.Int.get t "length"
let line n t = Jv.call t "line" [| Jv.of_int n |]
let to_jstr_array t = Jv.call t "toJSON" [||] |> Jv.to_jstr_array
