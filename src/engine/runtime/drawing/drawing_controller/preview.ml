open Lwd_infix
open Drawing_state.Live_coding
open Brr_lwd

let ( !! ) = Jstr.v

let options_of _stroker width =
  let size = width in
  Perfect_freehand.Options.v ~thinning:0.5 ~smoothing:0.5 ~size ~streamline:0.5
    ~last:false ()

let create_elem_of_stroke ~elapsed_time
    ({
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
     } as _stroke) =
  let at =
    let d =
      (* let$* end_at = end_at in *)
      (* let$* should_continue = *)
      (*   (\* I was hoping that when a value does not change, the recomputation *)
      (*    stops. See https://github.com/let-def/lwd/issues/55 *\) *)
      (*   let$ elapsed_time = elapsed_time in *)
      (*   elapsed_time <= end_at *)
      (* in *)
      let with_path path =
        let path = List.map fst path in
        let options = options_of stroker width in
        let v = Jstr.v (Drawing.Strokes.svg_path options scale path) in
        Brr.At.v (Jstr.v "d") v
      in
      let$* path = Lwd.get path in
      match elapsed_time with
      | None -> Lwd.pure @@ with_path path
      | Some elapsed_time ->
          let$ elapsed_time = elapsed_time in
          let path = List.filter (fun (_, t) -> t < elapsed_time) path in
          with_path path
    in
    let fill =
      let$ color =
        let$* erased = Lwd.get erased
        (* and$ elapsed_time = elapsed_time *)
        and$ color = Lwd.get color in
        match erased with
        | Some erased -> (
            match elapsed_time with
            | None -> Lwd.pure "transparent"
            | Some elapsed_time ->
                let$ elapsed_time = elapsed_time and$ at = Lwd.get erased.at in
                if elapsed_time > at then "transparent" else color
                (* let$ at = Lwd.get erased.at in *)
                (* if elapsed_time > at then "transparent" *)
                (* else *)
                (* Drawing.Color.to_string *)
                (* color *)
                (* "transparent" *))
        | None ->
            Lwd.pure
            @@
            (* Drawing.Color.to_string *)
            color
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
  (* let ev = move_handler stroke in *)
  let st =
    let scale = 1. /. scale in
    let scale = string_of_float scale in
    let ( !! ) = Jstr.v in
    let s = "scale3d(" ^ scale ^ "," ^ scale ^ "," ^ scale ^ ")" in
    [ `P (!!"transform", !!s) ]
  in
  Elwd.v ~ns:`SVG ~at (* ~ev *) ~st (Jstr.v "path") []

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

let count_member (strokes : strokes) =
  Lwd_table.map_reduce (fun _ _ -> 1) (0, ( + )) strokes

let drawing_area =
  let gs =
    let content =
      let$* status = Lwd.get Drawing_state.Live_coding.status in
      match status with
      | Drawing Presenting ->
          draw ~elapsed_time:None
            Drawing_state.Live_coding.workspaces.live_drawing
          (* let$* content = *)
          (*   let$ recording = State.Recording.current in *)
          (*   match recording with *)
          (*   | Some recording -> *)
          (*       let elapsed_time = Lwd.get State.time in *)
          (*       draw_until ~elapsed_time recording *)
          (*   | None -> Lwd.pure Lwd_seq.empty *)
          (* in *)
          (* From what I remember when I did this, the reason for an intermediate
         "g" is that with the current "Lwd.observe" implementation, taken from
         the brr-lwd example, only the attributes/children will be updated, not
               the element itself *)
      | Drawing (Recording { recording; _ }) ->
          draw ~elapsed_time:None recording.strokes
      | Editing { recording; current_time; _ } ->
          let elapsed_time = Some (Lwd.get current_time) in
          draw ~elapsed_time recording.strokes
    in
    Elwd.v ~ns:`SVG (Jstr.v "g") [ `S content ]
  in
  Elwd.v ~ns:`SVG (Jstr.v "svg")
    ~at:
      [
        `P
          (Brr.At.style
             (Jstr.v "overflow:visible; position: absolute; z-index:1001"));
      ]
    [ `R gs ]

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
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-content") |> Option.get
  in
  Brr.El.prepend_children content [ Lwd.quick_sample svg ];
  Lwd.set_on_invalidate svg on_invalidate;
  ()

let for_events () =
  let open Lwd_infix in
  let panel =
    let handler =
      let$* status =
        Lwd.get Drawing_state.Live_coding.status
        (* and$ current_tool = Lwd.get State.current_tool *)
      in
      let draw_mode d =
        let strokes, started_time =
          match d with
          | Presenting ->
              (Drawing_state.Live_coding.workspaces.live_drawing, Tools.now ())
          | Recording { recording = { strokes; _ }; started_at } ->
              (strokes, started_at)
        in
        let { tool; color; width } =
          Drawing_state.Live_coding.live_drawing_state
        in
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
      | Editing _ -> Lwd.pure Lwd_seq.empty
      (* match (recording, current_tool) with *)
      (* | None, _ -> Lwd_seq.empty *)
      (* | Some recording, Move -> *)
      (*     Lwd_seq.element @@ Editor_tools.Move.Preview.event recording *)
      (* | Some recording, Select -> *)
      (*     Lwd_seq.element @@ Editor_tools.Selection.Preview.event recording *)
      (* | Some recording, Scale -> *)
      (*     Lwd_seq.element @@ Editor_tools.Scale.Preview.event recording *)
    in
    (* let cursor = *)
    (*   let$ tool = Lwd.get State.current_tool in *)
    (*   match tool with *)
    (*   | Select -> (!!"cursor", !!"crosshair") *)
    (*   | Move -> (!!"cursor", !!"move") *)
    (*   | Scale -> (!!"cursor", !!"ne-resize") *)
    (* in *)
    (* TODO: what's below but with pointer-events *)
    (* let display = *)
    (*   match tool with *)
    (*   | None -> (!!"display", !!"none") *)
    (*   | Some _ -> (!!"display", !!"block") *)
    (* in *)
    (* let preview_box = Editor_tools.Selection.Preview.box in *)
    Elwd.div
      ~ev:[ `S handler ]
      ~at:[ `P (Brr.At.id !!"slipshow-drawing-editor-for-events") ]
      ~st:
        [
          (* `R cursor; *)
          (* `R display; *)
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
