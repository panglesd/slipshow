(* Widget decorations: elements drawn in the document. Pressing F2 adds
   a block widget under the cursor's line saying how long the line is.
   The widgets live in a state field of decorations, added by an effect
   whose position maps through later edits, so they stay with their
   lines as the text above them changes. The button replaces the whole
   document: notes inside it go, one at its very end is kept. *)

open Code_mirror
open State
open View
open Brr

let basic_setup = Jv.get Jv.global "__CM__basic_setup" |> Extension.of_jv

(* The effect carries the position to decorate; [map] keeps it right when
   earlier text is inserted or deleted. *)
let add_note =
  StateEffect.define_ Jv.of_int Jv.to_int ~map:(fun pos changes ->
      Some (ChangeDesc.mapPos changes pos))

let note_widget text =
  WidgetType.make
    ~to_dom:(fun _view ->
      let el = El.div [ El.txt' text ] in
      El.set_inline_style (Jstr.v "color") (Jstr.v "#666") el;
      El.set_inline_style (Jstr.v "font-style") (Jstr.v "italic") el;
      El.set_inline_style (Jstr.v "padding-left") (Jstr.v "2em") el;
      el)
    ()

let decoration_conv = { Tjv.to_jv = Decoration.to_jv; of_jv = Decoration.of_jv }

let notes =
  StateField.define RangeSet.to_jv
    (RangeSet.of_jv decoration_conv)
    ~create:(fun _ -> Decoration.none)
    ~update:(fun set tr ->
      let set = RangeSet.map set (Transaction.changes tr) in
      List.fold_left
        (fun set e ->
          match StateEffect.value e add_note with
          | None -> set
          | Some pos ->
              let doc = EditorState.doc (Transaction.state tr) in
              let line = Text.line_at pos doc in
              let text =
                Printf.sprintf "line %d is %d characters long"
                  (Line.number line) (Line.length line)
              in
              let widget =
                Decoration.widget ~block:true ~side:1 (note_widget text)
              in
              RangeSet.update
                ~add:[ Decoration.range ~from:(Line.to_ line) widget ]
                set)
        set (Transaction.effects tr))
    ~provide:(Facet.from EditorView.decorations)

let () =
  let note_here view =
    let state = EditorView.state view in
    let head =
      SelectionRange.head
        (List.hd (EditorSelection.ranges (EditorState.selection state)))
    in
    EditorView.dispatch view
      (TransactionSpec.create ~effects:[ StateEffect.of_ add_note head ] ());
    true
  in
  let keys =
    Facet.of_ Keymap.keymap [ Keymap.create ~key:"F2" ~run:note_here () ]
  in
  let initial_doc =
    "Put the cursor on a line and press F2.\n\
     A note appears under the line.\n\
     Edit above a note: it stays with its line.\n"
  in
  let config =
    EditorStateConfig.create ~doc:initial_doc
      ~extensions:
        (Extension.of_list [ basic_setup; keys; StateField.extension notes ])
      ()
  in
  let state = EditorState.create ~config () in
  let view =
    EditorView.create
      ~config:
        (EditorViewConfig.create ~state ~parent:(Document.body G.document) ())
      ()
  in
  let reset = El.button [ El.txt' "Reset document" ] in
  ignore
    (Ev.listen Ev.click
       (fun _ -> EditorView.set_doc view initial_doc)
       (El.as_target reset));
  El.append_children (Document.body G.document) [ reset ]
