open Drawing_state.Live_coding
open Lwd_infix
open Brr_lwd

let ( !! ) = Jstr.v
let total_length (recording : recording) = Lwd.get recording.total_time

let slider (editing_state : editing_state) =
  let attrs =
    [
      `P (Brr.At.id !!"slipshow-time-slider");
      `P (Brr.At.class' !!"time-slider");
      `P (Brr.At.v !!"min" !!"0");
    ]
  in
  let prop =
    let max =
      let$ max = total_length editing_state.replaying_state.recording in
      (!!"max", Jv.of_float max)
    in
    [ `R max ]
  in
  let el =
    Drawing_editor.Ui_widgets.float ~prop ~type':"range" ~kind:`Input
      editing_state.replaying_state.time attrs
  in
  Elwd.div [ `R el ]

(* let left_selection recording = *)
(*   let attrs = *)
(*     let max = *)
(*       let$ max = total_length recording in *)
(*       Brr.At.v !!"max" (Jstr.of_float max) *)
(*     in *)
(*     [ *)
(*       `P (Brr.At.id !!"slipshow-right-selection-slider"); *)
(*       `P (Brr.At.class' !!"time-slider"); *)
(*       `P (Brr.At.v !!"min" !!"0"); *)
(*       `R max; *)
(*     ] *)
(*   in *)
(*   let callback n = *)
(*     Lwd.may_update *)
(*       (fun m -> if m >= n then None else Some n) *)
(*       State.right_selection *)
(*   in *)
(*   let el = *)
(*     Drawing_editor.Ui_widgets.float ~callback ~type':"range" ~kind:`Input *)
(*       State.left_selection attrs *)
(*   in *)
(*   Elwd.div [ `R el ] *)

(* let right_selection recording = *)
(*   let attrs = *)
(*     let max = *)
(*       let$ max = total_length recording in *)
(*       Brr.At.v !!"max" (Jstr.of_float max) *)
(*     in *)
(*     [ *)
(*       `P (Brr.At.id !!"slipshow-right-selection-slider"); *)
(*       `P (Brr.At.class' !!"time-slider"); *)
(*       `P (Brr.At.v !!"min" !!"0"); *)
(*       `R max; *)
(*     ] *)
(*   in *)
(*   let callback n = *)
(*     Lwd.may_update *)
(*       (fun m -> if m <= n then None else Some n) *)
(*       State.left_selection *)
(*   in *)
(*   let el = *)
(*     Ui_widgets.float ~callback ~type':"range" ~kind:`Input State.right_selection *)
(*       attrs *)
(*   in *)
(*   Elwd.div [ `R el ] *)

let description_of_stroke row (stroke : stro) =
  (* let color = Drawing_editor.Ui_widgets.of_color stroke.color in *)
  (* let color = Elwd.div [ `P (Brr.El.txt' "Color: "); `R color ] in *)
  let close =
    let click_handler =
      Elwd.handler Brr.Ev.click (fun _ -> Lwd.set stroke.selected false)
    in
    Elwd.button ~ev:[ `P click_handler ] [ `P (Brr.El.txt' "Close") ]
  in
  let delete =
    let click_handler =
      Elwd.handler Brr.Ev.click (fun _ -> Lwd_table.remove row)
    in
    Elwd.button ~ev:[ `P click_handler ] [ `P (Brr.El.txt' "Remove") ]
  in
  let duration =
    let duration =
      let at = [ `P (Brr.At.type' !!"number") ] in
      let prop =
        let v =
          let$ end_at = stroke.end_at and$ starts_at = stroke.starts_at in
          (!!"value", Jv.of_float (end_at -. starts_at))
        in
        [ `R v ]
      in
      let ev =
        let$ path = Lwd.get stroke.path in
        let begin_ = List.hd (List.rev path) |> snd in
        let end_ = List.hd path |> snd in
        Elwd.handler Brr.Ev.change (fun ev ->
            let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
            let new_value =
              Jv.get el "value" |> Jv.to_string |> float_of_string
            in
            let new_path =
              Drawing_editor.Path_editing.change_path path begin_ end_ new_value
            in
            Lwd.set stroke.path new_path)
      in
      let ev = [ `R ev ] in
      Elwd.input ~prop ~ev ~at ()
    in
    Elwd.div [ `P (Brr.El.txt' "Duration: "); `R duration ]
  in
  Elwd.div [ (* `R color; *) `R duration; `R delete; `R close ]

let global_panel recording =
  let total_time =
    let total_time =
      Drawing_editor.Ui_widgets.float ~type':"number" recording.total_time []
    in
    Elwd.div [ `P (Brr.El.txt' "Total duration: "); `R total_time ]
  in
  let name_title =
    let$ name = Lwd.get recording.name in
    Brr.El.txt' name
  in
  let change_title =
    Drawing_editor.Ui_widgets.string ~kind:`Input recording.name []
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
            let$ current_editing_state = Lwd.get current_editing_state in
            if
              workspace.recording.record_id
              = current_editing_state.replaying_state.recording.record_id
            then Lwd_seq.element Brr.At.selected
            else Lwd_seq.empty
          in
          Lwd_seq.element
          @@ Elwd.option ~at:[ `P value; `S selected ] [ `R name ])
        Lwd_seq.monoid workspaces.recordings
      |> Lwd_seq.lift
    in
    let current_recording =
      let$ name = Lwd.get workspaces.current_recording.recording.name in
      Brr.El.option [ Brr.El.txt' name ]
    in
    let change =
      Elwd.handler Brr.Ev.change (fun ev ->
          let record_id =
            let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
            Jv.get el "value" |> Jv.to_string |> int_of_string
          in
          Brr.Console.(log [ "BBB Setting record id"; record_id ]);
          let replaying_state =
            let exception Found of Drawing_state.Live_coding.replaying_state in
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
          Lwd.set current_editing_state
            { replaying_state; is_playing = Lwd.var false })
    in
    Elwd.select ~ev:[ `P change ] [ `S options; `R current_recording ]
  in
  Elwd.div [ `R select; `R name_title; `R total_time; `R change_title ]

let play (editing_state : editing_state) =
  Lwd.set editing_state.is_playing true;
  let now () = Brr.Performance.now_ms Brr.G.performance in
  let max = Lwd.peek editing_state.replaying_state.recording.total_time in
  let start_time = now () -. Lwd.peek editing_state.replaying_state.time in
  let rec loop _ =
    let now = now () -. start_time in
    Lwd.set editing_state.replaying_state.time now;
    if now <= max && Lwd.peek editing_state.is_playing then
      let _animation_frame_id = Brr.G.request_animation_frame loop in
      ()
    else Lwd.set editing_state.is_playing false
  in
  loop 0.

let play_button editing_state =
  let$* is_playing = Lwd.get editing_state.is_playing in
  if is_playing then
    let click =
      Elwd.handler Brr.Ev.click (fun _ ->
          Lwd.set editing_state.is_playing false)
    in
    Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Pause") ]
  else
    let click = Elwd.handler Brr.Ev.click (fun _ -> play editing_state) in
    Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Play") ]

let save_button recording =
  let click =
    Elwd.handler Brr.Ev.click (fun _ ->
        let (* recording *) s =
          Drawing_state.Json.string_of_recording recording
        in
        (* let s = Drawing.Record.to_string recording in *)
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
  Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Save") ]

let select_button =
  let click =
    Elwd.handler Brr.Ev.click (fun _ -> Lwd.set editing_tool Select)
  in
  Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Select") ]

let move_button =
  let click = Elwd.handler Brr.Ev.click (fun _ -> Lwd.set editing_tool Move) in
  Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Move") ]

let scale_button =
  let click =
    Elwd.handler Brr.Ev.click (fun _ -> Lwd.set editing_tool Rescale)
  in
  Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Resize") ]

let close_button =
  let click =
    Elwd.handler Brr.Ev.click (fun _ -> Lwd.set status (Drawing Presenting))
  in
  Elwd.button ~ev:[ `P click ] [ `P (Brr.El.txt' "Close") ]

let el =
  let$* editing_state = Lwd.get current_editing_state in
  let recording = editing_state.replaying_state.recording in
  let description =
    let$* s =
      Lwd_table.map_reduce
        (fun row s ->
          Lwd.get s.selected
          |> Lwd.map ~f:(fun x ->
                 if x then Lwd_seq.element (row, s) else Lwd_seq.empty))
        Lwd_seq.lwd_monoid recording.strokes
      |> Lwd.join
    in
    let l = Lwd_seq.to_list s in
    match l with
    | [] -> global_panel recording
    | [ (row, current_stroke) ] -> description_of_stroke row current_stroke
    | _ :: _ :: _ -> Elwd.div [ `P (Brr.El.txt' "Not implemented") ]
  in
  let ti =
    Drawing_editor.Ui_widgets.float editing_state.replaying_state.time []
  in
  let description =
    Elwd.div ~st:[ `P (Brr.El.Style.width, !!"20%") ] [ `R description ]
  in
  let strokes = Timeline.el recording in
  let time_panel =
    Elwd.div
      ~st:[ `P (!!"flex-grow", !!"1") ]
      [
        `R ti;
        `R (play_button editing_state);
        `R (save_button recording);
        `R select_button;
        `R move_button;
        `R scale_button;
        `R close_button;
        `R (slider editing_state);
        `R strokes;
        (* `R (left_selection recording); *)
        (* `R (right_selection recording); *)
      ]
  in
  Elwd.div
    ~st:[ `P (Brr.El.Style.display, !!"flex") ]
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
  let st = [ `P (Brr.El.Style.height, !!"200px") ] in
  Elwd.div
    ~at:[ `P (Brr.At.id !!"slipshow-drawing-editor"); `S display ]
    ~st
    [ `R el ]
