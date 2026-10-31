(* Linting: every TODO is a warning, every FIXME an error and every
   "note" a hint. Hover over a marked word to see its diagnostic; its
   Remove action deletes the word. *)

open Code_mirror
open State
open View
open Brr

let basic_setup = Jv.get Jv.global "__CM__basic_setup" |> Extension.of_jv

(* The positions of every occurrence of [word] in [s]. *)
let occurrences word s =
  let n = String.length word in
  let rec go i acc =
    if i + n > String.length s then List.rev acc
    else if String.sub s i n = word then go (i + n) (i :: acc)
    else go (i + 1) acc
  in
  go 0 []

let remove =
  Lint.Action.create ~name:"Remove" (fun ~view ~from ~to_ ->
      EditorView.dispatch view
        (TransactionSpec.create
           ~changes:(ChangeSpec.create ~from ~to_ ~insert:"" ())
           ()))

let diagnostics view =
  let doc = Text.to_string (EditorState.doc (EditorView.state view)) in
  let flag word severity message =
    List.map
      (fun from ->
        Lint.Diagnostic.create ~source:"demo" ~actions:[ remove ] ~from
          ~to_:(from + String.length word)
          ~severity ~message ())
      (occurrences word doc)
  in
  Fut.return
    (flag "TODO" Warning "Unfinished work"
    @ flag "FIXME" Error "Known to be broken"
    @ flag "note" Hint "Just a note")

let () =
  let doc =
    "TODO: write the rest of this.\n\
     This line is fine.\n\
     FIXME: this one is broken.\n\
     A note, for later.\n"
  in
  let config =
    EditorStateConfig.create ~doc
      ~extensions:
        (Extension.of_list [ basic_setup; Lint.create ~delay:100 diagnostics ])
      ()
  in
  let state = EditorState.create ~config () in
  ignore
    (EditorView.create
       ~config:
         (EditorViewConfig.create ~state ~parent:(Document.body G.document) ())
       ())
