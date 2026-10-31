open Code_mirror
open State
open View
open Brr

let basic_setup = Jv.get Jv.global "__CM__basic_setup" |> Extension.of_jv

let init ?doc ?(exts = []) () =
  let config =
    EditorStateConfig.create ?doc
      ~extensions:(Extension.of_list (basic_setup :: exts))
      ()
  in
  let state = EditorState.create ~config () in
  let config =
    EditorViewConfig.create ~state ~parent:(Document.body G.document) ()
  in
  let view : EditorView.t = EditorView.create ~config () in
  (state, view)

let _ =
  let _state, view =
    init ~doc:"This doesn't have an asterisk in initially\nSome more text\n"
      ~exts:[] ()
  in
  let selection = TransactionSpec.Short { anchor = 10; head = Some 20 } in
  let transaction =
    TransactionSpec.create ~selection
      ~changes:(ChangeSpec.create ~from:10 ~insert:"*" ())
      ()
  in
  EditorView.dispatch view transaction;
  ()
