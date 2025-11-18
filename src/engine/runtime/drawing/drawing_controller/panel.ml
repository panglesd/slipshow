open Lwd_infix
open Drawing_state.Live_coding
open Brr_lwd

let set_handler v value = Elwd.handler Brr.Ev.click (fun _ -> Lwd.set v value)
let ( !! ) = Jstr.v

let panel_icon ?ev ?(at = []) ?st el =
  Elwd.div ?ev ~at:(`P (Brr.At.class' !!"slipshow-icon") :: at) ?st el

let panel_button ?label_for ?shortcut ?handler ?(at = []) ~icon text =
  let shortcut =
    match shortcut with
    | None -> []
    | Some shortcut ->
        [
          `P
            (Brr.El.kbd
               ~at:[ Brr.At.class' !!"slipshow-key" ]
               [ Brr.El.txt' shortcut ]);
        ]
  in
  let text =
    let txt =
      match label_for with
      | None -> Brr.El.txt' text
      | Some lbl ->
          Brr.El.label
            ~at:[ Brr.At.style !!"cursor:pointer"; Brr.At.for' !!lbl ]
            [ Brr.El.txt' text ]
    in
    Brr.El.div ~at:[ Brr.At.style !!"flex-grow:11" ] [ txt ]
  in
  Elwd.div
    ~at:(`P (Brr.At.class' !!"slipshow-button") :: at)
    ~ev:(match handler with None -> [] | Some c -> [ `P c ])
    ([ `R icon; `P text ] @ shortcut)

let panel_block ?class_ ~buttons () =
  Elwd.div
    ~at:
      ((match class_ with None -> [] | Some c -> [ `P (Brr.At.class' !!c) ])
      @ [ `P (Brr.At.class' !!"tool-block") ])
    buttons

let svg_button v (value : live_drawing_tool) svg name shortcut =
  let handler = set_handler v value in
  let button = Brr.El.div [] in
  let _ = Jv.set (Brr.El.to_jv button) "innerHTML" (Jv.of_string svg) in
  let at =
    let class_ =
      let$ current_tool = Lwd.get v in
      if current_tool = value then
        Lwd_seq.of_list [ Brr.At.class' !!"slip-set-tool" ]
      else Lwd_seq.of_list []
    in
    [ `S class_ ]
  in
  let icon = panel_icon ~at [ `P button ] in
  panel_button ~handler ~icon name ~shortcut

let pen_button v =
  svg_button v (Stroker Pen)
    {|<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="20" height="20" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path class="clr-i-outline clr-i-outline-path-1" d="M33.87 8.32L28 2.42a2.07 2.07 0 0 0-2.92 0L4.27 23.2l-1.9 8.2a2.06 2.06 0 0 0 2 2.5a2.14 2.14 0 0 0 .43 0l8.29-1.9l20.78-20.76a2.07 2.07 0 0 0 0-2.92zM12.09 30.2l-7.77 1.63l1.77-7.62L21.66 8.7l6 6zM29 13.25l-6-6l3.48-3.46l5.9 6z" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>|}

let highlighter_button v =
  svg_button v (Stroker Highlighter)
    {|<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="25" height="25" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path d="M15.82 26.06a1 1 0 0 1-.71-.29l-6.44-6.44a1 1 0 0 1-.29-.71a1 1 0 0 1 .29-.71L23 3.54a5.55 5.55 0 1 1 7.85 7.86L16.53 25.77a1 1 0 0 1-.71.29zm-5-7.44l5 5L29.48 10a3.54 3.54 0 0 0 0-5a3.63 3.63 0 0 0-5 0z" class="clr-i-outline clr-i-outline-path-1" fill="#000000"/><path d="M10.38 28.28a1 1 0 0 1-.71-.28l-3.22-3.23a1 1 0 0 1-.22-1.09l2.22-5.44a1 1 0 0 1 1.63-.33l6.45 6.44A1 1 0 0 1 16.2 26l-5.44 2.22a1.33 1.33 0 0 1-.38.06zm-2.05-4.46l2.29 2.28l3.43-1.4l-4.31-4.31z" class="clr-i-outline clr-i-outline-path-2" fill="#000000"/><path d="M8.94 30h-5a1 1 0 0 1-.84-1.55l3.22-4.94a1 1 0 0 1 1.55-.16l3.21 3.22a1 1 0 0 1 .06 1.35L9.7 29.64a1 1 0 0 1-.76.36zm-3.16-2h2.69l.53-.66l-1.7-1.7z" class="clr-i-outline clr-i-outline-path-3" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>|}

let erase_button v =
  svg_button v Eraser
    {|<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="20" height="20" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path d="M35.62 12a2.82 2.82 0 0 0-.84-2l-7.29-7.35a2.9 2.9 0 0 0-4 0L2.83 23.28a2.84 2.84 0 0 0 0 4L7.53 32H3a1 1 0 0 0 0 2h25a1 1 0 0 0 0-2H16.74l18-18a2.82 2.82 0 0 0 .88-2zM13.91 32h-3.55l-6.11-6.11a.84.84 0 0 1 0-1.19l5.51-5.52l8.49 8.48zm19.46-19.46L19.66 26.25l-8.48-8.49l13.7-13.7a.86.86 0 0 1 1.19 0l7.3 7.29a.86.86 0 0 1 .25.6a.82.82 0 0 1-.25.59z" class="clr-i-outline clr-i-outline-path-1" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>|}

let cursor_button v =
  svg_button v Pointer
    {|<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="20" height="20" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path class="clr-i-outline clr-i-outline-path-1" d="M14.58 32.31a1 1 0 0 1-.94-.65L4 5.65a1 1 0 0 1 1.25-1.28l26 9.68a1 1 0 0 1-.05 1.89l-8.36 2.57l8.3 8.3a1 1 0 0 1 0 1.41l-3.26 3.26a1 1 0 0 1-.71.29a1 1 0 0 1-.71-.29l-8.33-8.33l-2.6 8.45a1 1 0 0 1-.93.71zm3.09-12a1 1 0 0 1 .71.29l8.79 8.79L29 27.51l-8.76-8.76a1 1 0 0 1 .41-1.66l7.13-2.2L6.6 7l7.89 21.2l2.22-7.2a1 1 0 0 1 .71-.68z" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>|}

let color_button var color color_name =
  let icon =
    let at =
      let class_ =
        let$ current_color = Lwd.get var in
        if current_color = color then
          Lwd_seq.element (Brr.At.class' !!"slip-set-color")
        else Lwd_seq.empty
      in
      [ `S class_ ]
    in
    let st = [ `P (Brr.El.Style.background_color, !!color) ] in
    panel_icon ~at ~st []
  in
  panel_button ~handler:(set_handler var color) ~icon color_name

let custom_color_button var =
  let label = "slipshow-custom-color-name" in
  let icon =
    let at =
      let class_ =
        let$ current_color = Lwd.get var in
        let normal_colors =
          [ "#000000"; "#0000ff"; "#ff0000"; "#008000"; "#ffff00" ]
        in
        if not (List.exists (fun color -> color = current_color) normal_colors)
        then Lwd_seq.element (Brr.At.class' !!"slip-set-color")
        else Lwd_seq.empty
      in
      [ `S class_ ]
    in
    let ev =
      let callback ev =
        let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
        let color = Jv.get el "value" |> Jv.to_string in
        Lwd.set var color
      in
      [ `P (Elwd.handler Brr.Ev.change callback) ]
    in
    panel_icon ~ev ~at
      [ `P (Brr.El.input ~at:[ Brr.At.type' !!"color"; Brr.At.id !!label ] ()) ]
  in
  panel_button ~label_for:label ~icon "Custom color"

let width_button var width c name =
  let icon =
    let at =
      let class_ =
        let$ current_width = Lwd.get var in
        if current_width = width then
          Lwd_seq.element (Brr.At.class' !!"slip-set-width")
        else Lwd_seq.empty
      in
      [
        `S class_; `P (Brr.At.class' !!c); `P (Brr.At.class' !!"slipshow-icon");
      ]
    in
    Elwd.div ~at [ `P (Brr.El.div []) ]
  in
  let ev = [ `P (set_handler var width) ] in
  let at = [ `P (Brr.At.class' !!"slipshow-button") ] in
  Elwd.div ~at ~ev [ `R icon; `P (Brr.El.txt' name) ]

let toplevel_panel_el =
  Elwd.div ~at:[ `P (Brr.At.class' !!"slip-writing-toolbar") ]

let drawing_panel mode =
  let workspace =
    match mode with
    | Presenting -> Drawing_state.Live_coding.workspaces.live_drawing
    | Recording _ ->
        Drawing_state.Live_coding.workspaces.current_recording.recording.strokes
  in
  let lds = Drawing_state.Live_coding.live_drawing_state in
  let pen_button = pen_button lds.tool "Pen" "p" in
  let highlighter_button = highlighter_button lds.tool "Highlighter" "h" in
  let erase_button = erase_button lds.tool "Erase" "e" in
  let cursor_button = cursor_button lds.tool "Cursor" "c" in
  let tool_buttons =
    Elwd.div
      ~at:[ `P (Brr.At.class' !!"tool-block") ]
      [
        `R pen_button; `R highlighter_button; `R erase_button; `R cursor_button;
      ]
  in
  let color_buttons =
    let black_button = color_button lds.color "#000000" "Black" in
    let blue_button = color_button lds.color "#0000ff" "Blue" in
    let red_button = color_button lds.color "#ff0000" "Red" in
    let green_button = color_button lds.color "#008000" "Green" in
    let yellow_button = color_button lds.color "#ffff00" "Yellow" in
    let custom_color_button = custom_color_button lds.color in

    Elwd.div
      ~at:[ `P (Brr.At.class' !!"tool-block") ]
      [
        `R black_button;
        `R blue_button;
        `R red_button;
        `R green_button;
        `R yellow_button;
        `R custom_color_button;
      ]
  in
  let width_buttons =
    let small_button = width_button lds.width 5. "slip-toolbar-small" "Small" in
    let medium_button =
      width_button lds.width 15. "slip-toolbar-medium" "Medium"
    in
    let large_button =
      width_button lds.width 25. "slip-toolbar-large" "Large"
    in
    Elwd.div
      ~at:
        [
          `P (Brr.At.class' !!"slip-toolbar-width");
          `P (Brr.At.class' !!"tool-block");
        ]
      [ `R small_button; `R medium_button; `R large_button ]
  in
  let clear_button =
    let handler =
      Elwd.handler Brr.Ev.click (fun _ ->
          let started_at =
            match mode with
            | Presenting -> Tools.now ()
            | Recording { started_at } -> started_at
          in
          Tools.Clear.event started_at workspace)
    in
    let icon = panel_icon [ `P (Brr.El.txt !!"✗") ] in
    panel_block
      ~buttons:[ `R (panel_button ~handler ~icon "Clear" ~shortcut:"X") ]
      ()
  in
  let record_button =
    match mode with
    | Presenting ->
        let handler =
          Elwd.handler Brr.Ev.click (fun _ -> Lwd.set status Editing)
        in
        let icon = panel_icon [ `P (Brr.El.txt !!"") ] in
        panel_block ~class_:"slipshow-manage-recording-block"
          ~buttons:
            [
              `R (panel_button ~handler ~icon "Manage recordings" ~shortcut:"R");
            ]
          ()
    | Recording state ->
        let handler =
          Elwd.handler Brr.Ev.click (fun _ -> finish_recording state)
        in
        let icon =
          Brr.El.div
            ~at:[ Brr.At.style !!"width:10px;height:10px;background:red;" ]
            []
        in
        let icon = panel_icon [ `P icon ] in
        panel_block
          ~buttons:
            [ `R (panel_button ~shortcut:"R" ~handler ~icon "Stop recording") ]
          ()
  in
  toplevel_panel_el
    [
      `R tool_buttons;
      `R color_buttons;
      `R width_buttons;
      `R clear_button;
      `R record_button;
    ]

let editing_panel =
  let editing_tool v icon name shortcut =
    let handler = Elwd.handler Brr.Ev.click (fun _ -> Lwd.set editing_tool v) in
    let class_ =
      let$ current_tool = Lwd.get editing_tool in
      if current_tool = v then
        Lwd_seq.of_list [ Brr.At.class' !!"slip-set-tool" ]
      else Lwd_seq.of_list []
    in
    let icon = panel_icon ~at:[ `S class_ ] [ `P (Brr.El.txt' icon) ] in
    panel_button ~handler ~icon name ~shortcut
  in
  let select = editing_tool Select "☝" "Select" "s" in
  let move = editing_tool Move "⌖" "Move" "m" in
  let resize = editing_tool Rescale "⇲" "Resize" "r" in
  let block = panel_block ~buttons:[ `R select; `R move; `R resize ] () in
  let recording_block =
    let record =
      let handler =
        Elwd.handler Brr.Ev.click (fun _ ->
            Drawing_state.Live_coding.start_recording ())
      in
      let icon =
        Brr.El.div
          ~at:
            [
              Brr.At.style
                !!"width:10px;height:10px;background:red;border-radius:5px";
            ]
          []
      in
      let icon = panel_icon [ `P icon ] in
      panel_button ~handler ~icon "Record a drawing" ~shortcut:"R"
    in
    panel_block ~buttons:[ `R record ] ()
  in
  toplevel_panel_el [ `R block; `R recording_block ]

let panel =
  let content =
    let$* status = Lwd.get Drawing_state.Live_coding.status in
    match status with Drawing d -> drawing_panel d | Editing -> editing_panel
  in
  Elwd.div ~at:[ `P (Brr.At.id !!"slipshow-drawing-toolbar") ] [ `R content ]
