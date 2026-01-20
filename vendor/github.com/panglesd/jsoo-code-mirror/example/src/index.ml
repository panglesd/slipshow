open Code_mirror
open Brr

let basic_setup = Jv.get Jv.global "__CM__basic_setup" |> Extension.of_jv

let init ?doc ?(exts = [||]) () =
  let open Editor in
  let config =
    State.Config.create ?doc
      ~extensions:(Array.concat [ [| basic_setup |]; exts ])
      ()
  in
  let state = State.create ~config () in
  let opts = View.opts ~state ~parent:(Document.body G.document) () in
  let view : View.t = View.create ~opts () in
  (state, view)

let _editor = init ~exts:[||] ()
