open State_types
open Lwd_infix

let create_elem_of_stroke ~elapsed_time
    { options; scale; color; opacity; id; path; total_duration = _; selected } =
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
      let s = Jstr.v @@ "scale3d(" ^ scale ^ "," ^ scale ^ "," ^ scale ^ ")" in
      Brr.At.style s
    in
    let opacity =
      let$ opacity = Lwd.get opacity in
      Brr.At.v (Jstr.v "opacity") (opacity |> string_of_float |> Jstr.v)
    in
    let selected =
      let$ selected = Lwd.join @@ Lwd.get selected in
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

let draw_until ~elapsed_time (record : record) =
  List.map
    (fun { event; time = ctime } ->
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
      let$* time_slider = Lwd.get State.time in
      let$ recording = State.Recording.current in
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
