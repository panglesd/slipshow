type t = Jv.t

include (Jv.Id : Jv.CONV with type t := t)

let of_list l = Jv.of_list to_jv l
