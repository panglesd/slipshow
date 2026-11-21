open Code_mirror

let initial_doc =
  {|{#title}
# Slipshow in the browser

{gui}
This editor talks to the Slipshow LSP server, running in a web worker.

{up=title}
|}

let _ : (unit, _) result Fut.t =
  let find id = Brr.El.find_first_by_selector (Jstr.v id) |> Option.get in
  let basic_setup = Jv.get Jv.global "__CM__basic_setup" |> Extension.of_jv in
  let markdown =
    Jv.apply (Jv.get Jv.global "__CM__markdown") [||] |> Extension.of_jv
  in
  let open Fut.Result_syntax in
  let+ server = Lsp_js.create_server "lsp_worker.bc.js" in
  let path = Fpath.v "main.slp" in
  let extension = Lsp_js.extension server ~path in
  let () =
    Lsp_js.preview ~errors_el:(find "#errors") (find "#preview") server ~path
  in
  let config =
    State.EditorStateConfig.create ~doc:initial_doc
      ~extensions:(Extension.of_list [ basic_setup; markdown; extension ])
      ()
  in
  let state = State.EditorState.create ~config () in
  let config =
    View.EditorViewConfig.create ~state ~parent:(find "#editor") ()
  in
  let _view : View.EditorView.t = View.EditorView.create ~config () in
  ()
