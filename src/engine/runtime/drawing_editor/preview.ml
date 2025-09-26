open State_types
open Lwd_infix

let create_elem_of_stroke ~elapsed_time
    {
      options;
      scale;
      color;
      opacity;
      id;
      path;
      end_at;
      starts_at = _;
      selected;
      preselected;
    } =
  let at =
    let d =
      let$* end_at = end_at in
      let$* should_continue =
        (* I was hoping that when a value does not change, the recomputation
           stops. See https://github.com/let-def/lwd/issues/55 *)
        let$ elapsed_time = elapsed_time in
        elapsed_time <= end_at
      in
      let with_path path =
        let$ options =
          let$ size = Lwd.get options.size in
          Perfect_freehand.Options.v ~size ?thinning:options.thinning
            ?streamline:options.streamline ?smoothing:options.smoothing ()
        in
        let v = Jstr.v (Drawing.Action.svg_path options scale path) in
        Brr.At.v (Jstr.v "d") v
      in
      let$* path = Lwd.get path in
      if should_continue then
        let$* elapsed_time = elapsed_time in
        let path = List.filter (fun (_, t) -> t < elapsed_time) path in
        with_path path
      else with_path path
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
      let$ selected = Lwd.get selected and$ preselected = Lwd.get preselected in
      if selected then
        Lwd_seq.of_list
        @@ [
             Brr.At.v (Jstr.v "stroke") (Jstr.v "darkorange");
             Brr.At.v (Jstr.v "stroke-width") (Jstr.v "4px");
           ]
      else if preselected then
        Lwd_seq.of_list
        @@ [
             Brr.At.v (Jstr.v "stroke") (Jstr.v "orange");
             Brr.At.v (Jstr.v "stroke-width") (Jstr.v "4px");
           ]
      else Lwd_seq.empty
    in
    [ `R fill; `P id; `P style; `R opacity; `R d; `S selected ]
  in
  Brr_lwd.Elwd.v ~ns:`SVG ~at (Jstr.v "path") []

let draw_until ~elapsed_time (record : t) =
  Lwd_table.map_reduce
    (fun _ event ->
      let res = create_elem_of_stroke ~elapsed_time event in
      Lwd_seq.element res)
    Lwd_seq.monoid record.strokes
  |> Lwd_seq.lift

let el =
  let gs =
    let$* content =
      let$ recording = State.Recording.current in
      match recording with
      | Some recording ->
          let elapsed_time = Lwd.get State.time in
          draw_until ~elapsed_time recording
      | None -> Lwd.pure Lwd_seq.empty
    in
    (* From what I remember when I did this, the reason for an intermediate
         "g" is that with the current "Lwd.observe" implementation, taken from
         the brr-lwd example, only the attributes/children will be updated, not
         the element itself *)
    Brr_lwd.Elwd.v ~ns:`SVG (Jstr.v "g") [ `S content ]
  in
  Brr_lwd.Elwd.v ~ns:`SVG (Jstr.v "svg")
    ~at:
      [
        `P
          (Brr.At.style
             (Jstr.v "overflow:visible; position: absolute; z-index:1001"));
      ]
    [ `R gs ]
