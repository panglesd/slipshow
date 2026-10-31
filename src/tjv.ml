(* A typed Jv value *)
type 'a conv = { to_jv : 'a -> Jv.t; of_jv : Jv.t -> 'a }

let conv to_jv of_jv = { of_jv; to_jv }
let jv_conv : Jv.t conv = { of_jv = Jv.Id.of_jv; to_jv = Jv.Id.to_jv }

type 'a t = 'a conv * Jv.t

let map_jv (conv, v) f = (conv, f v)
let any : 'a t -> Jv.t t = fun (_conv, v) -> (jv_conv, v)

module Id = struct
  let to_jv (_, jv) = jv
  let of_jv conv v = (conv, v)
  let conv (c, _) = c
  let any = any
end

module type CONV = sig
  type 'a t

  val to_jv : 'a t -> Jv.t
  val of_jv : 'a conv -> Jv.t -> 'a t
  val conv : 'a t -> 'a conv
  val any : 'a t -> Jv.t t
end
