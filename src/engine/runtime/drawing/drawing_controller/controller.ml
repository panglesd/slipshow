open Drawing_state.Live_coding

let shortcut_editing editing_state key =
  match key with
  | "m" ->
      Lwd.set editing_tool Move;
      true
  | "s" ->
      Lwd.set editing_tool Select;
      true
  | "r" ->
      Lwd.set editing_tool Rescale;
      true
  | " " ->
      (match Lwd.peek editing_state.is_playing with
      | true -> Lwd.set editing_state.is_playing false
      | false ->
          Ui.play editing_state;
          Lwd.set editing_state.is_playing true);
      true
  | _ -> false

let shortcut_drawing strokes mode key =
  match key with
  | "w" ->
      Lwd.set live_drawing_state.tool (Stroker Pen);
      true
  | "h" ->
      Lwd.set live_drawing_state.tool (Stroker Highlighter);
      true
  | "e" ->
      Lwd.set live_drawing_state.tool Eraser;
      true
  | "x" ->
      Lwd.set live_drawing_state.tool Pointer;
      true
  | "X" ->
      Tools.Clear.event strokes;
      true
  | "r" ->
      toggle_recording mode;
      true
  | _ -> false

let shortcuts key =
  match Lwd.peek status with
  | Drawing mode ->
      let strokes =
        match mode with
        | Presenting -> workspaces.live_drawing
        | Recording (* { recording = { strokes; _ }; _ } *) _ ->
            workspaces.current_recording.recording.strokes
      in
      shortcut_drawing strokes mode key
  | Editing editing_state -> shortcut_editing editing_state key

let handle ev =
  let key = ev |> Brr.Ev.as_type |> Brr.Ev.Keyboard.key |> Jstr.to_string in
  shortcuts key
