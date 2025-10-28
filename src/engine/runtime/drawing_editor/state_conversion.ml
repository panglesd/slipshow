open State_types

let starts_at l = List.hd (List.rev l) |> snd
let end_at l = List.hd l |> snd

(** Here, we turn a record (as an event list) into something we can use in the
    drawing editor *)
let new_stroke ~coord ~time ~stroker ~color ~width ~id =
  let path = Lwd.var [ (coord, time) ] in
  let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
  let end_at = Lwd.map (Lwd.get path) ~f:end_at in
  let starts_at = Lwd.map (Lwd.get path) ~f:starts_at in
  (* TODO: turn path into a "relatively_timed" and make starts_at a var *)
  let color = Lwd.var color in
  let selected = Lwd.var false in
  let preselected = Lwd.var false in
  {
    id;
    scale;
    path;
    end_at;
    starts_at;
    color;
    selected;
    preselected;
    track = Lwd.var 0;
    erased = Lwd.var None;
    stroker;
    width;
  }

let handle_draw_event h d time =
  match d with
  | Drawing.Tools.Draw.Start
      { start_args = { stroker; width; color }; id; coord } ->
      let new_stroke = new_stroke ~coord ~time ~stroker ~color ~width ~id in
      Hashtbl.add h id new_stroke
  | Continue { coord; id } -> (
      match Hashtbl.find_opt h id with
      | None -> ()
      | Some stro -> Lwd.set stro.path ((coord, time) :: Lwd.peek stro.path))
  | End { id = _ } -> ()

let handle_erase_event h (Drawing.Tools.Erase.Erase ids) time =
  List.iter
    (fun (id, _origin) ->
      match Hashtbl.find_opt h id with
      | None -> ()
      | Some s ->
          Lwd.set s.erased
            (Some
               {
                 at = Lwd.var time;
                 track = Lwd.var (Lwd.peek s.track);
                 selected = Lwd.var false;
                 preselected = Lwd.var false;
               }))
    ids

let record_of_record (evs : Drawing.Record.t) : t =
  let total_time, strokes =
    let h = Hashtbl.create 10 in
    let total_time =
      List.fold_left
        (fun _acc (event, time) ->
          match event with
          | `Draw d ->
              handle_draw_event h d time;
              time
          | `Erase e ->
              handle_erase_event h e time;
              time
          | `Clear _e ->
              (* TODO: handle_clear_event h e time; *)
              time)
        0. (List.rev evs.events)
    in
    (total_time, Hashtbl.fold (fun _id stro acc -> stro :: acc) h [])
  in
  let table = Lwd_table.make () in
  List.iter (fun stroke -> Lwd_table.append' table stroke) strokes;
  {
    strokes = table;
    total_time = Lwd.var total_time;
    record_id = evs.record_id;
  }

let record_to_record (evs : t) : Drawing.Record.t =
  let of_stroke (stro : stro) : Drawing.Record.event Drawing.Record.timed list =
    let draw (d, t) = (`Draw d, t) in
    let path = Lwd.peek stro.path in
    let id = stro.id in
    let end_time = List.hd path |> snd in
    let continue =
      List.rev_map
        (fun (coord, time) ->
          draw (Drawing.Tools.Draw.Continue { coord; id }, time))
        path
    in
    let stroke =
      match continue with
      | (`Draw (Continue { coord; id }), time) :: ev ->
          let start_args =
            {
              Drawing.Tools.stroker =
                stro.stroker
                (* TODO: Change stroker to allow custom numerical values
                 for width and opacity *);
              width = stro.width;
              color = Lwd.peek stro.color;
            }
          in
          draw (Drawing.Tools.Draw.End { id }, end_time)
          :: draw (Drawing.Tools.Draw.Start { coord; id; start_args }, time)
          :: ev
      | _ -> continue
    in
    let erase =
      match Lwd.peek stro.erased with
      | None -> []
      | Some { at; _ } ->
          [
            ( `Erase (Drawing.Tools.Erase.Erase [ (id, Record evs.record_id) ]),
              Lwd.peek at );
          ]
    in
    erase @ stroke
  in
  let strokes =
    let rec loop acc row =
      match row with
      | None -> acc
      | Some row ->
          let acc =
            match Lwd_table.get row with None -> acc | Some v -> v :: acc
          in
          loop acc (Lwd_table.prev row)
    in
    loop [] (Lwd_table.last evs.strokes)
  in
  let events =
    strokes |> List.concat_map of_stroke
    |> List.sort (fun (_, s1) (_, s2) -> Float.compare s1 s2)
    |> List.rev
  in
  { events; record_id = evs.record_id }
