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

  let set_current c =
    match c with
    | None as c -> Lwd.set current c
    | Some record_to_add -> (
        match Lwd.peek current with
        | None ->
            let record = State_conversion.record_of_record record_to_add in
            let total_time_recorded = Lwd.peek record.total_time in
            Lwd.set current (Some record);
            Lwd.set time total_time_recorded;
            Drawing.Event.clear ()
        | Some current_recording ->
            let record_to_add =
              State_conversion.record_of_record record_to_add
            in
            let total_time_recorded = Lwd.peek record_to_add.total_time in
            Lwd.set current_recording.total_time
              (Lwd.peek current_recording.total_time +. total_time_recorded);
            Lwd_table.iter
              (fun s ->
                let path_var = s.path in
                let path = Lwd.peek path_var in
                Lwd.set path_var
                  (Path_editing.add_time path (Lwd.peek time)
                     total_time_recorded))
              current_recording.strokes;
            Lwd_table.iter
              (fun s ->
                let path_var = s.path in
                let path = Lwd.peek path_var in
                Lwd.set path_var (Path_editing.translate path (Lwd.peek time)))
              record_to_add.strokes;
            Lwd_table.iter
              (fun s -> Lwd_table.append' current_recording.strokes s)
              record_to_add.strokes;
            Lwd.set time (Lwd.peek time +. total_time_recorded);
            Drawing.Event.clear ())

  let peek_current () = Lwd.peek current
  let current = Lwd.get current
end
