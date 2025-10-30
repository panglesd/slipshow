open State_types
open Lwd_infix

let move_handler stroke =
  let has_moved = ref false in
  let click_handler =
    Brr_lwd.Elwd.handler Brr.Ev.click (fun _ ->
        if !has_moved then () else Lwd.update not stroke.selected)
  in
  let mouse_move x y path =
   fun ev ->
    has_moved := true;
    let ev = Brr.Ev.as_type ev in
    let x' = Brr.Ev.Mouse.client_x ev in
    let dx = x' -. x in
    let y' = Brr.Ev.Mouse.client_y ev in
    let dy = y' -. y in
    let new_path = Path_editing.translate_space path dx dy in
    Lwd.set stroke.path new_path
  in
  let move_handler =
    Brr_lwd.Elwd.handler Brr.Ev.mousedown (fun ev ->
        Brr.Ev.prevent_default ev;
        has_moved := false;
        let path = Lwd.peek stroke.path in
        let ev = Brr.Ev.as_type ev in
        let x = Brr.Ev.Mouse.client_x ev in
        let y = Brr.Ev.Mouse.client_y ev in
        let id =
          Brr.Ev.listen Brr.Ev.mousemove (mouse_move x y path)
            (Brr.Document.body Brr.G.document |> Brr.El.as_target)
        in
        let opts = Brr.Ev.listen_opts ~once:true () in
        let _id =
          Brr.Ev.listen ~opts Brr.Ev.mouseup
            (fun _ -> Brr.Ev.unlisten id)
            (Brr.Document.body Brr.G.document |> Brr.El.as_target)
        in
        ())
  in
  [ `P click_handler; `P move_handler ]

let create_elem_of_stroke ~elapsed_time
    ({
       scale;
       color;
       id;
       width;
       stroker;
       path;
       end_at;
       starts_at = _;
       selected;
       preselected;
       track = _;
       erased;
     } as stroke) =
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
        let path = List.map fst path in
        let options = Drawing.Strokes.options_of stroker width in
        let v = Jstr.v (Drawing.Strokes.svg_path options scale path) in
        Brr.At.v (Jstr.v "d") v
      in
      let$* path = Lwd.get path in
      if should_continue then
        let$ elapsed_time = elapsed_time in
        let path = List.filter (fun (_, t) -> t < elapsed_time) path in
        with_path path
      else Lwd.pure @@ with_path path
    in
    let fill =
      let$* color = Lwd.get color
      and$ erased = Lwd.get erased
      and$ elapsed_time = elapsed_time in
      let$ color =
        match erased with
        | Some erased ->
            let$ at = Lwd.get erased.at in
            if elapsed_time > at then "transparent"
            else Drawing.Color.to_string color
        | None -> Lwd.pure @@ Drawing.Color.to_string color
      in
      Brr.At.v (Jstr.v "fill") (Jstr.v color)
    in
    let id = Brr.At.id (Jstr.v id) in
    let opacity =
      let opacity = match stroker with Highlighter -> 0.33 | Pen -> 1. in
      Brr.At.v (Jstr.v "opacity") (opacity |> Jstr.of_float)
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
    [ `R fill; `P id; `P opacity; `R d; `S selected ]
  in
  let ev = move_handler stroke in
  let st =
    let scale = 1. /. scale in
    let scale = string_of_float scale in
    let ( !! ) = Jstr.v in
    let s = "scale3d(" ^ scale ^ "," ^ scale ^ "," ^ scale ^ ")" in
    [ `P (!!"transform", !!s) ]
  in
  Brr_lwd.Elwd.v ~ns:`SVG ~at ~ev ~st (Jstr.v "path") []

let draw_until ~elapsed_time (record : t) =
  Lwd_table.map_reduce
    (fun _ stro ->
      let res =
        let$ elem = create_elem_of_stroke ~elapsed_time stro
        and$ track = Lwd.get stro.track
        and$ path = Lwd.get stro.path in
        (track, snd (List.hd path), elem)
      in
      Lwd_seq.element res)
    Lwd_seq.monoid record.strokes
  |> Lwd_seq.lift
  |> Lwd_seq.sort_uniq (fun (t1, t1', _) (t2, t2', _) ->
         match Int.compare t1 t2 with
         | (1 | -1) as res -> res
         | _ -> Float.compare t1' t2')
  |> Lwd_seq.map (fun (_, _, e) -> e)

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
