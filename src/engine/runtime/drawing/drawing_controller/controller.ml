open Drawing_state

let check_in_textarea () =
  (* This checks that we are not typing in a text input, to allow for editing *)
  let is_editable active_elem =
    if Brr.El.is_content_editable active_elem then true
    else
      let tag_name =
        Brr.El.tag_name active_elem |> Jstr.lowercased |> Jstr.to_string
      in
      match tag_name with
      | "input" | "textarea" | "select" | "button" -> true
      | _ -> false
  in
  let active_elem = Brr.Document.active_el Brr.G.document in
  (* We need to go inside shadow roots to check if focused content is editable *)
  let rec check active_elem =
    match active_elem with
    | None -> false
    | Some active_elem -> (
        if is_editable active_elem then true
        else
          match Brr.El.shadow_root active_elem with
          | None -> false
          | Some shadow_root ->
              check (Brr.El.Shadow_root.active_element shadow_root))
  in
  check active_elem

let shortcut_editing (replaying_state : replaying_state) key =
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
      start_recording replaying_state;
      true
  | " " ->
      (match Lwd.peek replaying_state.is_playing with
      | true -> Lwd.set replaying_state.is_playing false
      | false ->
          Ui.play replaying_state;
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
  | Editing -> shortcut_editing (Lwd.peek current_replaying_state) key

let handle ev =
  let key = ev |> Brr.Ev.as_type |> Brr.Ev.Keyboard.key |> Jstr.to_string in
  if check_in_textarea () then false else shortcuts key
