type undo = Undo of (unit -> unit Fut.t)
and redo = Redo of (unit -> unit Fut.t)
and 'a t = ('a * undo * redo) Fut.t

type direction = Forward | Backward

let forward () = raise (Failure "yo")

let rec bind (f : 'a -> 'b t) (x : 'a t) : 'b t =
  let open Fut.Syntax in
  let (* rec *) combine undo1 undo2 () =
    let* () (* , Undo redo1 *) = undo2 () in
    let* () (* , Undo redo2 *) = undo1 () in
    Fut.return () (* , Undo (combine redo1 redo2) *)
  in
  let* x, Undo undo1, Redo redo1 = x in
  match forward () with
  | Forward ->
      let* y, Undo undo2, Redo redo2 = f x in
      let undo = combine undo1 undo2 in
      let redo () =
        let* () = redo1 () in
        let+ () = redo2 () in
        ()
      in
      Fut.return (y, Undo undo, Redo redo)
  | Backward -> (
      (* let* y, Undo undo2 = f x in *)
      let* () = undo1 () in
      match forward () with
      | Forward -> _
      | Backward ->
          let undo = combine undo1 undo2 in
          Fut.return (y, Undo undo, Redo _))

let () =
  let ( let> ) = Fun.flip bind in
  let> () = f1 () in
  let> () = f2 () in
  f3 ()

let () =
  let bind_ = Fun.flip bind in
  bind_ (fffffffffffffffffffffff1 ()) (fun () ->
      bind (ffffffffffffffffffffffffffffffffffffffff2 ()) (fun () ->
          fffffffffffffffffffffffffffffffff3 ()))

let return ?(undo = fun () -> Fut.return ()) x = Fut.return (x, undo)
let discard x = Fut.map fst x

module Syntax = struct
  let ( let> ) x f = bind f x
end

let rec sleep (ms : int) : unit t =
  let open Fut.Syntax in
  if forward then
    let+ () = Fut.tick ~ms in
    let undo () = sleep ms in
    ((), Undo undo)
  else _

(** Différentes contraintes

    Différentes possibilités :
    - Utiliser des effets
    - Sympa techniquement
    - Potentiellement moins efficace
    - Problème avec l'interface avec Javascript?

    - Utiliser une monade :
    - Toute les opérations checkent si on est en mode actif et ne font que si en
      mode actif ?

    - La fonction bind est réécrite pour ne continuer que si il le faut *)
