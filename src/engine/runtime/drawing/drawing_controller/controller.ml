open Drawing_state

let shortcut_editing (editing_state : editing_state) key =
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
  | "R" ->
      start_recording editing_state.replaying_state;
      true
  | " " ->
      (match Lwd.peek editing_state.is_playing with
      | true -> Lwd.set editing_state.is_playing false
      | false ->
          Ui.play editing_state;
          Lwd.set editing_state.is_playing true);
      true
  | "ArrowRight" ->
      Lwd.update
        (fun t ->
          let total_time =
            Lwd.peek editing_state.replaying_state.recording.total_time
          in
          let res = t +. (total_time /. 100.) in
          Float.min res total_time)
        editing_state.replaying_state.time;
      true
  | "ArrowLeft" ->
      Lwd.update
        (fun t ->
          let total_time =
            Lwd.peek editing_state.replaying_state.recording.total_time
          in
          Float.max (t -. (total_time /. 100.)) 0.)
        editing_state.replaying_state.time;
      true
  | _ -> false

let shortcut_drawing mode key =
  match key with
  | "p" | "w" ->
      Lwd.set live_drawing_state.tool (Stroker Pen);
      true
  | "h" ->
      Lwd.set live_drawing_state.tool (Stroker Highlighter);
      true
  | "e" ->
      Lwd.set live_drawing_state.tool Eraser;
      true
  | "c" | "x" ->
      Lwd.set live_drawing_state.tool Pointer;
      true
  | "X" ->
      let strokes, started_at, replayed_strokes =
        match mode with
        | Presenting -> (workspaces.live_drawing, Tools.now (), None)
        | Recording { started_at; replayed_part; recording_temp; _ } ->
            (recording_temp, started_at, Some replayed_part)
      in
      Tools.Clear.event ~replayed_strokes started_at strokes;
      true
  | "R" ->
      (match mode with
      | Presenting -> Lwd.set status Editing
      | Recording state -> finish_recording state);
      true
  | _ -> false

let shortcuts key =
  match Lwd.peek status with
  | Drawing mode -> shortcut_drawing mode key
  | Editing -> shortcut_editing (Lwd.peek current_editing_state) key

let handle ev =
  let key = ev |> Brr.Ev.as_type |> Brr.Ev.Keyboard.key |> Jstr.to_string in
  shortcuts key
