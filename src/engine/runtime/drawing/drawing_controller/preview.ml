open Lwd_infix
open Drawing_state
open Brr_lwd

let ( !! ) = Jstr.v
let empty_d = Lwd.pure (Brr.At.v (Jstr.v "d") Jstr.empty)

let d ~elapsed_time ~starts_at ~end_at ~final_d ~scale ~path kind =
  match elapsed_time with
  | None -> final_d
  | Some elapsed_time' ->
      (* Built once, so that the bind below only chooses between existing
         nodes, instead of building a new graph at each change of time. *)
      let partial =
        Drawing_state.Path_editing.make_d kind ~elapsed_time ~scale path
      in
      let$* starts_at = starts_at
      and$ end_at = end_at
      and$ elapsed_time' = elapsed_time' in
      if end_at < elapsed_time' then final_d
      else if elapsed_time' <= starts_at then empty_d
      else partial

let pen_attributes ~starts_at ~end_at ~final_d ~width ~elapsed_time ~scale ~path
    ~erased ~color ~id ~selected ~preselected =
  let at =
    let d =
      let$* width = Lwd.get width in
      d ~elapsed_time ~starts_at ~end_at ~final_d ~scale ~path (`Pfh width)
    in
    let fill =
      let$ color =
        let$* erased = Lwd.get erased and$ color = Lwd.get color in
        match erased with
        | Some erased -> (
            match elapsed_time with
            | None -> Lwd.pure "transparent"
            | Some elapsed_time ->
                let$ elapsed_time = elapsed_time and$ at = Lwd.get erased.at in
                if elapsed_time > at then "transparent" else color)
        | None -> Lwd.pure color
      in
      Brr.At.v (Jstr.v "fill") (Jstr.v color)
    in
    let id = Brr.At.id (Jstr.v id) in
    let opacity = Brr.At.v (Jstr.v "opacity") (Jstr.of_float 1.) in
    let selected =
      let$ selected = Lwd.get selected
      and$ preselected = Lwd.get preselected
      and$ erased =
        let$* v = Lwd.get erased in
        match v with
        | None -> Lwd.pure None
        | Some { selected; preselected; _ } ->
            let$ selected = Lwd.get selected
            and$ preselected = Lwd.get preselected in
            Some (selected, preselected)
      in
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
      else
        match erased with
        | Some (true, _) | Some (_, true) ->
            Lwd_seq.of_list
            @@ [
                 Brr.At.v (Jstr.v "stroke") (Jstr.v "orange");
                 Brr.At.v (Jstr.v "stroke-width") (Jstr.v "4px");
               ]
        | _ -> Lwd_seq.empty
    in
    [ `R fill; `P id; `P opacity; `R d; `S selected ]
  in
  let st =
    let scale = 1. /. scale in
    let scale = string_of_float scale in
    let ( !! ) = Jstr.v in
    let s = "scale3d(" ^ scale ^ "," ^ scale ^ "," ^ scale ^ ")" in
    [ `P (!!"transform", !!s) ]
  in
  Elwd.v ~ns:`SVG ~at ~st (Jstr.v "path") []

let highlight_attributes ~starts_at ~end_at ~final_d ~elapsed_time ~width ~path
    ~color ~selected ~preselected ~erased ~scale ~id =
  let at =
    let d = d ~elapsed_time ~starts_at ~end_at ~final_d ~scale ~path `Normal in
    let stroke =
      let$ width =
        let$ width = Lwd.get width in
        Jstr.append (Jstr.of_float (width *. 3.)) (Jstr.v "px")
      and$ selected = Lwd.get selected
      and$ preselected = Lwd.get preselected
      and$ color =
        let$* erased = Lwd.get erased and$ color = Lwd.get color in
        match erased with
        | Some erased -> (
            match elapsed_time with
            | None -> Lwd.pure "transparent"
            | Some elapsed_time ->
                let$ elapsed_time = elapsed_time and$ at = Lwd.get erased.at in
                if elapsed_time > at then "transparent" else color)
        | None -> Lwd.pure color
      in
      if selected then
        Lwd_seq.of_list
        @@ [
             Brr.At.v (Jstr.v "stroke") (Jstr.v "darkorange");
             Brr.At.v (Jstr.v "stroke-width") width;
           ]
      else if preselected then
        Lwd_seq.of_list
        @@ [
             Brr.At.v (Jstr.v "stroke") (Jstr.v "orange");
             Brr.At.v (Jstr.v "stroke-width") width;
           ]
      else
        Lwd_seq.of_list
        @@ [
             Brr.At.v (Jstr.v "stroke") (Jstr.v color);
             Brr.At.v (Jstr.v "stroke-width") width;
           ]
    in
    let opacity = Brr.At.v (Jstr.v "opacity") (Jstr.of_float 0.33) in
    let fill = Brr.At.v (Jstr.v "fill") (Jstr.v "none") in
    let stroke_linecap = Brr.At.v (Jstr.v "stroke-linecap") (Jstr.v "round") in
    let stroke_linejoin =
      Brr.At.v (Jstr.v "stroke-linejoin") (Jstr.v "round")
    in
    let id = Brr.At.id (Jstr.v id) in
    [
      `P opacity;
      `S stroke;
      `R d;
      `P id;
      `P fill;
      `P stroke_linecap;
      `P stroke_linejoin;
    ]
  in
  let st =
    let scale = 1. /. scale in
    let scale = string_of_float scale in
    let ( !! ) = Jstr.v in
    let s = "scale3d(" ^ scale ^ "," ^ scale ^ "," ^ scale ^ ")" in
    [ `P (!!"transform", !!s) ]
  in
  Elwd.v ~ns:`SVG ~at ~st (Jstr.v "path") []

let create_elem_of_stroke ~elapsed_time
    {
      scale;
      color;
      id;
      width;
      stroker;
      path;
      end_at;
      starts_at;
      selected;
      preselected;
      track = _;
      erased;
      final_d;
    } =
  let$* scale = Lwd.get scale in
  match stroker with
  | Highlighter ->
      highlight_attributes ~starts_at ~end_at ~final_d ~scale ~color ~id ~width
        ~path ~selected ~preselected ~erased ~elapsed_time
  | Pen ->
      pen_attributes ~starts_at ~end_at ~final_d ~scale ~color ~id ~width ~path
        ~selected ~preselected ~erased ~elapsed_time

let draw ~elapsed_time strokes =
  Lwd_table.map_reduce
    (fun _ stro ->
      let res =
        let$ elem = create_elem_of_stroke ~elapsed_time stro
        and$ track = Lwd.get stro.track
        and$ path = Lwd.get stro.path in
        (track, snd (List.hd path), elem, stro.id)
      in
      Lwd_seq.element res)
    Lwd_seq.monoid strokes
  |> Lwd_seq.lift
  |> Lwd_seq.sort_uniq (fun (t1, t1', _el1, id1) (t2, t2', _el2, id2) ->
      match Int.compare t1 t2 with
      | (1 | -1) as res -> res
      | _ -> (
          match Float.compare t1' t2' with
          | (1 | -1) as res -> res
          | _ -> String.compare id1 id2))
  |> Lwd_seq.map (fun (_, _, e, _) -> e)

let live_svg replaying_state =
  let recording = replaying_state.recording in
  let$* anchored = Lwd.get (snd recording.element_anchor) in
  if anchored = `Unanchored then
    Brr_lwd.Elwd.div ~st:[ `P (Jstr.v "display", Jstr.v "None") ] []
  else
    let act ~time strokes =
      let content = draw ~elapsed_time:time strokes in
      Brr_lwd.Elwd.v ~ns:`SVG (Jstr.v "g") [ `S content ]
    in
    let reactive =
      let open Lwd_infix in
      let$* status = Status.get in
      let one_or_two =
        match status with
        | Drawing
            (Recording { replaying_state; recording_temp; replayed_part; _ })
          when replaying_state.recording.record_id = recording.record_id ->
            Lwd_seq.of_list
            @@ [ act ~time:None recording_temp; act ~time:None replayed_part ]
        | _ ->
            Lwd_seq.element
            @@ act ~time:(Some (Lwd.get replaying_state.time)) recording.strokes
      in
      Lwd_seq.lift (Lwd.pure one_or_two)
    in
    let el = Brr_lwd.Elwd.v ~ns:`SVG (Jstr.v "g") [ `S reactive ] in
    Brr_lwd.Elwd.v ~ns:`SVG (Jstr.v "svg")
      ~st:
        [
          `P (!!"overflow", !!"visible");
          `P (!!"display", !!"inline-block");
          `P (!!"width", !!"10px");
          `P (!!"height", !!"10px");
          `P (!!"position", !!"relative");
          (* TODO: find out why 18px *)
          `P (!!"top", !!"-18px");
        ]
      [ `R el ]

let drawing_area =
  let act ~time strokes =
    let content = draw ~elapsed_time:time strokes in
    Elwd.v ~ns:`SVG (Jstr.v "g") [ `S content ]
  in
  let all_drawings =
    let$* status = Status.get in
    Lwd_table.map_reduce
      (fun _row { recording; time; is_playing = _ } ->
        let$ anchored = Lwd.get (snd recording.element_anchor) in
        if anchored = `Anchored then Lwd_seq.empty
        else
          match status with
          | Drawing
              (Recording { replaying_state; recording_temp; replayed_part; _ })
            when replaying_state.recording.record_id = recording.record_id ->
              Lwd_seq.of_list
              @@ [ act ~time:None recording_temp; act ~time:None replayed_part ]
          | _ ->
              Lwd_seq.element
              @@ act ~time:(Some (Lwd.get time)) recording.strokes)
      Lwd_seq.lwd_monoid workspaces.recordings
    |> Lwd.bind ~f:Lwd_seq.lift
  in
  let drawn_live_drawing =
    act ~time:None Drawing_state.workspaces.live_drawing
  in
  Elwd.v ~ns:`SVG (Jstr.v "g") [ `S all_drawings; `R drawn_live_drawing ]

let init_drawing_area () =
  let content =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
    |> Option.get
  in
  let _root = Elwd.prepend_child content drawing_area in
  ()

let for_events =
  let drawing_started_time = Tools.now () in
  (* Just to avoid one level of indentation... *)
  Fun.id @@ fun window ->
  let open Lwd_infix in
  let panel =
    let handler =
      let$* status = Status.get in
      let draw_mode d =
        let { tool; color; width } = live_drawing_state in
        let$ tool = Lwd.get tool
        and$ color = Lwd.get color
        and$ width = Lwd.get width in
        match tool with
        | Stroker stroker ->
            let strokes, started_time, element_anchor =
              match d with
              | Presenting ->
                  (workspaces.live_drawing, drawing_started_time, None)
              | Recording { started_at; replaying_state; recording_temp; _ } ->
                  ( recording_temp,
                    started_at,
                    Some (fst replaying_state.recording.element_anchor) )
            in
            Lwd_seq.element
            @@ Tools.Draw_stroke.event window ~started_time ?element_anchor
                 strokes stroker color width
        | Pointer -> Lwd_seq.empty
        | Eraser ->
            let strokes, started_time, replayed_part, element_anchor =
              match d with
              | Recording
                  {
                    replaying_state;
                    recording_temp;
                    started_at;
                    unplayed_erasure = _;
                    replayed_part;
                  } ->
                  ( recording_temp,
                    started_at,
                    Some replayed_part,
                    Some (fst replaying_state.recording.element_anchor) )
              | Presenting -> (workspaces.live_drawing, Tools.now (), None, None)
            in
            Lwd_seq.element
            @@ Tools.Erase.event window ?element_anchor ~started_time
                 ~replayed_strokes:replayed_part strokes
      in
      match status with
      | Drawing d -> draw_mode d
      | Editing -> Lwd.pure Lwd_seq.empty
      | Gui_mode ->
          (* One time I should unify all those "for-events" *)
          Lwd.pure Lwd_seq.empty
    in
    let display =
      let$* status = Status.get in
      let$ tool = Lwd.get live_drawing_state.tool in
      match (status, tool) with
      | Drawing _, (Stroker _ | Eraser) -> (!!"display", !!"block")
      | _ -> (!!"display", !!"none")
    in
    Elwd.div
      ~ev:[ `S handler ]
      ~at:[ `P (Brr.At.id !!"slipshow-drawing-recording-for-events") ]
      ~st:
        [
          (* `R cursor; *)
          `R display;
          `P (!!"position", !!"absolute");
          `P (!!"top", !!"0");
          `P (!!"left", !!"0");
          `P (!!"right", !!"0");
          `P (!!"bottom", !!"0");
        ]
      [ (* `S preview_box *) ]
  in
  let main =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
  in
  let _root = Elwd.append_child main panel in
  ()
