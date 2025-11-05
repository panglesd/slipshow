open Lwd_infix
open Drawing_state.Live_coding

let set_handler v value =
  Brr_lwd.Elwd.handler Brr.Ev.click (fun _ -> Lwd.set v value)

let ( !! ) = Jstr.v

module Live_drawing = struct
  let svg_button v (value : live_drawing_tool) svg =
    let at =
      let class_ =
        let$ current_tool = Lwd.get v in
        if current_tool = value then
          Lwd_seq.element (Brr.At.class' !!"slip-set-tool")
        else Lwd_seq.empty
      in
      [ `S class_ ]
    in
    let h = set_handler v value in
    let$ button = Brr_lwd.Elwd.div ~at ~ev:[ `P h ] [] in
    Brr.Console.(log [ "button"; button ]);
    let _ = Jv.set (Brr.El.to_jv button) "innerHTML" (Jv.of_string svg) in
    button

  let pen_button v =
    svg_button v (Stroker Pen)
      {|<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="20" height="20" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path class="clr-i-outline clr-i-outline-path-1" d="M33.87 8.32L28 2.42a2.07 2.07 0 0 0-2.92 0L4.27 23.2l-1.9 8.2a2.06 2.06 0 0 0 2 2.5a2.14 2.14 0 0 0 .43 0l8.29-1.9l20.78-20.76a2.07 2.07 0 0 0 0-2.92zM12.09 30.2l-7.77 1.63l1.77-7.62L21.66 8.7l6 6zM29 13.25l-6-6l3.48-3.46l5.9 6z" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>|}

  let highlighter_button v =
    svg_button v (Stroker Highlighter)
      {|<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="25" height="25" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path d="M15.82 26.06a1 1 0 0 1-.71-.29l-6.44-6.44a1 1 0 0 1-.29-.71a1 1 0 0 1 .29-.71L23 3.54a5.55 5.55 0 1 1 7.85 7.86L16.53 25.77a1 1 0 0 1-.71.29zm-5-7.44l5 5L29.48 10a3.54 3.54 0 0 0 0-5a3.63 3.63 0 0 0-5 0z" class="clr-i-outline clr-i-outline-path-1" fill="#000000"/><path d="M10.38 28.28a1 1 0 0 1-.71-.28l-3.22-3.23a1 1 0 0 1-.22-1.09l2.22-5.44a1 1 0 0 1 1.63-.33l6.45 6.44A1 1 0 0 1 16.2 26l-5.44 2.22a1.33 1.33 0 0 1-.38.06zm-2.05-4.46l2.29 2.28l3.43-1.4l-4.31-4.31z" class="clr-i-outline clr-i-outline-path-2" fill="#000000"/><path d="M8.94 30h-5a1 1 0 0 1-.84-1.55l3.22-4.94a1 1 0 0 1 1.55-.16l3.21 3.22a1 1 0 0 1 .06 1.35L9.7 29.64a1 1 0 0 1-.76.36zm-3.16-2h2.69l.53-.66l-1.7-1.7z" class="clr-i-outline clr-i-outline-path-3" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>|}

  let erase_button v =
    svg_button v Eraser
      {|<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="20" height="20" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path d="M35.62 12a2.82 2.82 0 0 0-.84-2l-7.29-7.35a2.9 2.9 0 0 0-4 0L2.83 23.28a2.84 2.84 0 0 0 0 4L7.53 32H3a1 1 0 0 0 0 2h25a1 1 0 0 0 0-2H16.74l18-18a2.82 2.82 0 0 0 .88-2zM13.91 32h-3.55l-6.11-6.11a.84.84 0 0 1 0-1.19l5.51-5.52l8.49 8.48zm19.46-19.46L19.66 26.25l-8.48-8.49l13.7-13.7a.86.86 0 0 1 1.19 0l7.3 7.29a.86.86 0 0 1 .25.6a.82.82 0 0 1-.25.59z" class="clr-i-outline clr-i-outline-path-1" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>|}

  let cursor_button v =
    svg_button v Pointer
      {|<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="20" height="20" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path class="clr-i-outline clr-i-outline-path-1" d="M14.58 32.31a1 1 0 0 1-.94-.65L4 5.65a1 1 0 0 1 1.25-1.28l26 9.68a1 1 0 0 1-.05 1.89l-8.36 2.57l8.3 8.3a1 1 0 0 1 0 1.41l-3.26 3.26a1 1 0 0 1-.71.29a1 1 0 0 1-.71-.29l-8.33-8.33l-2.6 8.45a1 1 0 0 1-.93.71zm3.09-12a1 1 0 0 1 .71.29l8.79 8.79L29 27.51l-8.76-8.76a1 1 0 0 1 .41-1.66l7.13-2.2L6.6 7l7.89 21.2l2.22-7.2a1 1 0 0 1 .71-.68z" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>|}

  let color_button var color =
    let at =
      let class_ =
        let$ current_color = Lwd.get var in
        if current_color = color then
          Lwd_seq.element (Brr.At.class' !!"slip-set-color")
        else Lwd_seq.empty
      in
      [ `S class_ ]
    in
    let ev = [ `P (set_handler var color) ] in
    Brr_lwd.Elwd.div ~at ~ev ~st:[ `P (!!"background-color", !!color) ] []

  let width_button var width c =
    let at =
      let class_ =
        let$ current_width = Lwd.get var in
        if current_width = width then
          Lwd_seq.element (Brr.At.class' !!"slip-set-width")
        else Lwd_seq.empty
      in
      [ `S class_; `P (Brr.At.class' !!c) ]
    in
    let ev = [ `P (set_handler var width) ] in
    Brr_lwd.Elwd.div ~at ~ev [ `P (Brr.El.div []) ]

  let make_panel (lds : live_drawing_state) workspace =
    let pen_button = pen_button lds.tool in
    let highlighter_button = highlighter_button lds.tool in
    let erase_button = erase_button lds.tool in
    let cursor_button = cursor_button lds.tool in
    let tool_buttons =
      Brr_lwd.Elwd.div
        [
          `R pen_button;
          `R highlighter_button;
          `R erase_button;
          `R cursor_button;
        ]
    in
    let color_buttons =
      let black_button = color_button lds.color "black" in
      let blue_button = color_button lds.color "blue" in
      let red_button = color_button lds.color "red" in
      let green_button = color_button lds.color "green" in
      let yellow_button = color_button lds.color "yellow" in
      Brr_lwd.Elwd.div
        [
          `R black_button;
          `R blue_button;
          `R red_button;
          `R green_button;
          `R yellow_button;
        ]
    in
    let width_buttons =
      let small_button = width_button lds.width 5. "slip-toolbar-small" in
      let medium_button = width_button lds.width 15. "slip-toolbar-medium" in
      let large_button = width_button lds.width 25. "slip-toolbar-large" in
      Brr_lwd.Elwd.div
        ~at:[ `P (Brr.At.class' !!"slip-toolbar-width") ]
        [ `R small_button; `R medium_button; `R large_button ]
    in
    let clear_button =
      let c =
        Brr_lwd.Elwd.handler Brr.Ev.click (fun _ -> Tools.Clear.event workspace)
      in
      Brr_lwd.Elwd.div
        ~at:[ `P (Brr.At.class' !!"slip-toolbar-control") ]
        [
          `R
            (Brr_lwd.Elwd.div
               ~at:[ `P (Brr.At.class' !!"slip-toolbar-clear") ]
               ~ev:[ `P c ]
               [ `P (Brr.El.txt !!"✗") ]);
        ]
    in
    Brr_lwd.Elwd.div
      ~at:[ `P (Brr.At.class' !!"slip-writing-toolbar") ]
      [ `R tool_buttons; `R color_buttons; `R width_buttons; `R clear_button ]
end

module Editing = struct
  let make_panel (es : editing_state) =
    let tool_buttons =
      let select_button =
        let ev = [ `P (set_handler es.tool Select) ] in
        Brr_lwd.Elwd.div ~ev [ `P (Brr.El.txt' "s") ]
      in
      let move_button =
        let ev = [ `P (set_handler es.tool Move) ] in
        Brr_lwd.Elwd.div ~ev [ `P (Brr.El.txt' "m") ]
      in
      let rescale_button =
        let ev = [ `P (set_handler es.tool Rescale) ] in
        Brr_lwd.Elwd.div ~ev [ `P (Brr.El.txt' "r") ]
      in
      Brr_lwd.Elwd.div [ `R select_button; `R move_button; `R rescale_button ]
    in
    Brr_lwd.Elwd.div [ `R tool_buttons ]
end

let panel =
  let s =
    let$ status = Lwd.get Drawing_state.Live_coding.status in
    match status with
    | Presenting ->
        Lwd_seq.element
        @@ Live_drawing.make_panel Drawing_state.Live_coding.live_drawing_state
             Drawing_state.Live_coding.workspaces.live_drawing
    | Recording _ -> Lwd_seq.empty
    | Editing _ -> Lwd_seq.empty (* Lwd_seq.element *)
    (* @@ Brr_lwd.Elwd.button *)
    (*      ~at:[ `P (Brr.At.class' !!"slip-writing-toolbar") ] *)
    (*      ~ev: *)
    (*        [ *)
    (*          `P *)
    (*            (set_handler Drawing_state.Live_coding.status *)
    (*               (Presenting *)
    (*                  { *)
    (*                    tool = Lwd.var (Stroker Pen); *)
    (*                    color = Lwd.var "blue"; *)
    (*                    width = Lwd.var 10.; *)
    (*                  })); *)
    (*        ] *)
    (*      [ `P (Brr.El.txt !!"yo") ] *)
  in
  let s = Lwd_seq.lift s in
  Brr_lwd.Elwd.div ~at:[ `P (Brr.At.id !!"slipshow-drawing-toolbar") ] [ `S s ]

open Brr

let init_ui () =
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

  let draw (strokes : strokes) =
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
        | Presenting ->
            let strokes = Drawing_state.Live_coding.workspaces.live_drawing in
            let$* n = count_member strokes in
            Brr.Console.(log [ "strokes has:"; n ]);
            draw (* ~elapsed_time *) strokes
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
        | Recording _ -> Lwd.pure Lwd_seq.empty
        | Editing _ -> Lwd.pure Lwd_seq.empty
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
        match status with
        | Presenting -> (
            let { tool; color; width } =
              Drawing_state.Live_coding.live_drawing_state
            in
            let$ tool = Lwd.get tool
            and$ color = Lwd.get color
            and$ width = Lwd.get width in
            match tool with
            | Stroker stroker ->
                Lwd_seq.element
                @@ Tools.Draw_stroke.event
                     Drawing_state.Live_coding.workspaces.live_drawing stroker
                     color width
            | Pointer -> Lwd_seq.empty
            | Eraser ->
                Lwd_seq.element
                @@ Tools.Erase.event
                     Drawing_state.Live_coding.workspaces.live_drawing)
        | Recording _ -> Lwd.pure Lwd_seq.empty
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

module Garbage = struct
  let g () =
    let open Lwd_infix in
    let panel =
      let$* status = Lwd.get Drawing_state.Live_coding.status in
      match status with
      | Presenting -> (
          let$ tool =
            Lwd.get Drawing_state.Live_coding.live_drawing_state.tool
          in
          match tool with Pointer -> false | _ -> true)
      | Recording _ -> Lwd.pure true
      | Editing _ -> Lwd.pure true
    in
    let ui = Lwd.observe panel in
    let on_invalidate _ =
      let _ : int =
        G.request_animation_frame @@ fun _ ->
        let is_drawing = Lwd.quick_sample ui in
        Brr.Console.(log [ "yooo!" ]);
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

let init_ui () =
  Preview.init_drawing_area ();
  Preview.for_events ();
  init_ui ();
  Garbage.g ()
