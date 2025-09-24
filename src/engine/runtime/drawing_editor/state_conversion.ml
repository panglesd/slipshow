open State_types

let record_of_record (evs : Drawing.Action.Record.t) =
  let of_stroke
      { Drawing.Stroke.id; scale; path; end_at; color; opacity; options } =
    let color = Lwd.var color in
    let opacity = Lwd.var opacity in
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
    { id; scale; path; end_at; color; opacity; options }
  in
  List.filter_map
    (function
      | Drawing.Action.Record.Stroke stroke -> Some (of_stroke stroke)
      | Erase _ -> None)
    evs

let record_to_record (evs : t) =
  List.map
    (fun { id; scale; path; end_at; color; opacity; options } ->
      let { size; thinning; smoothing; streamline } = options in
      let color = Lwd.peek color in
      let opacity = Lwd.peek opacity in
      let options =
        let size = Lwd.peek size in
        Perfect_freehand.Options.v ~size ?thinning ?smoothing ?streamline ()
      in
      let event =
        { Drawing.Stroke.id; scale; path; end_at; color; opacity; options }
      in
      Drawing.Action.Record.Stroke event)
    evs
