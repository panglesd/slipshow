let handle_message previewer msg =
  match msg with
  | Proto.Server_to_client.Pong -> ()
  | Update data ->
      (* version := data.version; *)
      Previewer.preview_compiled previewer data.content
  | Control (Movement Forward) -> Previewer.next previewer
  | Control (Movement Backward) -> Previewer.previous previewer
  | Saved path -> Previewer.notify previewer ("Saved drawing as: " ^ path)
  | Notify msg -> Previewer.notify previewer msg
  | Replace (Some id) -> Previewer.activate_gui previewer id
  | Replace None -> Previewer.deactivate_gui previewer
