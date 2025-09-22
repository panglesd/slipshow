open State_types

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
                selected = Lwd.var (Lwd.return false);
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
