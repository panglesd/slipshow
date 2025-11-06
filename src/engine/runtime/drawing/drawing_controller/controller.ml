let drawing_handler d key =
  let strokes =
    match d with
    | Drawing_state.Live_coding.Presenting ->
        Drawing_state.Live_coding.workspaces.live_drawing
    | Recording { recording = { strokes; _ }; _ } -> strokes
  in
  match key with
  | "w" ->
      Lwd.set Drawing_state.Live_coding.live_drawing_state.tool (Stroker Pen);
      true
  | "h" ->
      Lwd.set Drawing_state.Live_coding.live_drawing_state.tool
        (Stroker Highlighter);
      true
  | "e" ->
      Lwd.set Drawing_state.Live_coding.live_drawing_state.tool Eraser;
      true
  | "x" ->
      Lwd.set Drawing_state.Live_coding.live_drawing_state.tool Pointer;
      true
  | "X" ->
      Tools.Clear.event strokes;
      true
  | _ -> false

let handle ev =
  let key = ev |> Brr.Ev.as_type |> Brr.Ev.Keyboard.key |> Jstr.to_string in
  match Lwd.peek Drawing_state.Live_coding.status with
  | Drawing d -> drawing_handler d key
  | Editing _ -> false
