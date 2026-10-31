open Code_mirror
open State
open View
open Brr

let basic_setup = Jv.get Jv.global "__CM__basic_setup" |> Extension.of_jv

module Highlight = struct
  type t = { from : int; to_ : int }

  include (Jv.Id : Jv.CONV with type t := t)
end

let add_underline =
  let map v changes =
    Some
      Highlight.
        {
          from = ChangeDesc.mapPos changes v.from;
          to_ = ChangeDesc.mapPos changes v.to_;
        }
  in
  StateEffect.define_ Highlight.to_jv Highlight.of_jv ~map

let underline_mark = Decoration.mark ~className:"cm-underline" ()

let underline_field =
  let to_jv v = RangeSet.to_jv v in
  let of_jv jv =
    RangeSet.of_jv { Tjv.to_jv = Decoration.to_jv; of_jv = Decoration.of_jv } jv
  in
  StateField.define to_jv of_jv
    ~create:(fun _ -> Decoration.none)
    ~update:(fun v tr ->
      let v = RangeSet.map v (Transaction.changes tr) in
      let effects = Transaction.effects tr in
      List.fold_right
        (fun e cur ->
          if StateEffect.is e add_underline then
            match StateEffect.value e add_underline with
            | Some { from; to_ } ->
                let add = Decoration.range ~from ~to_ underline_mark in
                RangeSet.update ~add:[ add ] cur
            | None -> cur
          else cur)
        effects v)
    ~provide:(Facet.from EditorView.decorations)

let underline_theme =
  EditorView.(
    base_theme
      (TO
         [
           ( ".cm-underline",
             TO
               [
                 ("textDecoration", TV "underline 3px red");
                 (* Browsers skip the underline where glyphs touch it, which
                    at this thickness leaves only fragments; draw it whole
                    and below the descenders. *)
                 ("textDecorationSkipInk", TV "none");
                 ("textUnderlineOffset", TV "3px");
               ] );
         ]))

let underline_selection view =
  let selection = EditorState.selection (EditorView.state view) in
  let ranges = EditorSelection.ranges selection in
  let effects =
    List.filter_map
      (fun r ->
        if SelectionRange.empty r then None
        else
          let from = SelectionRange.from r in
          let to_ = SelectionRange.to_ r in
          Some (StateEffect.of_ add_underline { from; to_ }))
      ranges
    |> List.map StateEffect.any
  in
  match effects with
  | [] -> false
  | effects ->
      let state = EditorView.state view in
      let effects =
        try
          ignore (EditorState.field state underline_field);
          effects
        with _ ->
          let x =
            StateEffect.of_
              (StateEffect.append_config ())
              (Extension.of_list
                 [ StateField.extension underline_field; underline_theme ])
          in
          Console.log [ Jv.of_string "adding underline fields and theme" ];
          StateEffect.any x :: effects
      in
      EditorView.dispatch view (TransactionSpec.create ~effects ());
      true

let keymap = Keymap.create ~key:"F1" ~run:underline_selection ()
let ext = Facet.of_ Keymap.keymap [ keymap ]

let init ?doc ?(exts = []) () =
  let config =
    EditorStateConfig.create ?doc
      ~extensions:(Extension.of_list (basic_setup :: ext :: exts))
      ()
  in
  let state = EditorState.create ~config () in
  let config =
    EditorViewConfig.create ~state ~parent:(Document.body G.document) ()
  in
  let view : EditorView.t = EditorView.create ~config () in
  (state, view)

let _ =
  Console.log [ Jv.of_string "init_underline" ];
  let _state, _view =
    init ~doc:"Select some text and hit 'f1' to highlight it\nSome more text\n"
      ~exts:[] ()
  in
  (* let transaction =
    TransactionSpec.create
      ~effects:[StateEffect.of_ add_underline { from = 10; to_ = 20 }]
      ()
  in
  EditorView.dispatch view transaction;
  () *)
  ()
