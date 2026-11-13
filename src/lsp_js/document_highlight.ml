open Code_mirror

let decoration = View.Decoration.mark ~className:"cm-highlight-occurrences" ()

let decoration_conv =
  { Tjv.of_jv = View.Decoration.of_jv; to_jv = View.Decoration.to_jv }

let state_effect =
  State.StateEffect.define State.RangeSet.to_jv
    (State.RangeSet.of_jv decoration_conv)

let state_field =
  let update decorations transition =
    let res =
      State.RangeSet.map decorations (State.Transaction.changes transition)
    in
    let effects = State.Transaction.effects transition in
    List.fold_left
      (fun res eff ->
        match State.StateEffect.value eff state_effect with
        | None -> res
        | Some res -> res)
      res effects
  in
  State.StateField.define State.RangeSet.to_jv
    (State.RangeSet.of_jv decoration_conv)
    ~create:(fun _state -> View.Decoration.none)
    ~update
    ~provide:(fun field -> State.Facet.from View.EditorView.decorations field)

let extension_field = State.StateField.extension state_field

let send_document_highlight view =
  match Lsp_client.LSPPlugin.get view with
  | None -> ()
  | Some plugin -> (
      let client = Lsp_client.LSPPlugin.client plugin in
      let state = View.EditorView.state view in
      let position =
        let selection = State.EditorState.selection state in
        let selection_range = State.EditorSelection.main selection in
        let pos = State.SelectionRange.head selection_range in
        Lsp_client.LSPPlugin.to_position plugin ~pos ()
      in
      let text_document =
        let uri = Lsp_client.LSPPlugin.uri plugin in
        Jv.obj [| ("uri", Jv.of_string uri) |]
      in
      let params =
        Jv.obj [| ("position", position); ("textDocument", text_document) |]
      in
      let () = Lsp_client.LSPClient.sync client in
      Fut.await
        (Lsp_client.LSPClient.request ~method_:"textDocument/documentHighlight"
           ~params client)
      @@ function
      | Ok res ->
          let of_document_highlight res =
            let range = Jv.get res "range" in
            let from =
              let start = Jv.get range "start" in
              Lsp_client.LSPPlugin.from_position plugin ~pos:start ()
            in
            let to_ =
              let end_ = Jv.get range "end" in
              Lsp_client.LSPPlugin.from_position plugin ~pos:end_ ()
            in
            View.Decoration.range ~from ~to_ decoration
          in
          let res = Jv.to_option (Jv.to_list of_document_highlight) res in
          let res = Option.value ~default:[] res in
          let res = State.RangeSet.of_ ~sort:true res in
          let res = Option.value ~default:View.Decoration.none res in
          let state_effect = State.StateEffect.of_ state_effect res in
          View.EditorView.dispatch view
            (State.TransactionSpec.create ~effects:[ state_effect ] ())
      | Error _ -> ())

let plugin =
  View.ViewPlugin.define @@ fun view ->
  let update (update : View.EditorView.Update.t) =
    let s =
      View.EditorView.Update.selection_set update
      || View.EditorView.Update.doc_changed update
    in
    if s then send_document_highlight view
  in
  View.PluginValue.create ~update ()

let extension_send = View.ViewPlugin.extension plugin

let view_extension =
  View.EditorView.base_theme
    (TO
       [
         ( ".cm-highlight-occurrences",
           TO [ ("backgroundColor", TV "#ff000040") ] );
       ])

let extension =
  Extension.of_list [ view_extension; extension_send; extension_field ]
