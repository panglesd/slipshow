type undo = unit -> unit Fut.t
type 'a t = ('a * undo) Fut.t

let bind f x =
  let open Fut.Syntax in
  let* x, undo1 = x in
  let* y, undo2 = f x in
  let undo () =
    let* () = undo2 () in
    undo1 ()
  in
  Fut.return (y, undo)

let return ?(undo = fun () -> Fut.return ()) x = Fut.return (x, undo)
let discard x = Fut.map fst x

module Syntax = struct
  let ( let> ) x f = bind f x
end

module Browser = Browser_

module List = struct
  open Syntax

  let iter f l =
    List.fold_left
      (fun acc x ->
        let> () = acc in
        f x)
      (return ()) l
end
