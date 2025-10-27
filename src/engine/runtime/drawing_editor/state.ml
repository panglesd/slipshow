module Stroke = struct
  let current = Lwd.var None
  let set_current (c : Drawing.Stroke.t) = Lwd.set current (Some c)

  open Lwd_infix

  let el =
    let$* current = current |> Lwd.get in
    let id =
      match current with None -> "custom_id" | Some current -> current.id
    in
    let id_elem = Brr.El.txt' id in
    Brr_lwd.Elwd.div [ `P id_elem ]
end

let time = Lwd.var 0.
let left_selection = Lwd.var 0.
let right_selection = Lwd.var 0.
let is_playing = Lwd.var false

open State_types

let is_selected stroke = Lwd.get stroke.selected
let is_preselected stroke = Lwd.get stroke.preselected

module Recording = struct
  let current = Lwd.var None

  let set_current (c : Drawing.Record.t option) =
    match c with
    | None as c -> Lwd.set current c
    | Some record_to_add -> (
        let () =
          List.iter
            (function
              | `Draw (Drawing.Tools.Draw.Start { id; _ }), _ ->
                  let _ =
                    Drawing.Tools.Erase.execute Drawing.Types.Self
                      (Erase [ (id, Self (* TODO: change to Record origin *)) ])
                  in
                  ()
              | _ -> ())
            record_to_add.events
        in
        match Lwd.peek current with
        | None ->
            let record = State_conversion.record_of_record record_to_add in
            let total_time_recorded = Lwd.peek record.total_time in
            Lwd.set current (Some record);
            Lwd.set time total_time_recorded
        | Some current_recording ->
            let record_to_add =
              State_conversion.record_of_record record_to_add
            in
            let total_time_recorded = Lwd.peek record_to_add.total_time in
            Lwd.set current_recording.total_time
              (Lwd.peek current_recording.total_time +. total_time_recorded);
            let max_track = ref (-1) in
            Lwd_table.iter
              (fun s ->
                max_track := Int.max !max_track (Lwd.peek s.track);
                let path_var = s.path in
                let path = Lwd.peek path_var in
                Lwd.set path_var
                  (Path_editing.add_time path (Lwd.peek time)
                     total_time_recorded);
                Option.iter
                  (fun erase ->
                    Lwd.set erase.at (Lwd.peek erase.at +. total_time_recorded))
                  (Lwd.peek s.erased))
              current_recording.strokes;
            Lwd_table.iter
              (fun s ->
                Lwd.set s.track (!max_track + 1);
                let path_var = s.path in
                let path = Lwd.peek path_var in
                Lwd.set path_var (Path_editing.translate path (Lwd.peek time)))
              record_to_add.strokes;
            Lwd_table.iter
              (fun s -> Lwd_table.append' current_recording.strokes s)
              record_to_add.strokes;
            Lwd.set time (Lwd.peek time +. total_time_recorded))

  let peek_current () = Lwd.peek current
  let current = Lwd.get current
end

module Track = struct
  open Lwd_infix

  let n_track recording =
    Lwd_table.map_reduce
      (fun _ (s : stro) ->
        let$ s_track = Lwd.get s.track
        and$ e_track =
          let$* e = Lwd.get s.erased in
          match e with
          | None -> Lwd.pure None
          | Some e -> Lwd.map ~f:(fun x -> Some x) @@ Lwd.get e.track
        in
        match e_track with
        | None -> s_track
        | Some e_track -> Int.max s_track e_track)
      (Lwd.pure 0, Lwd.map2 ~f:Int.max)
      recording
    |> Lwd.join
end

let play () =
  let record = Recording.peek_current () in
  match record with
  | None -> ()
  | Some recording ->
      Lwd.set is_playing true;
      let now () = Brr.Performance.now_ms Brr.G.performance in
      let max = Lwd.peek recording.total_time in
      let start_time = now () -. Lwd.peek time in
      let rec loop _ =
        let now = now () -. start_time in
        Lwd.set time now;
        if now <= max && Lwd.peek is_playing then
          let _animation_frame_id = Brr.G.request_animation_frame loop in
          ()
        else Lwd.set is_playing false
      in
      loop 0.

let stop () = Lwd.set is_playing false
let current_tool = Lwd.var Select
