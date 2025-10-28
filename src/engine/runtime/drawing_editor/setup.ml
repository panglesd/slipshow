open Brr

let ( !! ) = Jstr.v

(* init function inspired from brr-lwd examples. There seem to be a limitation
   in handling reactive top level element, see comment below. *)

let connect () =
  let open Lwd_infix in
  let panel =
    let handler =
      let$ recording = State.Recording.current
      and$ current_tool = Lwd.get State.current_tool in
      match (recording, current_tool) with
      | None, _ -> Lwd_seq.empty
      | Some recording, Move ->
          Lwd_seq.element @@ Editor_tools.Move.drawing_event recording
      | Some recording, Select ->
          Lwd_seq.element @@ Editor_tools.Selection.drawing_event recording
    in
    let cursor =
      let$ tool = Lwd.get State.current_tool in
      match tool with
      | Select -> (!!"cursor", !!"pointer")
      | Move -> (!!"cursor", !!"move")
    in
    let display =
      let$ tool = State.Recording.current in
      match tool with
      | None -> (!!"display", !!"none")
      | Some _ -> (!!"display", !!"block")
    in
    let preview_box = Editor_tools.Selection.preview_box in
    Brr_lwd.Elwd.div
      ~ev:[ `S handler ]
      ~at:[ `P (Brr.At.id !!"slipshow-drawing-editor-for-events") ]
      ~st:
        [
          `R cursor;
          `R display;
          `P (!!"position", !!"absolute");
          `P (!!"top", !!"0");
          `P (!!"left", !!"0");
          `P (!!"right", !!"0");
          `P (!!"bottom", !!"0");
        ]
      [ `S preview_box ]
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

let init_ui () =
  let ui = Ui.el in
  let ui = Lwd.observe ui in
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
  let vertical =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-vertical-flex")
    |> Option.get
  in
  El.append_children vertical [ Lwd.quick_sample ui ];
  Lwd.set_on_invalidate ui on_invalidate;
  ()

let init_svg () =
  let svg = Preview.el in
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
  (* let on_load _ = *)
  (*   Console.(log [ str "onload" ]); *)
  (* in *)
  (* ignore (Ev.listen Ev.dom_content_loaded on_load (Window.as_target G.window)); *)
  ()

let init () =
  init_svg ();
  init_ui ();
  connect ()
