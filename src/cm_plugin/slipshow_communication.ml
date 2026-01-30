open Code_mirror

let preview ?slipshow_js ?frontmatter ?read_file () =
  let id = ref 0 in
  let open Fut.Syntax in
  fun ~ms state content ->
    incr id;
    let my_id = !id in
    let+ () = Fut.tick ~ms in
    if my_id = !id then
      Previewer.preview ?slipshow_js ?frontmatter ?read_file state content

let update_slipshow ?slipshow_js ?frontmatter ?read_file () =
  let preview = preview ?slipshow_js ?frontmatter ?read_file () in
  fun state view ->
    let open Editor in
    let content =
      let state = View.state view in
      let text = State.doc state in
      let lines =
        Text.to_jstr_array text |> Array.map Jstr.to_string |> Array.to_list
      in
      String.concat "\n" lines
    in
    preview state content

let slipshow_plugin ?slipshow_js ?frontmatter ?read_file preview_element =
  let open Editor in
  let update_slipshow =
    update_slipshow ?slipshow_js ?frontmatter ?read_file ()
  in
  View.ViewPlugin.define (fun view ->
      let state =
        Previewer.create_previewer ~include_speaker_view:false preview_element
      in
      let _ : unit Fut.t = update_slipshow ~ms:0 state view in
      let update upd =
        let _ : unit Fut.t =
          if View.Update.docChanged upd then update_slipshow ~ms:500 state view
          else Fut.return ()
        in
        ()
      in
      let destruct () = () in
      { update; destruct })
