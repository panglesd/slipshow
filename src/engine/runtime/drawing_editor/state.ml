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

open Lwd_infix

module UI = struct
  let float (type x) ?type' ?(kind = `Change) var =
    let h =
     fun ev ->
      let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
      let new_value = Jv.get el "value" |> Jv.to_string |> float_of_string in
      Brr.Console.(log [ new_value ]);
      Lwd.set var new_value
    in
    let set =
      match kind with
      | `Change -> Brr_lwd.Elwd.handler Brr.Ev.change h
      | `Input -> Brr_lwd.Elwd.handler Brr.Ev.input h
    in
    let ev = [ `P set ] in
    let at =
      let v =
        let$ v = Lwd.get var in
        Brr.At.value (Jstr.of_float v)
      in
      let type' =
        match type' with
        | None -> []
        | Some t -> [ `P (Brr.At.type' (Jstr.v t)) ]
      in
      `R v :: type'
    in
    Brr_lwd.Elwd.input ~at ~ev ()

  let of_color (c : Drawing.Color.t Lwd.var) =
    let set =
      Brr_lwd.Elwd.handler Brr.Ev.change (fun ev ->
          let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
          let new_value =
            Jv.get el "value" |> Jv.to_string |> Drawing.Color.of_string
          in
          Brr.Console.(log [ new_value ]);
          Lwd.set c new_value)
    in
    let ev = [ `P set ] in
    let at =
      let v =
        let$ v = Lwd.get c in
        Brr.At.value (v |> Drawing.Color.to_string |> Jstr.of_string)
      in
      [ `R v ]
    in
    let children =
      List.map
        (fun col ->
          let at = if col = Lwd.peek c then [ Brr.At.selected ] else [] in
          `P (Brr.El.option ~at [ Brr.El.txt' (Drawing.Color.to_string col) ]))
        Drawing.Color.all
    in
    Brr_lwd.Elwd.select ~at ~ev children
end

let slider =
  let el = UI.float ~type':"range" ~kind:`Input time in
  Brr_lwd.Elwd.div [ `R el ]

module Recording = struct
  open Lwd_infix

  type pfo = {
    size : float option Lwd.var;
    thinning : float option;
    smoothing : float option;
    streamline : float option;
  }

  type stro = {
    id : string;
    scale : float;
    path : ((float * float) * float) list (* TODO: (position * time) list *);
    total_duration : float;
    color : Drawing.Color.t Lwd.var;
    opacity : float Lwd.var;
    options : pfo;
  }

  type timed_event = { event : stro; time : float Lwd.var }

  type t = timed_event list
  (** Ordered by time *)

  type record = { start_time : float; evs : t }

  let record_of_record ({ start_time; evs } : Drawing.Action.Record.record) =
    let evs =
      List.filter_map
        (function
          | {
              Drawing.Action.Record.event =
                Stroke
                  { id; scale; path; total_duration; color; opacity; options };
              time;
            } ->
              let color = Lwd.var color in
              let opacity = Lwd.var opacity in
              let options =
                let thinning = Perfect_freehand.Options.thinning options in
                let size = Lwd.var @@ Perfect_freehand.Options.size options in
                let smoothing = Perfect_freehand.Options.smoothing options in
                let streamline = Perfect_freehand.Options.streamline options in
                { size; thinning; smoothing; streamline }
              in
              let event =
                { id; scale; path; total_duration; color; opacity; options }
              in
              let time = Lwd.var time in
              Some { event; time }
          | { event = Erase _; _ } -> None)
        evs
    in
    { start_time; evs }

  let record_to_record ({ start_time; evs } : record) =
    let evs =
      List.map
        (fun {
               event =
                 {
                   id;
                   scale;
                   path;
                   total_duration;
                   color;
                   opacity;
                   options = { size; thinning; smoothing; streamline };
                 };
               time;
             } ->
          let color = Lwd.peek color in
          let opacity = Lwd.peek opacity in
          let time = Lwd.peek time in
          let options =
            let size = Lwd.peek size in
            Perfect_freehand.Options.v ?size ?thinning ?smoothing ?streamline ()
          in
          let event =
            {
              Drawing.Stroke.id;
              scale;
              path;
              total_duration;
              color;
              opacity;
              options;
            }
          in
          { Drawing.Action.Record.event = Stroke event; time })
        evs
    in
    { Drawing.Action.Record.start_time; evs }

  let current = Lwd.var None
  let set_current c = Lwd.set current (Option.map record_of_record c)
  let peek_current () = Lwd.peek current
  let current = Lwd.get current

  let el_of_stroke (stroke : stro) =
    let option = UI.of_color stroke.color in
    Brr_lwd.Elwd.div [ `R option ]

  let el =
    let display =
      let$ current = current in
      match current with
      | None ->
          Lwd_seq.element @@ Brr.At.class' (Jstr.v "slipshow-dont-display")
      | Some _ -> Lwd_seq.empty
    in
    let strokes =
      let$ current = current in
      match current with
      | None -> Lwd_seq.empty
      | Some current ->
          List.map (fun (stroke : timed_event) -> stroke.event) current.evs
          |> List.map el_of_stroke |> List.rev (* TODO: Why rev? *)
          |> Lwd_seq.of_list
    in
    let strokes = Lwd_seq.lift strokes in
    let ti =
      let$ time = Lwd.get time in
      Brr.El.div [ Brr.El.txt' (string_of_float time) ]
    in
    Brr_lwd.Elwd.div
      ~at:[ `P (Brr.At.id (Jstr.v "slipshow-drawing-editor")); `S display ]
      [ `R ti; `R slider; `S strokes ]
end

module Svg = struct
  open Lwd.Infix

  let to_stroke ~elapsed_time =
   fun {
         Recording.id;
         scale;
         path;
         total_duration;
         color;
         opacity;
         options = { size; thinning; smoothing; streamline };
       } ->
    let$* color = Lwd.get color in
    let$* elapsed_time = elapsed_time in
    let$* opacity = Lwd.get opacity in
    let$ size = Lwd.get size in
    let path = List.filter (fun (_, t) -> t <= elapsed_time) path in
    let options =
      Perfect_freehand.Options.v ?size ?thinning ?smoothing ?streamline ()
    in
    let event =
      {
        Drawing.Stroke.id;
        scale;
        path;
        total_duration;
        color;
        opacity;
        options;
      }
    in
    event

  let stroke_until ~elapsed_time (stroke : Recording.stro) =
    let$ stroke = to_stroke ~elapsed_time stroke in
    let el = Drawing.Action.create_elem_of_stroke stroke in
    el

  let draw_until ~elapsed_time (record : Recording.record) =
    let res =
      List.map
        (fun { Recording.event; time = ctime } ->
          let$* should_display =
            let$* elapsed_time = elapsed_time in
            let$ time = Lwd.get ctime in
            elapsed_time >= time
          in
          if should_display then
            let elapsed_time =
              let$* elapsed_time = elapsed_time in
              let$ time = Lwd.get ctime in
              elapsed_time -. time
            in
            let$ res = stroke_until ~elapsed_time event in
            Some res
          else Lwd.return None)
        record.evs
    in
    res |> Lwd_seq.of_list |> Lwd.return |> Lwd_seq.lift
    |> Lwd_seq.filter_map Fun.id

  let el =
    let content =
      let$* time_slider = Lwd.get time in
      let$* recording = Recording.current in
      match recording with
      | None -> Lwd.return Lwd_seq.empty
      | Some recording ->
          let elapsed_time =
            match recording.evs with
            | [] -> Lwd.return time_slider
            (* | { time; event = Erase _ } :: _ -> time *. time_slider /. 100. *)
            | { time; event = (* Stroke *) { total_duration; _ } } :: _ ->
                let$ time = Lwd.get time in
                (time +. total_duration) *. time_slider /. 100.
          in
          (* let recording = Recording.record_to_record recording in *)
          let els = draw_until ~elapsed_time recording in
          (* Lwd_seq.of_list els *)
          els
    in
    Brr_lwd.Elwd.v ~ns:`SVG (Jstr.v "svg")
      ~at:
        [
          `P
            (Brr.At.style
               (Jstr.v "overflow:visible; position: absolute; z-index:1001"));
        ]
      [ `S content ]
end
