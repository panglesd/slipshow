module Date = struct
  let date = Jv.get Jv.global "Date"
  let now () = Jv.call date "now" [||] |> Jv.to_int
  let initial_t = now ()

  let string_of_t ms =
    let t = ms / 1000 in
    let s = t mod 60 in
    let m = s / 60 in
    let h = m / 60 in
    let m = m mod 60 in
    let soi i =
      if i = 0 then "00"
      else if i < 10 then "0" ^ string_of_int i
      else string_of_int i
    in
    soi h ^ ":" ^ soi m ^ ":" ^ soi s

  let setup_timer el =
    Brr.G.set_interval ~ms:100 (fun () ->
        let now = now () in
        Brr.El.set_children el [ Brr.El.txt' (string_of_t (now - initial_t)) ];
        ())
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
    <div id="speaker-notes"><div id="timer"></div><h2>Notes</h2></div>
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
    <script>
      window.addEventListener("message", (event) => {
        if (window.opener) {
          window.opener.postMessage(event.data);
        }
      });
    </script>
  </body>
</html>
|}
(* TODO: move this script to ocaml realm *)

(* TODO: Upstream to [Brr] *)
let document_of_window w =
  Jv.get (Brr.Window.to_jv w) "document" |> Brr.Document.of_jv

(* TODO: Upstream to [Brr] *)
let document_element d =
  Jv.get (Brr.Document.to_jv d) "documentElement" |> Brr.El.of_jv

(* TODO: Upstream to [Brr] *)
let window_name w = Jv.get (Brr.Window.to_jv w) "name" |> Brr.El.of_jv

(* TODO: Upstream to [Brr] *)
let window_set_name w n = Jv.set (Brr.Window.to_jv w) "name" (Jv.of_string n)

(* TODO: Upstream to [Brr] *)
let content_window w =
  Jv.get (Brr.El.to_jv w) "contentWindow" |> Brr.Window.of_jv

(* This is deprecated but sill works better than anything else *)
let document_write s d =
  Jv.call (Brr.Document.to_jv d) "write" [| Jv.of_jstr s |]

(* let document_inner_write s d = *)
(*   let document_element = document_element d in *)
(*   Jv.set (Brr.El.to_jv document_element) "innerHTML" (Jv.of_jstr s) *)

let document_close d = Jv.call (Brr.Document.to_jv d) "close" [||]
let current_step = ref None
let speaker_view_ref = ref None

let open_window s =
  match !speaker_view_ref with
  | Some (w, _) when not (Brr.Window.closed w) -> ()
  | _ -> (
      let child =
        Brr.Window.open' ~features:(Jstr.v "popup") Brr.G.window
          (Jstr.of_string "")
      in
      match child with
      | None -> Brr.Console.(log [ "No child" ])
      | Some child ->
          window_set_name child "speaker-view";
          (* let _ = child |> document_of_window |> document_inner_write s in *)
          let _ = child |> document_of_window |> document_write (Jstr.v html) in
          let _ = child |> document_of_window |> document_close in
          let el = child |> document_of_window |> document_element in
          let child_iframe =
            Brr.El.find_first_by_selector ~root:el (Jstr.v "#speaker-view")
            |> Option.get
          in
          speaker_view_ref := Some (child, child_iframe);
          Brr.El.set_at (Jstr.v "srcdoc") (Some src) child_iframe;
          let timer =
            Brr.El.find_first_by_selector ~root:el (Jstr.v "#timer")
            |> Option.get
          in
          let _untimer = Date.setup_timer timer in
          Brr.Console.(log [ "Done" ]))

let receive_message_speaker_view = function
  | Some { Communication.payload = State i; _ } ->
      current_step := Some i;
      let msg =
        { id = "hello"; payload = State i }
        |> Communication.to_string |> Jv.of_string
      in
      Brr.Window.post_message (content_window iframe) ~msg
  | Some { Communication.id = _; payload = Ready } -> (
      match (!current_step, !speaker_view_ref) with
      | Some i, Some (w, child_frame) when not (Brr.Window.closed w) ->
          let msg =
            { id = "hello"; payload = State i }
            |> Communication.to_string |> Jv.of_string
          in
          Fut.await (Fut.tick ~ms:000) (fun _ ->
              Brr.Console.(log [ "Sending initial state"; i ]);
              Brr.Window.post_message (content_window child_frame) ~msg)
      | _ -> ())
  | _ -> ()

let receive_message_main = function
  | Some { Communication.id = "hello"; payload = Open_speaker_notes } ->
      Brr.Console.(log [ "Receiving an order to open the speaker notes" ]);
      open_window src;
      ()
  | Some { id = "hello"; payload = State i } -> (
      current_step := Some i;
      match !speaker_view_ref with
      | Some (w, child_frame) when not (Brr.Window.closed w) ->
          let msg =
            { id = "hello"; payload = State i }
            |> Communication.to_string |> Jv.of_string
          in
          Brr.Window.post_message (content_window child_frame) ~msg
      | _ -> ())
  | _ -> ()

let _ =
  Brr.Ev.listen Brr_io.Message.Ev.message
    (fun event ->
      let source =
        Brr_io.Message.Ev.source (Brr.Ev.as_type event) |> Option.get
      in
      (* TODO: use window_name *)
      let source_name = Jv.get source "name" |> Jv.to_string in
      let raw_data : Jv.t = Brr_io.Message.Ev.data (Brr.Ev.as_type event) in
      let msg = Msg.of_jv raw_data in
      match source_name with
      | "speaker-view" -> receive_message_speaker_view msg
      | "slipshow_main_pres" -> receive_message_main msg
      | _ -> ())
    (Brr.Window.as_target Brr.G.window)

let _ =
  Brr.Ev.listen Brr.Ev.beforeunload
    (fun event ->
      match !speaker_view_ref with
      | None -> ()
      | Some (w, _) -> Brr.Window.close w)
    (Brr.Window.as_target Brr.G.window)
