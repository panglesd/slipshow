module Date = struct
  let date = Jv.get Jv.global "Date"
  let now () = Jv.call date "now" [||] |> Jv.to_int
  let initial_t = now ()

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
    Brr.G.set_interval ~ms:100 (fun () ->
        let now = now () in
        Brr.El.set_children el [ Brr.El.txt' (string_of_t (now - initial_t)) ];
        ())

  let clock el =
    let write_date () =
      let now = Jv.new' date [||] in
      let hours = Jv.call now "getHours" [||] |> Jv.to_int in
      let minutes = Jv.call now "getMinutes" [||] |> Jv.to_int in
      Brr.El.set_children el [ Brr.El.txt' (soi hours ^ ":" ^ soi minutes) ]
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
    <div id="speaker-notes"><div id="timer"></div><div id="clock"></div><h2>Notes</h2></div>
    <style>
    html, body {
      height: 100%;
      margin: 0;
      padding: 0;
    }
    body {
      display: flex;
    }
    #speaker-view {
      width:70%;
    }
    #speaker-notes {
      padding: 30px;
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

let receive_message forward_to self =
  let forward_message msg =
    match forward_to with
    | Some (window, iframe_window) when not (Brr.Window.closed window) ->
        Brr.Window.post_message iframe_window ~msg
    | _ -> ()
  in
  function
  | Some { Communication.payload = State (i, mode); _ } ->
      let _history = Browser.History.set_hash (string_of_int i) in
      current_step := Some i;
      let msg =
        { id = "hello"; payload = State (i, mode) }
        |> Communication.to_string |> Jv.of_string
      in
      forward_message msg
  | Some { Communication.payload = Receive_all_drawing _ as payload; _ } ->
      let msg =
        { id = "hello"; payload } |> Communication.to_string |> Jv.of_string
      in
      forward_message msg
  | Some { id = "hello"; payload = Drawing _ as payload } ->
      let msg =
        { id = "hello"; payload } |> Communication.to_string |> Jv.of_string
      in
      forward_message msg
  | Some { id = _; payload = Ready } -> (
      match !current_step with
      | Some i ->
          let msg =
            { id = "hello"; payload = State (i, `Fast) }
            |> Communication.to_string |> Jv.of_string
          in
          Brr.Window.post_message self ~msg;
          let msg =
            { id = "hello"; payload = Send_all_drawing }
            |> Communication.to_string |> Jv.of_string
          in
          forward_message msg
      | _ -> ())
  | _ -> ()

let open_window src =
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
            Brr.Ev.listen Brr_io.Message.Ev.message
              (fun event ->
                let raw_data : Jv.t =
                  Brr_io.Message.Ev.data (Brr.Ev.as_type event)
                in
                let msg = Msg.of_jv raw_data in
                receive_message
                  (Some (Brr.G.window, content_window iframe))
                  (content_window child_iframe)
                  msg)
              (Brr.Window.as_target child)
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

let receive_message_main = function
  | Some { Communication.id = "hello"; payload = Open_speaker_notes } ->
      open_window src;
      ()
  | msg ->
      let forward_to =
        Option.map
          (fun (w, child_frame) -> (w, content_window child_frame))
          !speaker_view_ref
      in
      receive_message forward_to (content_window iframe) msg

let _ =
  Brr.Ev.listen Brr_io.Message.Ev.message
    (fun event ->
      let raw_data : Jv.t = Brr_io.Message.Ev.data (Brr.Ev.as_type event) in
      let msg = Msg.of_jv raw_data in
      receive_message_main msg)
    (Brr.Window.as_target Brr.G.window)

let _ =
  Brr.Ev.listen Brr.Ev.beforeunload
    (fun _event ->
      match !speaker_view_ref with
      | None -> ()
      | Some (w, _) -> Brr.Window.close w)
    (Brr.Window.as_target Brr.G.window)
