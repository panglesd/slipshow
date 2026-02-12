module Msg = struct
  type msg = Communication.t

  let of_jv m : msg option = m |> Jv.to_string |> Communication.of_string
end

let iframe =
  Brr.El.find_first_by_selector (Jstr.v "#slipshow__internal_iframe")
  |> Option.get

let src = Brr.El.at (Jstr.v "srcdoc") iframe |> Option.get

let html =
  (* If you change the speaker view name, you should change the speaker view
     detection in the [play-media] action. *)
  {|
<!doctype html>
<html>
  <body class="clone-mode">
    <div id=slipshow__mirror-view><video autoplay></video></div>
    <iframe name="slipshow_speaker_view" id="speaker-view"></iframe>
    <div id="speaker-notes">
      <div id="slswrapper">
        <div id="timer"></div>
        <div id="clock"></div>
        <p id=mirror-button-div>
          <button id="slipshow__mirror-view-button">Use Mirror view</button>
          <span>Mirror an other screen. Select the screen your audience sees, and move the mouse there. Useful if you need to interact with the presentation, or another window, but still want to see your notes.</span>
        </p>
        <p id=clone-button-div>
          <button id="slipshow__cloned-view-button">Stop Mirror view</button>
          <span>Stop mirroring another screen, and go back to a synchronized clone.</span>
        </p>
        <h2>Notes</h2>
        <div id="notes_div"></div>
      </div>
    </div>
    <script>
    document.getElementById('speaker-view').addEventListener('load', function () {
        // Ensure iframe gets focus
        this.contentWindow.focus();
    });
    </script>
    <style>
    #slipshow__mirror-view {
      background: black;
    }
    button, input[type=button] {
      font-size: 20px;
    }
    .mirror-mode #slipshow__mirror-view {
      display: flex;
      width: 100%;
    }
    .mirror-mode #slipshow__mirror-view video {
      width: 100%;
    }
    .clone-mode #slipshow__mirror-view {
      display: none;
    }
    .mirror-mode #speaker-view {
      display: none;
    }
    .clone-mode #speaker-view {
    }
    .mirror-mode #mirror-button-div {
      display: none;
    }
    .clone-mode #clone-button-div {
      display: none;
    }
    #timer {
      font-size: 2em;
    }
    #clock {
      font-size: 2em;
    }
    html, body {
      height: 100%;
      margin: 0;
      padding: 0;
    }
    #slswrapper {
      padding: 30px;
      font-size: 2em;
    }
    body {
      display: flex;
    }
    #speaker-view {
      width:100%;
    }
    #speaker-notes {
      width:35%;
      overflow: scroll;
      flex-shrink:0;
    }
    </style>
  </body>
</html>
|}

let content_window w =
  Jv.get (Brr.El.to_jv w) "contentWindow" |> Brr.Window.of_jv

(* This is deprecated but sill works better than anything else *)
let document_write s d =
  Jv.call (Brr.Document.to_jv d) "write" [| Jv.of_jstr s |] |> ignore

(* let document_inner_write s d = *)
(*   let document_element = document_element d in *)
(*   Jv.set (Brr.El.to_jv document_element) "innerHTML" (Jv.of_jstr s) *)

let document_close d = Jv.call (Brr.Document.to_jv d) "close" [||] |> ignore

let current_step =
  ref
    (Brr.G.window |> Brr.Window.location |> Brr.Uri.fragment |> Jstr.to_string
   |> int_of_string_opt)

let speaker_view_ref = ref None

let listen w handle_msg =
  let _ =
    Brr.Ev.listen Brr.Ev.beforeunload
      (fun _event ->
        let msg =
          { payload = Close_speaker_notes; id = "TODO" }
          |> Communication.to_string |> Jv.of_string
        in
        match Brr.Window.parent Brr.G.window with
        | None -> ()
        | Some parent -> Brr.Window.post_message parent ~msg)
      (Brr.Window.as_target w)
  in
  Brr.Ev.listen Brr_io.Message.Ev.message
    (fun event ->
      let raw_data : Jv.t = Brr_io.Message.Ev.data (Brr.Ev.as_type event) in
      Brr.Console.(log [ "raw_data"; raw_data ]);
      let msg = Msg.of_jv raw_data in
      match msg with None -> () | Some msg -> handle_msg msg)
    (Brr.Window.as_target w)

let open_window handle_msg =
  match !speaker_view_ref with
  | Some (w, _) when not (Brr.Window.closed w) -> ()
  | _ -> (
      let child =
        Brr.Window.open' ~features:(Jstr.v "popup") Brr.G.window
          (Jstr.of_string "")
      in
      match child with
      | None -> Brr.Console.(error [ "Could not open speaker view" ])
      | Some child ->
          Brr.Window.set_name (Jstr.v "speaker-view") child;
          let document = Brr.Window.document child in
          let () = document_write (Jstr.v html) document in
          let () = document_close document in
          let el = Brr.Document.element document in
          let child_iframe =
            Brr.El.find_first_by_selector ~root:el (Jstr.v "#speaker-view")
            |> Option.get
          in
          let _unlisten =
            listen child (handle_msg (content_window child_iframe))
          in
          speaker_view_ref := Some (child, child_iframe);
          Brr.El.set_at (Jstr.v "srcdoc") (Some src) child_iframe;
          let mirror_button =
            Brr.El.find_first_by_selector ~root:el
              (Jstr.v "#slipshow__mirror-view-button")
            |> Option.get
          in
          let clone_button =
            Brr.El.find_first_by_selector ~root:el
              (Jstr.v "#slipshow__cloned-view-button")
            |> Option.get
          in
          let mirror_video =
            Brr.El.find_first_by_selector ~root:el
              (Jstr.v "#slipshow__mirror-view video")
            |> Option.get |> Brr_io.Media.El.of_el
          in
          let () =
            View_mode.setup ~speaker_view:child ~video_el:mirror_video
              ~mirror_button ~clone_button ~child_iframe ~src
          in
          let timer =
            Brr.El.find_first_by_selector ~root:el (Jstr.v "#timer")
            |> Option.get
          in
          let clock =
            Brr.El.find_first_by_selector ~root:el (Jstr.v "#clock")
            |> Option.get
          in
          let _untimer = Date.setup_timer timer in
          let _untimer = Date.clock clock in
          ())

let close_window () =
  match !speaker_view_ref with
  | Some (w, _) when not (Brr.Window.closed w) -> Brr.Window.close w
  | _ -> ()

module Handle = struct
  let forwarding forward_to =
    let forward_message msg =
      match forward_to with
      | Some (window, iframe_window) when not (Brr.Window.closed window) ->
          Brr.Window.post_message iframe_window ~msg
      | _ -> ()
    in
    function
    | { Communication.payload = State _ | Drawing _ | Receive_all_drawing _; _ }
      as msg ->
        let msg = msg |> Communication.to_string |> Jv.of_string in
        forward_message msg
    | _ -> ()

  let initial_state self = function
    | { Communication.payload = Ready; id } -> (
        match !current_step with
        | Some i ->
            let msg =
              { payload = State (i, `Fast); id }
              |> Communication.to_string |> Jv.of_string
            in
            Brr.Window.post_message self ~msg
        | _ -> ())
    | _ -> ()

  let send_all_strokes_on_ready main_frame = function
    | { Communication.payload = Ready; id } ->
        let msg =
          { payload = Send_all_drawing; id }
          |> Communication.to_string |> Jv.of_string
        in
        Brr.Window.post_message main_frame ~msg
    | _ -> ()

  let set_state_todo main_frame = function
    | { Communication.payload = Set_state (i, mode); id } ->
        let msg =
          { payload = State (i, mode); id }
          |> Communication.to_string |> Jv.of_string
        in
        Brr.Window.post_message main_frame ~msg
    | { Communication.payload = Stop_moving; _ } as msg ->
        let msg = msg |> Communication.to_string |> Jv.of_string in
        Brr.Window.post_message main_frame ~msg
    | _ -> ()

  let setting_state = function
    | { Communication.payload = State (i, _); _ } ->
        let _history = Browser.History.set_hash (string_of_int i) in
        current_step := Some i
    | _ -> ()

  let opening_closing_speaker_note handle_msg = function
    | { Communication.payload = Open_speaker_notes; _ } ->
        open_window handle_msg
    | { payload = Close_speaker_notes; id = _ } -> close_window ()
    | _ -> ()

  let forward_to_parent = function
    | msg -> (
        match Brr.Window.parent Brr.G.window with
        | None -> ()
        | Some parent ->
            let msg = msg |> Communication.to_string |> Jv.of_string in
            Brr.Window.post_message parent ~msg)

  let new_speaker_notes = function
    | { Communication.payload = Speaker_notes s; _ } -> (
        match !speaker_view_ref with
        | None -> ()
        | Some (window, _) ->
            let document = Brr.Window.document window in
            let root = Brr.Document.element document in
            let notes_elem =
              Brr.El.find_first_by_selector ~root (Jstr.v "#notes_div")
              |> Option.get
            in
            Jv.Jstr.set (Brr.El.to_jv notes_elem) "innerHTML" (Jstr.v s))
    | _ -> ()
end

let speaker_note_handling window msg =
  let () =
    let forward_to = Some (Brr.G.window, content_window iframe) in
    Handle.forwarding forward_to msg
  in
  let () = Handle.setting_state msg in
  let () = Handle.initial_state window msg in
  let () = Handle.send_all_strokes_on_ready (content_window iframe) msg in
  let () = Handle.new_speaker_notes msg in
  let () = Handle.forward_to_parent msg in
  ()

let main_frame_handling msg =
  let () =
    let forward_to =
      Option.bind !speaker_view_ref (fun (w, child_frame) ->
          if not @@ Brr.Window.closed w then Some (w, content_window child_frame)
          else (
            speaker_view_ref := None;
            None))
    in
    Handle.forwarding forward_to msg
  in
  let () = Handle.setting_state msg in
  let () = Handle.initial_state (content_window iframe) msg in
  let () = Handle.set_state_todo (content_window iframe) msg in
  let () = Handle.opening_closing_speaker_note speaker_note_handling msg in
  let () = Handle.forward_to_parent msg in
  ()

let _ = listen Brr.G.window main_frame_handling

let _ =
  Brr.Ev.listen Brr.Ev.beforeunload
    (fun _event ->
      match !speaker_view_ref with
      | None -> ()
      | Some (w, _) -> Brr.Window.close w)
    (Brr.Window.as_target Brr.G.window)
