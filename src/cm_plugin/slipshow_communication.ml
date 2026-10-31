open Code_mirror

let preview ?slipshow_js ?options () =
  let id = ref 0 in
  let open Fut.Syntax in
  fun ~ms state content ->
    incr id;
    let my_id = !id in
    let+ () = Fut.tick ~ms in
    if my_id = !id then Previewer.preview ?slipshow_js ?options state content

let update_slipshow ?slipshow_js ?options () =
  let preview = preview ?slipshow_js ?options () in
  fun state view ->
    let content =
      let state = View.EditorView.state view in
      let text = State.EditorState.doc state in
      let lines =
        State.Text.to_jstr_array text
        |> Array.map Jstr.to_string |> Array.to_list
      in
      String.concat "\n" lines
    in
    preview state content

let view_plugin ?slipshow_js ?options ~errors_el preview_element =
  let update_slipshow = update_slipshow ?slipshow_js ?options () in
  View.ViewPlugin.define (fun view ->
      let state =
        Previewer.create_previewer ~include_speaker_view:false ~errors_el
          ~steal_focus:false ~can_save:false ~can_gui:false
          ~save_coordinate:(fun ~id:_ ~coord:_ -> ())
          ~goto_loc:(fun _ -> ())
          preview_element
      in
      let _ : unit Fut.t = update_slipshow ~ms:0 state view in
      let update upd =
        let _ : unit Fut.t =
          if View.EditorView.Update.doc_changed upd then
            update_slipshow ~ms:500 state view
          else Fut.return ()
        in
        ()
      in
      View.PluginValue.create ~update ())

let extension ?slipshow_js ?options ~errors_el preview_element =
  view_plugin ?slipshow_js ?options ~errors_el preview_element
  |> View.ViewPlugin.extension
