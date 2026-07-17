open Drawing_state
open Lwd_infix
open Brr_lwd

let ( !! ) = Jstr.v
let total_length (recording : recording) = Lwd.get recording.total_time

let slider (replaying_state : replaying_state) =
  let attrs =
    [
      `P (Brr.At.id !!"slipshow-time-slider");
      `P (Brr.At.class' !!"time-slider");
      `P (Brr.At.v !!"min" !!"0");
    ]
  in
  let prop =
    let max =
      let$ max = total_length replaying_state.recording in
      (!!"max", Jv.of_float max)
    in
    [ `R max ]
  in
  let el =
    Ui_widgets.float ~prop ~type':"range" ~kind:`Input replaying_state.time
      attrs
  in
  Elwd.div [ `R el ]

let description_of_selection (selection : Drawing_state.selection) =
  let n_selected =
    Brr.El.div
      [
        Brr.El.txt'
          (string_of_int (List.length selection.s_strokes)
          ^ " stroke(s) and "
          ^ string_of_int (List.length selection.s_erasures)
          ^ " erasure(s) and "
          ^ string_of_int (List.length selection.s_pauses)
          ^ " pause(s) selected");
      ]
  in
  let delete =
    let click_handler =
      Elwd.handler Brr.Ev.click (fun _ -> Drawing_state.delete selection)
    in
    Elwd.button ~ev:[ `P click_handler ] [ `P (Brr.El.txt' "Delete") ]
  in
  let description_of_strokes strokes =
    match strokes with
    | [] -> Elwd.div []
    | (_, stro) :: _ ->
        let set_color =
          let click_handler =
            Elwd.handler Brr.Ev.change (fun ev ->
                let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
                let color = Jv.get el "value" |> Jv.to_string in
                List.iter
                  (fun (_, (stroke : stro)) -> Lwd.set stroke.color color)
                  strokes)
          in
          let input =
            let current_value = Lwd.peek stro.color in
            let at =
              [ `P (Brr.At.type' !!"color"); `P (Brr.At.value !!current_value) ]
            in
            Elwd.input ~at ~ev:[ `P click_handler ] ()
          in
          Elwd.div [ `P (Brr.El.txt' "Set color: "); `R input ]
        in
        let set_width =
          let click_handler =
            Elwd.handler Brr.Ev.change (fun ev ->
                let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
                let width = Jv.get el "value" |> Jv.to_string in
                match float_of_string_opt width with
                | None -> ()
                | Some width ->
                    List.iter
                      (fun (_, (stroke : stro)) -> Lwd.set stroke.width width)
                      strokes)
          in
          let input =
            let current_value =
              let _, stro = List.hd strokes in
              Lwd.peek stro.width |> Jv.of_float |> Jv.to_jstr
            in
            let at =
              [ `P (Brr.At.type' !!"number"); `P (Brr.At.value current_value) ]
            in
            Elwd.input ~at ~ev:[ `P click_handler ] ()
          in
          Elwd.div [ `P (Brr.El.txt' "Set width: "); `R input ]
        in
        Elwd.div [ `R set_width; `R set_color ]
  in
  Elwd.div
    [
      `P n_selected; `R (description_of_strokes selection.s_strokes); `R delete;
    ]

let selection =
  let options =
    Lwd_table.map_reduce
      (fun _row workspace ->
        let name =
          let name = workspace.recording.name in
          Brr.El.txt' name
        in
        let recording_id = string_of_int workspace.recording.record_id in
        let value = Brr.At.value (Jstr.v recording_id) in
        let selected =
          let$ current_replaying_state = Lwd.get current_replaying_state in
          match current_replaying_state with
          | Some current_replaying_state
            when workspace.recording.record_id
                 = current_replaying_state.recording.record_id ->
              Lwd_seq.element Brr.At.selected
          | _ -> Lwd_seq.empty
        in
        Lwd_seq.element @@ Elwd.option ~at:[ `P value; `S selected ] [ `P name ])
      Lwd_seq.monoid workspaces.recordings
    |> Lwd_seq.lift
  in
  let change =
    Elwd.handler Brr.Ev.change (fun ev ->
        let record_id =
          let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
          Jv.get el "value" |> Jv.to_string |> int_of_string
        in
        let replaying_state =
          let exception Found of Drawing_state.replaying_state in
          try
            Lwd_table.iter
              (fun replaying_state ->
                if Int.equal replaying_state.recording.record_id record_id then
                  raise (Found replaying_state)
                else ())
              workspaces.recordings;
            None
          with Found r -> Some r
        in
        Lwd.set current_replaying_state replaying_state)
  in
  let select = Elwd.select ~ev:[ `P change ] [ `S options ] in
  let label = Brr.El.txt' "List of recordings: " in
  Elwd.div [ `P label; `R select ]

let global_panel recording =
  (* let total_time = *)
  (*   let total_time = Ui_widgets.float ~type':"number" recording.total_time [] in *)
  (*   Elwd.div [ `P (Brr.El.txt' "Total duration: "); `R total_time ] *)
  (* in *)
  let name_title = Brr.El.h3 [ Brr.El.txt' recording.name ] in
  let get_help =
    Brr.El.div
      [
        Brr.El.a
          ~at:
            [
              Brr.At.href
                !!"https://docs.slipshow.org/en/stable/record-and-replay.html";
            ]
          [ Brr.El.txt' "Get help in the documentation" ];
      ]
  in
  Elwd.div [ `R selection; `P name_title; `P get_help ]

let play (replaying_state : replaying_state) =
  Lwd.set replaying_state.is_playing true;
  let max = Lwd.peek replaying_state.recording.total_time in
  let start_time = now () -. Lwd.peek replaying_state.time in
  let current_time = ref @@ Tools.now () in
  let rec loop _ =
    let now = Tools.now () in
    let increment = now -. !current_time in
    current_time := now;
    let now = now -. start_time in
    let before = now -. increment in
    let has_crossed_pause =
      Lwd_table.fold
        (fun b (pause : Drawing_state.pause) ->
          match b with
          | Some _ as b -> b
          | None ->
              let at = Lwd.peek pause.p_at in
              if before <= at && at < now then Some at else None)
        None replaying_state.recording.pauses
    in
    match has_crossed_pause with
    | Some max_time ->
        Lwd.set replaying_state.time (Float.next_after max_time Float.infinity);
        Lwd.set replaying_state.is_playing false
    | None ->
        if now <= max && Lwd.peek replaying_state.is_playing then
          let () = Lwd.set replaying_state.time now in
          let _animation_frame_id = Brr.G.request_animation_frame loop in
          ()
        else if now > max && Lwd.peek replaying_state.is_playing then
          let () = Lwd.set replaying_state.time max in
          Lwd.set replaying_state.is_playing false
        else ()
  in
  loop 0.

let play_button editing_state =
  let$* is_playing = Lwd.get editing_state.is_playing in
  if is_playing then
    let click =
      Elwd.handler Brr.Ev.click (fun ev ->
          let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv |> Brr.El.of_jv in
          Brr.El.set_has_focus false el;
          Lwd.set editing_state.is_playing false)
    in
    Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "⏸ Pause") ]
  else
    let click = Elwd.handler Brr.Ev.click (fun _ -> play editing_state) in
    Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "▶ Play") ]

let make_download name s =
  let blob =
    let init = Brr.Blob.init ~type':(Jstr.v "application/json") () in
    Brr.Blob.of_jstr ~init (Jstr.v s)
  in
  let a = Brr.El.a [] in
  let revoke_url =
    let url = Jv.get Jv.global "URL" in
    let object_url = Jv.call url "createObjectURL" [| Brr.Blob.to_jv blob |] in
    Jv.set (Brr.El.to_jv a) "href" object_url;
    fun () ->
      (* RevokeURL should not happen before the download has started, which
         might happen asynchronously in some browsers, so we wait 1s just to be
         sure. *)
      let _cancel =
        Brr.G.set_timeout ~ms:1000 (fun () ->
            Jv.call url "revokeObjectURL" [| object_url |] |> ignore)
      in
      ()
  in
  let filename =
    let f =
      name |> String.lowercase_ascii
      |> String.map (function ' ' -> '-' | s -> s)
    in
    f ^ ".draw"
  in
  Jv.set (Brr.El.to_jv a) "download" (Jv.of_string filename);
  Jv.call (Brr.El.to_jv a) "click" [||] |> ignore;
  revoke_url ()

let save_button recording =
  let click =
    Elwd.handler Brr.Ev.click (fun ev ->
        let s = Drawing_state.Json.string_of_recording recording in
        let () =
          recording.file_path
          |> Option.iter @@ fun path -> Messaging.save_drawing ~path ~content:s
        in
        let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv |> Brr.El.of_jv in
        Brr.El.set_has_focus false el)
  in
  let can_save =
    let$ can_save = Lwd.get Drawing_state.can_save in
    if Option.is_none recording.file_path then
      Lwd_seq.of_list
        [
          Brr.At.disabled;
          Brr.At.title
            !!"Recording has no corresponding file, use \"Save As\" and \
               include the created file in the presentation with \
               ![description](path/to/file.draw)";
        ]
    else if not can_save then
      Lwd_seq.of_list
        [
          Brr.At.disabled;
          Brr.At.title
            !!"Can only save through a preview server, such as \"slipshow \
               serve\" or the LSP server";
        ]
    else Lwd_seq.empty
  in
  Elwd.button ~at:[ `S can_save ] ~ev:[ `P click ] [ `P (Brr.El.txt' "💾 Save") ]

let download_button recording =
  let click =
    Elwd.handler Brr.Ev.click (fun ev ->
        let s = Drawing_state.Json.string_of_recording recording in
        make_download recording.name s;
        let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv |> Brr.El.of_jv in
        Brr.El.set_has_focus false el)
  in
  Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "💾 Save As...") ]

let add_pause_button (replaying_state : replaying_state) =
  let click =
    Elwd.handler Brr.Ev.click (fun ev ->
        let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv |> Brr.El.of_jv in
        Brr.El.set_has_focus false el;
        let current_time = Lwd.peek replaying_state.time in
        let new_pause =
          {
            p_at = Lwd.var current_time;
            p_preselected = Lwd.var false;
            p_selected = Lwd.var false;
          }
        in
        Lwd_table.append' replaying_state.recording.pauses new_pause)
  in
  Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Add pause") ]

(* let select_button = *)
(*   let click = *)
(*     Elwd.handler Brr.Ev.click (fun _ -> Lwd.set editing_tool Select) *)
(*   in *)
(*   Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Select") ] *)

(* let move_button = *)
(*   let click = Elwd.handler Brr.Ev.click (fun _ -> Lwd.set editing_tool Move) in *)
(*   Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Move") ] *)

(* let scale_button = *)
(*   let click = *)
(*     Elwd.handler Brr.Ev.click (fun _ -> Lwd.set editing_tool Rescale) *)
(*   in *)
(*   Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Resize") ] *)

let close_button =
  let click =
    Elwd.handler Brr.Ev.click (fun ev ->
        let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv |> Brr.El.of_jv in
        Brr.El.set_has_focus false el;
        Status.set (Drawing Presenting))
  in
  Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Close editing panel") ]

let new_recording_button =
  let click =
    Elwd.handler Brr.Ev.click (fun ev ->
        let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv |> Brr.El.of_jv in
        Brr.El.set_has_focus false el;
        let recording =
          {
            strokes = Lwd_table.make ();
            pauses = Lwd_table.make ();
            total_time = Lwd.var 0.;
            name = "Anonymous recording";
            record_id = Random.bits ();
            file_path = None;
          }
        in
        let replaying_state =
          { recording; time = Lwd.var 0.; is_playing = Lwd.var false }
        in
        Lwd_table.append' workspaces.recordings replaying_state;
        Lwd.set current_replaying_state (Some replaying_state))
  in
  Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Create a new recording") ]

let el =
  let$* replaying_state = Lwd.get current_replaying_state in
  match replaying_state with
  | None ->
      let time_panel =
        Elwd.div
          ~st:[ `P (Brr.El.Style.height, !!"300px") ]
          [
            `P (Brr.El.txt' "Add recordings using the ");
            `P (Brr.El.code [ Brr.El.txt' "![](filename.draw)" ]);
            `P (Brr.El.txt' " syntax. Or");
            `R new_recording_button;
            `R close_button;
          ]
      in
      Elwd.div
        ~st:
          [
            `P (Brr.El.Style.height, !!"300px");
            `P (Brr.El.Style.display, !!"flex");
          ]
        [ `R time_panel ]
  | Some replaying_state ->
      let recording = replaying_state.recording in
      let description =
        let$* selection = Drawing_state.selection replaying_state.recording in
        match selection with
        | { s_strokes = []; s_erasures = []; s_pauses = [] } ->
            global_panel recording
        | _ -> description_of_selection selection
      in
      let ti = Ui_widgets.float replaying_state.time [] in
      let description =
        Elwd.div
          ~st:
            [
              `P (Brr.El.Style.width, !!"480px");
              `P (!!"overflow", !!"auto");
              `P (!!"flex-shrink", !!"0");
            ]
          [ `R description ]
      in
      let strokes = Timeline.el replaying_state in
      let time_panel =
        let$* is_non_empty =
          Lwd_table.map_reduce
            (fun _ _ -> true)
            (false, fun _ _ -> true)
            recording.strokes
        in
        if is_non_empty then
          Elwd.div
            ~st:[ `P (!!"flex-grow", !!"1") ]
            [
              `R ti;
              `R (play_button replaying_state);
              `R (save_button recording);
              `R (download_button recording);
              (* `R select_button; *)
              (* `R move_button; *)
              (* `R scale_button; *)
              `R (add_pause_button replaying_state);
              `R close_button;
              `R (slider replaying_state);
              `R strokes;
              (* `R (left_selection recording); *)
              (* `R (right_selection recording); *)
            ]
        else
          Elwd.div
            ~st:[ `P (Brr.El.Style.height, !!"300px") ]
            [
              `P (Brr.El.txt' "Empty recording. Start recording with ");
              `P
                (Brr.El.kbd
                   ~at:[ Brr.At.class' !!"slipshow-key-panel" ]
                   [ Brr.El.txt' "Shift + R" ]);
              `P (Brr.El.txt' " (or select another recording to edit). Or ");
              `R close_button;
            ]
      in
      Elwd.div
        ~st:
          [
            `P (Brr.El.Style.height, !!"300px");
            `P (Brr.El.Style.display, !!"flex");
          ]
        [ `R description; `R time_panel ]

let el =
  let display =
    let$ status = Status.get in
    match status with
    | Editing -> Lwd_seq.empty
    | _ -> Lwd_seq.element @@ Brr.At.class' !!"slipshow-dont-display"
  in
  let el =
    let$* status = Status.get in
    match status with Editing -> el | _ -> Lwd.pure (Brr.El.div [])
  in
  let st = [ `P (Brr.El.Style.height, !!"300px") ] in
  Elwd.div
    ~at:[ `P (Brr.At.id !!"slipshow-drawing-editor"); `S display ]
    ~st
    [ `R el ]
