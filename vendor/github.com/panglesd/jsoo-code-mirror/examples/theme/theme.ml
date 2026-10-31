open Code_mirror
open State
open View
open Brr

let basic_setup = Jv.get Jv.global "__CM__basic_setup" |> Extension.of_jv
let dracula = Jv.get Jv.global "__CM__theme_dracula" |> Extension.of_jv

let init ?doc () =
  let config =
    EditorStateConfig.create ?doc
      ~extensions:(Extension.of_list [ dracula; basic_setup ])
      ()
  in
  let state = EditorState.create ~config () in
  let config =
    EditorViewConfig.create ~state ~parent:(Document.body G.document) ()
  in
  let view = EditorView.create ~config () in
  (state, view)

let _ =
  let _ = init ~doc:"Example of the 'dracula' theme" () in
  ()
