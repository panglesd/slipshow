open Drawing_state

let shortcut_editing global (replaying_state : replaying_state) key =
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
      start_recording global replaying_state;
      true
  | " " ->
      (match Lwd.peek replaying_state.is_playing with
      | true -> Lwd.set replaying_state.is_playing false
      | false ->
          Ui.play global replaying_state;
          Lwd.set replaying_state.is_playing true);
      true
  | "ArrowRight" ->
      Lwd.update
        (fun t ->
          let total_time = Lwd.peek replaying_state.recording.total_time in
          let res = t +. (total_time /. 100.) in
          Float.min res total_time)
        replaying_state.time;
      true
  | "ArrowLeft" ->
      Lwd.update
        (fun t ->
          let total_time = Lwd.peek replaying_state.recording.total_time in
          Float.max (t -. (total_time /. 100.)) 0.)
        replaying_state.time;
      true
  | _ -> false

let shortcut_drawing global mode key =
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
        | Presenting -> (workspaces.live_drawing, Tools.now global (), None)
        | Recording { started_at; replayed_part; recording_temp; _ } ->
            (recording_temp, started_at, Some replayed_part)
      in
      Tools.Clear.event global ~replayed_strokes started_at strokes;
      true
  | "R" ->
      (match mode with
      | Presenting -> Lwd.set status Editing
      | Recording state -> finish_recording global state);
      true
  | _ -> false

let shortcuts global key =
  match Lwd.peek status with
  | Drawing mode -> shortcut_drawing global mode key
  | Editing -> shortcut_editing global (Lwd.peek current_replaying_state) key

let handle global ev =
  let key = ev |> Brr.Ev.as_type |> Brr.Ev.Keyboard.key |> Jstr.to_string in
  shortcuts global key
