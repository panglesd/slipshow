type undo = unit -> unit Fut.t
type 'a t = 'a * undo list

let map f (x, undos) = (f x, undos)

let bind f (x, undos) =
  let res, new_undoes = f x in
  (res, new_undoes @ undos)

let return x = (x, [])

module Syntax = struct
  let ( let> ) f x = bind x f
end
