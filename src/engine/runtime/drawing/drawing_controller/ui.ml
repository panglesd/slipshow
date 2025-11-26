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

let description_of_selection
    (strokes_and_erases :
      [ `Stroke of _ Lwd_table.row * stro | `Erasure of stro * erased ] list)
    (pauses : (_ Lwd_table.row * pause) list) =
  let strokes, erasures =
    List.partition_map
      (function `Stroke x -> Left x | `Erasure x -> Right x)
      strokes_and_erases
  in
  let n_selected =
    Brr.El.div
      [
        Brr.El.txt'
          (string_of_int (List.length strokes)
          ^ " stroke(s) and "
          ^ string_of_int (List.length erasures)
          ^ " erasure(s) and "
          ^ string_of_int (List.length pauses)
          ^ " pause(s) selected");
      ]
  in
  let delete =
    let click_handler =
      Elwd.handler Brr.Ev.click (fun _ ->
          List.iter
            (function
              | `Stroke (row, _) -> Lwd_table.remove row
              | `Erasure (stro, _) -> Lwd.set stro.erased None)
            strokes_and_erases;
          List.iter (fun (row, _) -> Lwd_table.remove row) pauses)
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
  Elwd.div [ `P n_selected; `R (description_of_strokes strokes); `R delete ]

let global_panel recording =
  (* let total_time = *)
  (*   let total_time = Ui_widgets.float ~type':"number" recording.total_time [] in *)
  (*   Elwd.div [ `P (Brr.El.txt' "Total duration: "); `R total_time ] *)
  (* in *)
  let name_title =
    let$ name = Lwd.get recording.name in
    Brr.El.h3 ~at:[ Brr.At.style !!"margin-top:0" ] [ Brr.El.txt' name ]
  in
  let change_title =
    Elwd.div
      [
        `P (Brr.El.txt' "Rename recording: ");
        `R (Ui_widgets.string ~type':"text" ~kind:`Input recording.name []);
        `P
          (Brr.El.div
             [
               Brr.El.a
                 ~at:[ Brr.At.href !!"TODO" ] (* TODO *)
                 [ Brr.El.txt' "Get help in the documentation" ];
             ]);
      ]
  in
  let select =
    let options =
      Lwd_table.map_reduce
        (fun _row workspace ->
          let name =
            let$ name = Lwd.get workspace.recording.name in
            Brr.El.txt' name
          in
          let recording_id = string_of_int workspace.recording.record_id in
          let value = Brr.At.value (Jstr.v recording_id) in
          let selected =
            let$ current_replaying_state = Lwd.get current_replaying_state in
            if
              workspace.recording.record_id
              = current_replaying_state.recording.record_id
            then Lwd_seq.element Brr.At.selected
            else Lwd_seq.empty
          in
          Lwd_seq.element
          @@ Elwd.option ~at:[ `P value; `S selected ] [ `R name ])
        Lwd_seq.monoid workspaces.recordings
      |> Lwd_seq.lift
    in
    let current_recording =
      let$* name = Lwd.get workspaces.current_recording.recording.name in
      let recording_id =
        string_of_int workspaces.current_recording.recording.record_id
      in
      let value = Brr.At.value (Jstr.v recording_id) in
      let selected =
        let$ current_replaying_state = Lwd.get current_replaying_state in
        if
          workspaces.current_recording.recording.record_id
          = current_replaying_state.recording.record_id
        then Lwd_seq.element Brr.At.selected
        else Lwd_seq.empty
      in
      Elwd.option ~at:[ `P value; `S selected ] [ `P (Brr.El.txt' name) ]
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
                  if Int.equal replaying_state.recording.record_id record_id
                  then raise (Found replaying_state)
                  else ())
                workspaces.recordings;
              workspaces.current_recording
            with Found r -> r
          in
          Lwd.set current_replaying_state replaying_state)
    in
    let select =
      Elwd.select ~ev:[ `P change ] [ `S options; `R current_recording ]
    in
    let label = Brr.El.txt' "List of recordings: " in
    Elwd.div [ `P label; `R select ]
  in
  Elwd.div [ `R name_title; `R select (* ; `R total_time *); `R change_title ]

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
        (fun b pause ->
          b
          ||
          let at = Lwd.peek pause.p_at in
          before <= at && at < now)
        false replaying_state.recording.pauses
    in
    Lwd.set replaying_state.time now;
    if
      now <= max && Lwd.peek replaying_state.is_playing && not has_crossed_pause
    then
      let _animation_frame_id = Brr.G.request_animation_frame loop in
      ()
    else Lwd.set replaying_state.is_playing false
  in
  loop 0.

let play_button editing_state =
  let$* is_playing = Lwd.get editing_state.is_playing in
  if is_playing then
    let click =
      Elwd.handler Brr.Ev.click (fun _ ->
          Lwd.set editing_state.is_playing false)
    in
    Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "⏸ Pause") ]
  else
    let click = Elwd.handler Brr.Ev.click (fun _ -> play editing_state) in
    Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "▶ Play") ]

let save_button recording =
  let click =
    Elwd.handler Brr.Ev.click (fun _ ->
        let s = Drawing_state.Json.string_of_recording recording in
        let blob =
          let init = Brr.Blob.init ~type':(Jstr.v "application/json") () in
          Brr.Blob.of_jstr ~init (Jstr.v s)
        in
        let a = Brr.El.a [] in
        let revoke_url =
          let url = Jv.get Jv.global "URL" in
          let object_url =
            Jv.call url "createObjectURL" [| Brr.Blob.to_jv blob |]
          in
          Jv.set (Brr.El.to_jv a) "href" object_url;
          fun () -> Jv.call url "revokeObjectURL" [| object_url |] |> ignore
        in
        Jv.set (Brr.El.to_jv a) "download" (Jv.of_string "drawing.draw");
        Jv.call (Brr.El.to_jv a) "click" [||] |> ignore;
        revoke_url ())
  in
  Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "💾 Save") ]

let add_pause_button (replaying_state : replaying_state) =
  let click =
    Elwd.handler Brr.Ev.click (fun _ ->
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
    Elwd.handler Brr.Ev.click (fun _ -> Lwd.set status (Drawing Presenting))
  in
  Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Close editing panel") ]

let el =
  let$* replaying_state = Lwd.get current_replaying_state in
  let recording = replaying_state.recording in
  let description =
    let$* s =
      Lwd_table.map_reduce
        (fun row s ->
          let$ selected =
            let$ selected = Lwd.get s.selected in
            if selected then Lwd_seq.element (`Stroke (row, s))
            else Lwd_seq.empty
          and$ erase_selected =
            let$* erased = Lwd.get s.erased in
            match erased with
            | None -> Lwd.pure Lwd_seq.empty
            | Some erased ->
                let$ selected = Lwd.get erased.selected in
                if selected then Lwd_seq.element (`Erasure (s, erased))
                else Lwd_seq.empty
          in
          Lwd_seq.concat selected erase_selected)
        Lwd_seq.lwd_monoid recording.strokes
      |> Lwd.join
    in
    let l = Lwd_seq.to_list s in
    let$* pauses =
      Lwd_table.map_reduce
        (fun row pause ->
          let$ selected = Lwd.get pause.p_selected in
          if selected then Lwd_seq.element (row, pause) else Lwd_seq.empty)
        Lwd_seq.lwd_monoid recording.pauses
      |> Lwd.join
    in
    let pauses = Lwd_seq.to_list pauses in
    match (l, pauses) with
    | [], [] -> global_panel recording
    | strokes, pauses -> description_of_selection strokes pauses
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
               [ Brr.El.txt' "R" ]);
          `P (Brr.El.txt' " (or select another recording to edit).");
        ]
  in
  Elwd.div
    ~st:
      [
        `P (Brr.El.Style.height, !!"300px"); `P (Brr.El.Style.display, !!"flex");
      ]
    [ `R description; `R time_panel ]

let el =
  let display =
    let$ status = Lwd.get status in
    match status with
    | Editing -> Lwd_seq.empty
    | _ -> Lwd_seq.element @@ Brr.At.class' !!"slipshow-dont-display"
  in
  let el =
    let$* status = Lwd.get status in
    match status with Editing -> el | _ -> Lwd.pure (Brr.El.div [])
  in
  let st = [ `P (Brr.El.Style.height, !!"300px") ] in
  Elwd.div
    ~at:[ `P (Brr.At.id !!"slipshow-drawing-editor"); `S display ]
    ~st
    [ `R el ]
