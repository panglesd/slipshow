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

let shortcut_editing key =
  match key with
  | "m" ->
      Lwd.set State.status Move;
      true
  | "s" ->
      Lwd.set State.status Select;
      true
  | "r" ->
      Lwd.set State.status Scale;
      true
  | "d" ->
      Lwd.set State.status Dimension;
      true
  | "Escape" ->
      Action.deactivate ();
      true
  | "G" ->
      Drawing_state.Status.set (Drawing Presenting);
      Action.deactivate ();
      true
  | _ -> false

let shortcuts key =
  match Drawing_state.Status.peek () with
  | Drawing _ | Editing -> false
  | Gui_mode -> shortcut_editing key

let handle ev =
  let key = ev |> Brr.Ev.as_type |> Brr.Ev.Keyboard.key |> Jstr.to_string in
  if check_in_textarea () then false else shortcuts key
