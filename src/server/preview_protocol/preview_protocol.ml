let update (root : Server_types.root) =
  let content =
    Slipshow.delayed_from_units ~has_speaker_view:false root.units
  in
  let warnings = Slipshow.to_grace root.units root.diagnostics in
  let warnings =
    List.map
      (Format.asprintf "%a@.@."
         (Grace_ansi_renderer.pp_diagnostic ?config:None
            ~code_to_string:Diagnosis.to_code))
      warnings
  in
  let warnings = List.map (Ansi.process (Ansi.create ())) warnings in
  let warnings = warnings |> String.concat "" in
  let content =
    { Proto.content = (content, warnings); version = root.version }
  in
  Proto.Server_to_client.Update content

let of_event root (to_server : Server_types.to_server) =
  match to_server with
  | Update -> update root
  | Control c -> Control c
  | ActivateGUI id -> Replace (Some id)
  | DeActivateGUI -> Replace None
  | Notify s -> Notify s
