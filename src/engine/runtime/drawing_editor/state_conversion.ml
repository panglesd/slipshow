open State_types

let starts_at l = List.hd (List.rev l) |> snd
let end_at l = List.hd l |> snd

let record_of_record (evs : Drawing.Action.Record.t) : t =
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
    { id; scale; path; end_at; starts_at; color; opacity; options }
  in
  let strokes =
    List.filter_map
      (function Drawing.Action.Record.Stroke s -> Some s | Erase _ -> None)
      evs
  in
  let total_time = Lwd.var @@ end_at (List.hd strokes).path in
  let strokes = List.map of_stroke strokes in
  { strokes; total_time }

let record_to_record (evs : t) =
  List.map
    (fun { id; scale; path; starts_at = _; end_at = _; color; opacity; options }
       ->
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
      Drawing.Action.Record.Stroke event)
    evs.strokes
(* TODO: Sort by starting time *)
