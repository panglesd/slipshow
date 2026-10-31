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

let update dom v =
  let st = EditorView.Update.state v in
  let doc = EditorState.doc st in
  let length = Text.length doc in
  El.set_children dom [ El.txt' (string_of_int length) ]

let panel_constructor (_v : EditorView.t) =
  let dom = Brr.El.div [ Brr.El.txt (Jstr.v "Hello! This is a panel\n") ] in
  Panel.create ~update:(update dom) dom

let _ =
  let toggleHelp = StateEffect.define Jv.of_bool Jv.to_bool in

  let state_update cur t =
    let effects = Transaction.effects t in
    List.fold_right
      (fun e cur ->
        match StateEffect.value e toggleHelp with Some b -> b | _ -> cur)
      effects cur
  in

  let provide field =
    Facet.from' showPanel field (fun b ->
        if b then Some panel_constructor else None)
  in

  let help_state =
    StateField.define Jv.of_bool Jv.to_bool
      ~create:(fun _ -> false)
      ~provide ~update:state_update
  in

  let run v =
    let cur = EditorState.field (EditorView.state v) help_state in
    let eff = StateEffect.of_ toggleHelp (not cur) in
    let transaction = TransactionSpec.create ~effects:[ eff ] () in
    EditorView.dispatch v transaction;
    true
  in

  let keymap = Keymap.create ~key:"F1" ~run () in

  let ext = Facet.of_ Keymap.keymap [ keymap ] in

  let _editor =
    init ~doc:"Press 'f1' to toggle the panel"
      ~exts:[ ext; StateField.extension help_state ]
      ()
  in
  ()
