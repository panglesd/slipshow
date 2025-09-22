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
  let float ?type' ?(kind = `Change) var attrs =
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
      (`R v :: type') @ attrs
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
  let el =
    UI.float ~type':"range" ~kind:`Input time
      [ `P (Brr.At.id (Jstr.v "slipshow-time_slider")) ]
  in
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
    selected : bool Lwd.var;
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
                {
                  id;
                  scale;
                  path;
                  total_duration;
                  color;
                  opacity;
                  options;
                  selected = Lwd.var false;
                }
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
                   selected = _;
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
    let handler1 =
      Brr_lwd.Elwd.handler Brr.Ev.mouseenter (fun _ ->
          Lwd.set stroke.selected true)
    in
    let handler2 =
      Brr_lwd.Elwd.handler Brr.Ev.mouseleave (fun _ ->
          Lwd.set stroke.selected false)
    in
    let ev = [ `P handler1; `P handler2 ] in
    Brr_lwd.Elwd.div ~ev [ `R option ]

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
  let create_elem_of_stroke ~elapsed_time
      {
        Recording.options;
        scale;
        color;
        opacity;
        id;
        path;
        total_duration = _;
        selected;
      } =
    let at =
      let d =
        let$* elapsed_time = elapsed_time in
        let path = List.filter (fun (_, t) -> t <= elapsed_time) path in
        let$ options =
          let$ size = Lwd.get options.size in
          Perfect_freehand.Options.v ?size ?thinning:options.thinning
            ?streamline:options.streamline ?smoothing:options.smoothing ()
        in
        let v = Jstr.v (Drawing.Action.svg_path options scale path) in
        Brr.At.v (Jstr.v "d") v
      in
      let fill =
        let$ color = Lwd.get color in
        Brr.At.v (Jstr.v "fill") (Jstr.v (Drawing.Color.to_string color))
      in
      let id = Brr.At.id (Jstr.v id) in
      let style =
        let scale = 1. /. scale in
        let scale = string_of_float scale in
        let s =
          Jstr.v @@ "scale3d(" ^ scale ^ "," ^ scale ^ "," ^ scale ^ ")"
        in
        Brr.At.style s
      in
      let opacity =
        let$ opacity = Lwd.get opacity in
        Brr.At.v (Jstr.v "opacity") (opacity |> string_of_float |> Jstr.v)
      in
      let selected =
        let$ selected = Lwd.get selected in
        if selected then
          Lwd_seq.of_list
          @@ [
               Brr.At.v (Jstr.v "stroke") (Jstr.v "darkorange");
               Brr.At.v (Jstr.v "stroke-width") (Jstr.v "2px");
             ]
        else Lwd_seq.empty
      in
      [ `R fill; `P id; `P style; `R opacity; `R d; `S selected ]
    in
    Brr_lwd.Elwd.v ~ns:`SVG ~at (Jstr.v "path") []

  let draw_until ~elapsed_time (record : Recording.record) =
    List.map
      (fun { Recording.event; time = ctime } ->
        let diff =
          let ctime = Lwd.get ctime in
          let$* elapsed_time = elapsed_time in
          let$ time = ctime in
          let res = elapsed_time -. time in
          res
        in
        let res = create_elem_of_stroke ~elapsed_time:diff event in
        `R res)
      record.evs

  let el =
    let gs =
      let$* content =
        let$* time_slider = Lwd.get time in
        let$ recording = Recording.current in
        match recording with
        | None -> []
        | Some recording ->
            let elapsed_time =
              match recording.evs with
              | [] -> Lwd.return time_slider
              | { time; event = { total_duration; _ } } :: _ ->
                  let$ time = Lwd.get time in
                  (time +. total_duration) *. time_slider /. 100.
            in
            draw_until ~elapsed_time recording
      in
      (* From what I remember when I did this, the reason for an intermediate
         "g" is that with the current "Lwd.observe" implementation, taken from
         the brr-lwd example, only the attributes/children will be updated, not
         the element itself *)
      Brr_lwd.Elwd.v ~ns:`SVG (Jstr.v "g") content
    in
    Brr_lwd.Elwd.v ~ns:`SVG (Jstr.v "svg")
      ~at:
        [
          `P
            (Brr.At.style
               (Jstr.v "overflow:visible; position: absolute; z-index:1001"));
        ]
      [ `R gs ]
end
