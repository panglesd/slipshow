let now () = Brr.Performance.now_ms Brr.G.performance

include Types
module Json = Json
module Path_editing = Path_editing

let workspaces : workspaces =
  {
    recordings = Lwd_table.make ();
    live_drawing = Lwd_table.make ();
    current_recording =
      {
        recording =
          {
            strokes = Lwd_table.make ();
            total_time = Lwd.var 0.;
            record_id = Random.bits ();
            name = Lwd.var "Unnamed recording";
            pauses = Lwd_table.make ();
          };
        time = Lwd.var 0.;
        is_playing = Lwd.var false;
      };
  }

let editing_tool = Lwd.var Select
let current_replaying_state = Lwd.var workspaces.current_recording

let live_drawing_state =
  {
    tool = Lwd.var Pointer;
    color = Lwd.var "blue";
    width = Lwd.var Width.medium;
  }

let status = Lwd.var (Drawing Presenting)

let start_recording replaying_state =
  Lwd.set live_drawing_state.tool (Stroker Pen);
  let replayed_part, unplayed_erasure =
    let tbl = Lwd_table.make () in
    let unplayed_erasure =
      Lwd_table.fold
        (fun acc stro ->
          let first_time = Lwd.peek stro.path |> List.rev |> List.hd |> snd in
          if Lwd.peek replaying_state.time >= first_time then (
            Lwd_table.append' tbl stro;
            match Lwd.peek stro.erased with
            | None -> acc
            | Some ({ at; _ } as erased) ->
                if Lwd.peek at >= Lwd.peek replaying_state.time then (
                  Lwd.set stro.erased None;
                  StringMap.add stro.id erased acc)
                else acc)
          else acc)
        StringMap.empty replaying_state.recording.strokes
    in
    (tbl, unplayed_erasure)
  in
  Lwd.set status
    (Drawing
       (Recording
          {
            replaying_state;
            replayed_part;
            unplayed_erasure;
            started_at = now () -. Lwd.peek replaying_state.time;
            recording_temp = Lwd_table.make ();
          }))

let finish_recording
    {
      replaying_state;
      started_at;
      recording_temp;
      replayed_part;
      unplayed_erasure;
    } =
  let additional_time = now () -. started_at -. Lwd.peek replaying_state.time in
  Lwd_table.iter
    (fun stro ->
      let first = Lwd.peek stro.path |> List.rev |> List.hd |> snd in
      (* First case: the stroke was fully after the recording *)
      if first >= Lwd.peek replaying_state.time then (
        Lwd.update
          (List.map @@ fun (pos, t) -> (pos, t +. additional_time))
          stro.path;
        match Lwd.peek stro.erased with
        | None -> ()
        | Some { at; _ } ->
            if Lwd.peek at >= Lwd.peek replaying_state.time then
              Lwd.update (( +. ) additional_time) at)
      else
        (* Second case: it was included in the recording. But maybe not its
           erasure time! *)
        match Lwd.peek stro.erased with
        | Some _ ->
            (* It was erased in the new recording, that takes precedence over a
               saved value *)
            ()
        | None -> (
            (* Maybe there was a "saved" value? *)
            match StringMap.find_opt stro.id unplayed_erasure with
            | None -> ()
            | Some erased ->
                Lwd.update (( +. ) additional_time) erased.at;
                Lwd.set stro.erased (Some erased)))
    replaying_state.recording.strokes;
  (* We update pauses times that were after the beginning of the recording *)
  Lwd_table.iter
    (fun pause ->
      Lwd.may_update
        (fun at ->
          if at >= Lwd.peek replaying_state.time then
            Some (at +. additional_time)
          else None)
        pause.p_at)
    replaying_state.recording.pauses;
  Lwd.update (( +. ) additional_time) replaying_state.recording.total_time;
  Lwd.update (( +. ) additional_time) replaying_state.time;
  let max_track =
    Lwd_table.fold
      (fun max_track stro -> Int.max max_track (Lwd.peek stro.track))
      0 replayed_part
  in
  Lwd_table.iter
    (fun stro ->
      Lwd.set stro.track max_track;
      Lwd_table.append' replaying_state.recording.strokes stro)
    recording_temp;
  Lwd.set status Editing

type selection = {
  s_strokes : (stro Lwd_table.row * stro) list;
  s_erasures : (stro * erased) list;
  s_pauses : (pause Lwd_table.row * pause) list;
}

let selection recording =
  let open Lwd_infix in
  let$* s =
    Lwd_table.map_reduce
      (fun row s ->
        let$ selected =
          let$ selected = Lwd.get s.selected in
          if selected then Lwd_seq.element (Either.Left (row, s))
          else Lwd_seq.empty
        and$ erase_selected =
          let$* erased = Lwd.get s.erased in
          match erased with
          | None -> Lwd.pure Lwd_seq.empty
          | Some erased ->
              let$ selected = Lwd.get erased.selected in
              if selected then Lwd_seq.element (Either.Right (s, erased))
              else Lwd_seq.empty
        in
        Lwd_seq.concat selected erase_selected)
      Lwd_seq.lwd_monoid recording.strokes
    |> Lwd.join
  in
  let l = Lwd_seq.to_list s in
  let s_strokes, s_erasures = List.partition_map Fun.id l in
  let$ pauses =
    Lwd_table.map_reduce
      (fun row pause ->
        let$ selected = Lwd.get pause.p_selected in
        if selected then Lwd_seq.element (row, pause) else Lwd_seq.empty)
      Lwd_seq.lwd_monoid recording.pauses
    |> Lwd.join
  in
  let s_pauses = Lwd_seq.to_list pauses in
  { s_erasures; s_strokes; s_pauses }

let delete selection =
  List.iter (fun (row, _) -> Lwd_table.remove row) selection.s_strokes;
  List.iter (fun (stro, _) -> Lwd.set stro.erased None) selection.s_erasures;
  List.iter (fun (row, _) -> Lwd_table.remove row) selection.s_pauses

let unselect selection =
  List.iter (fun (_, stro) -> Lwd.set stro.selected false) selection.s_strokes;
  List.iter
    (fun (_, (erase : erased)) -> Lwd.set erase.selected false)
    selection.s_erasures;
  List.iter
    (fun (_, pause) -> Lwd.set pause.p_selected false)
    selection.s_pauses
