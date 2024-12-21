type undo = unit -> unit Fut.t
type 'a t = ('a * undo list) Fut.t

let bind f x =
  let open Fut.Syntax in
  let* x, undos = x in
  let* y, new_undos = f x in
  Fut.return (y, new_undos @ undos)

let return x = Fut.return (x, [])

module Syntax = struct
  let ( let> ) x f = bind f x
end
