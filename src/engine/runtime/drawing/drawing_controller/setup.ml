open Lwd_infix
open Drawing_state.Live_coding
open Brr_lwd

let set_handler v value = Elwd.handler Brr.Ev.click (fun _ -> Lwd.set v value)
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

module Rec_in_progress = struct
  let init () =
    let visib =
      let$ status = Lwd.get Drawing_state.Live_coding.status in
      match status with
      | Drawing (Recording _) -> (Brr.El.Style.display, !!"block")
      | _ -> (Brr.El.Style.display, !!"none")
    in
    let svg =
      Elwd.div
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
            (Elwd.div
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
      | Editing -> Lwd.pure true
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

let connect () =
  let open Lwd_infix in
  let panel =
    let handler =
      let$* status = Lwd.get Drawing_state.Live_coding.status
      and$ current_tool = Lwd.get Drawing_state.Live_coding.editing_tool in
      match status with
      | Editing -> (
          let$ editing_state = Lwd.get current_editing_state in
          let recording = editing_state.replaying_state.recording in
          match current_tool with
          | Move ->
              Lwd_seq.element @@ Editing_tools.Move.Preview.event recording
          | Select ->
              Lwd_seq.element @@ Editing_tools.Selection.Preview.event recording
          | Rescale ->
              Lwd_seq.element @@ Editing_tools.Scale.Preview.event recording)
      | _ -> Lwd.pure Lwd_seq.empty
    in
    let cursor =
      let$ current_tool = Lwd.get Drawing_state.Live_coding.editing_tool in
      match current_tool with
      | Select -> (!!"cursor", !!"crosshair")
      | Move -> (!!"cursor", !!"move")
      | Rescale -> (!!"cursor", !!"ne-resize")
    in
    let display =
      let$ status = Lwd.get Drawing_state.Live_coding.status in
      match status with
      | Editing -> (!!"display", !!"block")
      | _ -> (!!"display", !!"none")
    in
    let preview_box = Editing_tools.Selection.Preview.box in
    Elwd.div
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
  Preview.init_drawing_area ();
  Preview.for_events ();
  Rec_in_progress.init ();
  init_ui ();
  Garbage.g ();
  Ui.init ();
  connect ()
(* ; *)
(* Time.el *)
