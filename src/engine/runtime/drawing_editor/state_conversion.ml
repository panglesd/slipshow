open State_types

let starts_at l = List.hd (List.rev l) |> snd
let end_at l = List.hd l |> snd

let of_stroke
    { Drawing.Stroke.id; scale; path; end_at = _; color; opacity; options } =
  let color = Lwd.var color in
  let opacity = Lwd.var opacity in
  let path = Lwd.var path in
  let options =
    let open Perfect_freehand.Options in
    let thinning = thinning options in
    let size =
      Lwd.var @@ Option.get @@ size options
      (* Size options is _always_ set in strokes. The option type comes from
           the Perfect_freehand binding. *)
    in
    let smoothing = smoothing options in
    let streamline = streamline options in
    { size; thinning; smoothing; streamline }
  in
  let end_at = Lwd.map (Lwd.get path) ~f:end_at in
  let starts_at = Lwd.map (Lwd.get path) ~f:starts_at in
  let selected = Lwd.var false in
  let preselected = Lwd.var false in
  {
    id;
    scale;
    path;
    end_at;
    starts_at;
    color;
    opacity;
    options;
    selected;
    preselected;
    track = Lwd.var 0;
    erased = Lwd.var None;
  }

let record_of_record (evs : Drawing.Record.t) : t =
  let strokes, rest =
    List.partition_map
      (function
        | Drawing.Record.Stroke s -> Left s
        | (Erase _ | Clear _) as s -> Right s)
      evs
  in
  let erases, _clear =
    List.partition_map
      (function
        | Drawing.Record.Erase s -> Left s
        | Clear _ as s -> Right s
        | Stroke _ -> assert false (* Removed in the partition above *))
      rest
  in
  let total_time =
    let stroke_end = end_at (List.hd strokes).path in
    let erase_end = match erases with [] -> stroke_end | (_, t) :: _ -> t
    and clear_end =
      (* TODO: Clear end time *)
      0.
    in
    Lwd.var @@ Float.max stroke_end (Float.max erase_end clear_end)
  in
  let strokes = List.map of_stroke strokes in
  let h = Hashtbl.create 10 in
  let () = List.iter (fun s -> Hashtbl.add h s.id s) strokes in
  let () =
    erases
    |> List.iter @@ fun (ids, t) ->
       ids
       |> List.iter @@ fun id ->
          Hashtbl.find_opt h id
          |> Option.iter @@ fun s ->
             Lwd.set s.erased
               (Some
                  {
                    at = Lwd.var t;
                    track = Lwd.var (Lwd.peek s.track);
                    selected = Lwd.var false;
                    preselected = Lwd.var false;
                  })
  in
  let table = Lwd_table.make () in
  List.iter (fun stroke -> Lwd_table.append' table stroke) strokes;
  { strokes = table; total_time }

let record_to_record (evs : t) =
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
  List.concat_map
    (fun {
           id;
           scale;
           path;
           starts_at = _;
           end_at = _;
           color;
           opacity;
           options;
           selected = _;
           preselected = _;
           track = _;
           erased;
         } ->
      let { size; thinning; smoothing; streamline } = options in
      let color = Lwd.peek color in
      let opacity = Lwd.peek opacity in
      let path = Lwd.peek path in
      let options =
        let size = Lwd.peek size in
        Perfect_freehand.Options.v ~size ?thinning ?smoothing ?streamline ()
      in
      let end_at = end_at path in
      let event =
        { Drawing.Stroke.id; scale; path; end_at; color; opacity; options }
      in
      let erase =
        match Lwd.peek erased with
        | None -> []
        | Some { at; _ } -> [ Drawing.Record.Erase ([ id ], Lwd.peek at) ]
      in
      Drawing.Record.Stroke event :: erase)
    strokes
(* TODO: Sort by starting time *)
