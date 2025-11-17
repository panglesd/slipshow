open Lwd_infix
open Drawing_state.Live_coding
open Brr_lwd

let ( !! ) = Jstr.v

let pfo_options width =
  let size = width in
  Perfect_freehand.Options.v ~thinning:0.5 ~smoothing:0.5 ~size ~streamline:0.5
    ~last:true ()

let make_d ~elapsed_time path path_to_svg =
  (* TODO: DO NOT DELETE THIS COMMENT! *)
  (* let$* end_at = end_at in *)
  (* let$* should_continue = *)
  (*   (\* I was hoping that when a value does not change, the recomputation *)
  (*    stops. See https://github.com/let-def/lwd/issues/55 *\) *)
  (*   let$ elapsed_time = elapsed_time in *)
  (*   elapsed_time <= end_at *)
  (* in *)
  let with_path path =
    let path = List.map fst path in
    let v = path_to_svg path in
    Brr.At.v (Jstr.v "d") v
  in
  let$* path = Lwd.get path in
  match elapsed_time with
  | None -> Lwd.pure @@ with_path path
  | Some elapsed_time ->
      let$ elapsed_time = elapsed_time in
      let path = List.filter (fun (_, t) -> t < elapsed_time) path in
      with_path path

let pen_attributes ~width ~elapsed_time ~scale ~path ~erased ~color ~id
    ~selected ~preselected =
  let at =
    let d =
      make_d ~elapsed_time path @@ fun path ->
      let options = pfo_options width in
      Drawing_state.Path_editing.pfo_svg_path options scale path
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
  let st =
    let scale = 1. /. scale in
    let scale = string_of_float scale in
    let ( !! ) = Jstr.v in
    let s = "scale3d(" ^ scale ^ "," ^ scale ^ "," ^ scale ^ ")" in
    [ `P (!!"transform", !!s) ]
  in
  Elwd.v ~ns:`SVG ~at ~st (Jstr.v "path") []

let highlight_attributes ~elapsed_time ~width ~path ~color ~selected
    ~preselected ~erased ~scale ~id =
  let at =
    let d =
      make_d ~elapsed_time path @@ fun path ->
      Drawing_state.Path_editing.svg_path scale path
    in
    let stroke =
      let width = Jstr.append (Jstr.of_float (width *. 3.)) (Jstr.v "px") in
      let$ selected = Lwd.get selected
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
      end_at = _;
      starts_at = _;
      selected;
      preselected;
      track = _;
      erased;
    } =
  match stroker with
  | Highlighter ->
      highlight_attributes ~scale ~color ~id ~width ~path ~selected ~preselected
        ~erased ~elapsed_time
  | Pen ->
      pen_attributes ~scale ~color ~id ~width ~path ~selected ~preselected
        ~erased ~elapsed_time

let draw ~elapsed_time strokes =
  Lwd_table.map_reduce
    (fun _ stro ->
      let res =
        let$ elem = create_elem_of_stroke ~elapsed_time stro
        and$ track = Lwd.get stro.track
        and$ path = Lwd.get stro.path in
        (track, snd (List.hd path), elem)
      in
      Lwd_seq.element res)
    Lwd_seq.monoid strokes
  |> Lwd_seq.lift
  |> Lwd_seq.sort_uniq (fun (t1, t1', el1) (t2, t2', el2) ->
         match Int.compare t1 t2 with
         | (1 | -1) as res -> res
         | _ -> (
             match Float.compare t1' t2' with
             | (1 | -1) as res -> res
             | _ -> compare el1 el2))
  |> Lwd_seq.map (fun (_, _, e) -> e)

let drawing_area =
  let act ~time strokes =
    let content = draw ~elapsed_time:time strokes in
    Elwd.v ~ns:`SVG (Jstr.v "g") [ `S content ]
  in
  let all_drawings =
    let$ all_replayed =
      Lwd_table.map_reduce
        (fun _row { recording; time } ->
          Lwd_seq.element @@ act ~time:(Some (Lwd.get time)) recording.strokes)
        Lwd_seq.monoid workspaces.recordings
      |> Lwd_seq.lift
    and$ recorded_drawing =
      let strokes = workspaces.current_recording.recording.strokes in
      let$ u =
        let$* time =
          let$ status = Lwd.get status in
          match status with
          | Drawing _ -> None
          | Editing ->
              let time = workspaces.current_recording.time in
              Some (Lwd.get time)
        in
        act ~time strokes
      in
      Lwd_seq.element u
    in
    Lwd_seq.concat all_replayed recorded_drawing
  in
  let drawn_live_drawing =
    act ~time:None Drawing_state.Live_coding.workspaces.live_drawing
  in
  Elwd.v ~ns:`SVG (Jstr.v "g") [ `S all_drawings; `R drawn_live_drawing ]

let init_drawing_area () =
  let svg = drawing_area in
  let svg = Lwd.observe svg in
  let on_invalidate _ =
    let _ : int =
      Brr.G.request_animation_frame @@ fun _ ->
      let _ui = Lwd.quick_sample svg in
      (* Beware that due to this being ignored, a changed "root" element will
         not be updated by Lwd, only its reactive attributes/children *)
      ()
    in
    ()
  in
  let content =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
    |> Option.get
  in
  Brr.El.prepend_children content [ Lwd.quick_sample svg ];
  Lwd.set_on_invalidate svg on_invalidate;
  ()

let for_events () =
  let open Lwd_infix in
  let panel =
    let handler =
      let$* status = Lwd.get status in
      let draw_mode d =
        let strokes, started_time =
          match d with
          | Presenting -> (workspaces.live_drawing, Tools.now ())
          | Recording { started_at } ->
              let strokes = workspaces.current_recording.recording.strokes in
              (strokes, started_at)
        in
        let { tool; color; width } = live_drawing_state in
        let$ tool = Lwd.get tool
        and$ color = Lwd.get color
        and$ width = Lwd.get width in
        match tool with
        | Stroker stroker ->
            Lwd_seq.element
            @@ Tools.Draw_stroke.event ~started_time strokes stroker color width
        | Pointer -> Lwd_seq.empty
        | Eraser -> Lwd_seq.element @@ Tools.Erase.event ~started_time strokes
      in
      match status with
      | Drawing d -> draw_mode d
      | Editing -> Lwd.pure Lwd_seq.empty
    in
    let display =
      let$* status = Lwd.get Drawing_state.Live_coding.status in
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
  let ui = Lwd.observe panel in
  let on_invalidate _ =
    let _ : int =
      Brr.G.request_animation_frame @@ fun _ ->
      let _ui = Lwd.quick_sample ui in
      (* Beware that due to this being ignored, a changed "root" element will
         not be updated by Lwd, only its reactive attributes/children *)
      ()
    in
    ()
  in
  let main =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
  in
  Brr.El.append_children main [ Lwd.quick_sample ui ];
  Lwd.set_on_invalidate ui on_invalidate;
  ()
