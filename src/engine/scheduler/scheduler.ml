module Date = struct
  let date = Jv.get Jv.global "Date"
  let now () = Jv.call date "now" [||] |> Jv.to_int

  let soi i =
    if i = 0 then "00"
    else if i < 10 then "0" ^ string_of_int i
    else string_of_int i

  let string_of_t ms =
    let t = ms / 1000 in
    let s = t mod 60 in
    let m = t / 60 in
    let h = m / 60 in
    let m = m mod 60 in
    soi h ^ ":" ^ soi m ^ ":" ^ soi s

  let setup_timer el =
    let timer_mode = ref (`Since (now ())) in
    let timer = Brr.El.span [] in
    let restart =
      Brr.El.input
        ~at:[ Brr.At.type' (Jstr.v "button"); Brr.At.value (Jstr.v "Restart") ]
        ()
    in
    let pause =
      Brr.El.input
        ~at:
          [
            Brr.At.type' (Jstr.v "button");
            Brr.At.value (Jstr.v "Play/Pause");
            Brr.At.style (Jstr.v "margin-left: 20px");
          ]
        ()
    in
    let current_time = ref "" in
    let _ =
      Brr.Ev.listen Brr.Ev.click
        (fun _ ->
          match !timer_mode with
          | `Since n -> timer_mode := `Since (now ())
          | `Paused_at n -> timer_mode := `Paused_at 0)
        (Brr.El.as_target restart)
    in
    let _ =
      Brr.Ev.listen Brr.Ev.click
        (fun _ ->
          match !timer_mode with
          | `Since n -> timer_mode := `Paused_at (now () - n)
          | `Paused_at n -> timer_mode := `Since (now () - n))
        (Brr.El.as_target pause)
    in
    Brr.El.set_children el [ timer; pause; restart ];
    Brr.G.set_interval ~ms:100 (fun () ->
        let v =
          match !timer_mode with `Since n -> now () - n | `Paused_at n -> n
        in
        let new_current_time = "⏱️ " ^ string_of_t v in
        if not (String.equal !current_time new_current_time) then (
          Brr.El.set_children timer [ Brr.El.txt' new_current_time ];
          current_time := new_current_time))

  let clock el =
    let write_date () =
      let now = Jv.new' date [||] in
      let hours = Jv.call now "getHours" [||] |> Jv.to_int in
      let minutes = Jv.call now "getMinutes" [||] |> Jv.to_int in
      Brr.El.set_children el
        [ Brr.El.txt' ("⏰ " ^ soi hours ^ ":" ^ soi minutes) ]
    in
    write_date ();
    Brr.G.set_interval ~ms:20000 write_date
end

module Msg = struct
  type msg = Communication.t

  let of_jv m : msg option = m |> Jv.to_string |> Communication.of_string
end

let iframe = Brr.El.find_first_by_selector (Jstr.v "#ifra") |> Option.get
let src = Brr.El.at (Jstr.v "srcdoc") iframe |> Option.get

let html =
  {|
<!doctype html>
<html>
  <body>
    <iframe name="slipshow_speaker_view" id="speaker-view"></iframe>
    <div id="speaker-notes"><div id="slswrapper"><div id="timer"></div><div id="clock"></div><h2>Notes</h2><div id="notes_div"></div></div></div>
<script>
document.getElementById('speaker-view').addEventListener('load', function () {
    // Ensure iframe gets focus
    this.contentWindow.focus();
});
</script>
    <style>
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
      width:60%;
    }
    #speaker-notes {
      width:40%;
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
  Brr.Ev.listen Brr_io.Message.Ev.message
    (fun event ->
      let raw_data : Jv.t = Brr_io.Message.Ev.data (Brr.Ev.as_type event) in
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
    | { Communication.payload = Ready; _ } -> (
        match !current_step with
        | Some i ->
            let msg =
              { payload = State (i, `Fast) }
              |> Communication.to_string |> Jv.of_string
            in
            Brr.Window.post_message self ~msg
        | _ -> ())
    | _ -> ()

  let send_all_strokes_on_ready main_frame = function
    | { Communication.payload = Ready; _ } ->
        let msg =
          { payload = Send_all_drawing }
          |> Communication.to_string |> Jv.of_string
        in
        Brr.Window.post_message main_frame ~msg
    | _ -> ()

  let setting_state = function
    | { Communication.payload = State (i, _); _ } ->
        let _history = Browser.History.set_hash (string_of_int i) in
        current_step := Some i
    | _ -> ()

  let opening_speaker_note handle_msg = function
    | { Communication.payload = Open_speaker_notes; _ } ->
        open_window handle_msg
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
  ()

let main_frame_handling msg =
  let () =
    let forward_to =
      Option.map
        (fun (w, child_frame) -> (w, content_window child_frame))
        !speaker_view_ref
    in
    Handle.forwarding forward_to msg
  in
  let () = Handle.setting_state msg in
  let () = Handle.initial_state (content_window iframe) msg in
  let () = Handle.opening_speaker_note speaker_note_handling msg in
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
