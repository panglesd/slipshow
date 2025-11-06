open Lwd_infix
open Drawing_state.Live_coding

let set_handler v value =
  Brr_lwd.Elwd.handler Brr.Ev.click (fun _ -> Lwd.set v value)

let ( !! ) = Jstr.v

open Brr

let init_ui () =
  let ui = Lwd.observe Panel.panel in
  let on_invalidate _ =
    let _ : int =
      G.request_animation_frame @@ fun _ ->
      let _ui = Lwd.quick_sample ui in
      (* Beware that due to this being ignored, a changed "root" element will
         not be updated by Lwd, only its reactive attributes/children *)
      ()
    in
    ()
  in
  let body =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
  in
  El.append_children body [ Lwd.quick_sample ui ];
  Lwd.set_on_invalidate ui on_invalidate;
  ()

(* let _ = *)
(*   let el = *)
(*     Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get *)
(*   in *)
(*   let content = "" in *)
(*   (ignore content, ignore el) *)

module Preview = struct
  let options_of _stroker width =
    let size = width in
    Perfect_freehand.Options.v ~thinning:0.5 ~smoothing:0.5 ~size
      ~streamline:0.5 ~last:false ()

  let create_elem_of_stroke (* ~elapsed_time *)
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
        let$ path = Lwd.get path in
        (* if should_continue then *)
        (*   let$ elapsed_time = elapsed_time in *)
        (*   let path = List.filter (fun (_, t) -> t < elapsed_time) path in *)
        (*   with_path path *)
        (* else Lwd.pure @@  *)
        with_path path
      in
      let fill =
        let$ color = Lwd.get color
        and$ erased =
          Lwd.get erased
          (* and$ elapsed_time = elapsed_time *)
        in
        let color =
          match erased with
          | Some _erased ->
              (* let$ at = Lwd.get erased.at in *)
              (* if elapsed_time > at then "transparent" *)
              (* else *)
              (* Drawing.Color.to_string *)
              (* color *)
              "transparent"
          | None ->
              (* Lwd.pure *)
              (* @@ *)
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
        let$ selected = Lwd.get selected
        and$ preselected = Lwd.get preselected in
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
    Brr_lwd.Elwd.v ~ns:`SVG ~at (* ~ev *) ~st (Jstr.v "path") []

  let draw strokes =
    Lwd_table.map_reduce
      (fun _ stro ->
        let res =
          let$ elem = create_elem_of_stroke (* ~elapsed_time *) stro
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
            draw
              (* ~elapsed_time *)
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
        | Drawing (Recording { recording; _ }) -> draw recording.strokes
        | Editing { recording; _ } -> draw (* ~elapsed_time *) recording.strokes
      in
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

  let init_drawing_area () =
    let svg = drawing_area in
    let svg = Lwd.observe svg in
    let on_invalidate _ =
      let _ : int =
        G.request_animation_frame @@ fun _ ->
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
    El.prepend_children content [ Lwd.quick_sample svg ];
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
              @@ Tools.Draw_stroke.event ~started_time strokes stroker color
                   width
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
      Brr_lwd.Elwd.div
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
        G.request_animation_frame @@ fun _ ->
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
    El.append_children main [ Lwd.quick_sample ui ];
    Lwd.set_on_invalidate ui on_invalidate;
    ()
end

module Rec_in_progress = struct
  let init () =
    let visib =
      let$ status = Lwd.get Drawing_state.Live_coding.status in
      match status with
      | Drawing (Recording _) -> (Brr.El.Style.display, !!"block")
      | _ -> (Brr.El.Style.display, !!"none")
    in
    let svg =
      Brr_lwd.Elwd.div
        ~st:
          [
            `R visib;
            `P (!!"position", !!"absolute");
            `P (!!"right", !!"0");
            `P (!!"font-size", !!"2em");
            `P (!!"background", !!"rgba(255, 255, 255, 0.5)");
            `P (!!"padding", !!"10px");
            `P (!!"border-radius", !!"12px");
          ]
        [
          `R
            (Brr_lwd.Elwd.div
               ~at:[ `P (Brr.At.class' !!"slipshow-blink") ]
               ~st:
                 [
                   `P (!!"display", !!"inline-block");
                   `P (!!"width", !!"40px");
                   `P (!!"margin-right", !!"10px");
                   `P (!!"height", !!"40px");
                   `P (!!"background", !!"red");
                   `P (!!"border-radius", !!"23px");
                 ]
               []);
          `P (Brr.El.txt' "REC");
        ]
    in
    let svg = Lwd.observe svg in
    let on_invalidate _ =
      let _ : int =
        G.request_animation_frame @@ fun _ ->
        let _ui = Lwd.quick_sample svg in
        (* Beware that due to this being ignored, a changed "root" element will
         not be updated by Lwd, only its reactive attributes/children *)
        ()
      in
      ()
    in
    let content =
      Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
    in
    El.append_children content [ Lwd.quick_sample svg ];
    Lwd.set_on_invalidate svg on_invalidate;
    ()
end

module Garbage = struct
  (** Handle the slipshow-drawing-mode class added to the body depending on the
      mode. *)

  let g () =
    let open Lwd_infix in
    let panel =
      let$* status = Lwd.get Drawing_state.Live_coding.status in
      match status with
      | Drawing Presenting -> (
          let$ tool =
            Lwd.get Drawing_state.Live_coding.live_drawing_state.tool
          in
          match tool with Pointer -> false | _ -> true)
      | Drawing (Recording _) -> Lwd.pure true
      | Editing _ -> Lwd.pure true
    in
    let ui = Lwd.observe panel in
    let on_invalidate _ =
      let _ : int =
        G.request_animation_frame @@ fun _ ->
        let is_drawing = Lwd.quick_sample ui in
        ignore
        @@ Brr.El.set_class !!"slipshow-drawing-mode" is_drawing
             (Brr.Document.body Brr.G.document)
      in
      ()
    in
    let _ = Lwd.quick_sample ui in
    Lwd.set_on_invalidate ui on_invalidate;
    ()
end

module Ui = struct
  let init () =
    let svg = Ui.el in
    let svg = Lwd.observe svg in
    let on_invalidate _ =
      let _ : int =
        G.request_animation_frame @@ fun _ ->
        let _ui = Lwd.quick_sample svg in
        (* Beware that due to this being ignored, a changed "root" element will
         not be updated by Lwd, only its reactive attributes/children *)
        ()
      in
      ()
    in
    let content =
      Brr.El.find_first_by_selector (Jstr.v "#slipshow-vertical-flex")
      |> Option.get
    in
    El.append_children content [ Lwd.quick_sample svg ];
    Lwd.set_on_invalidate svg on_invalidate;
    ()
end

let init_ui () =
  Preview.init_drawing_area ();
  Preview.for_events ();
  Rec_in_progress.init ();
  init_ui ();
  Garbage.g ();
  Ui.init ()
(* ; *)
(* Time.el *)
