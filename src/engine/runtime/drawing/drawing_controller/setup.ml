open Lwd_infix
open Drawing_state
open Brr_lwd

let set_handler v value = Elwd.handler Brr.Ev.click (fun _ -> Lwd.set v value)
let ( !! ) = Jstr.v

open Brr

let init_ui global () =
  let ui = Lwd.observe (Panel.panel global) in
  let on_invalidate _ =
    let _ : int =
      Preview.request_animation_frame (Window.to_jv global.window) @@ fun _ ->
      let _ui = Lwd.quick_sample ui in
      (* Beware that due to this being ignored, a changed "root" element will
         not be updated by Lwd, only its reactive attributes/children *)
      ()
    in
    ()
  in
  let root = global.window |> Brr.Window.document |> Brr.Document.body in
  let body =
    Brr.El.find_first_by_selector ~root (Jstr.v "#slipshow-main") |> Option.get
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
  let init (global : Global_state.t) () =
    let visib =
      let$ status = Lwd.get Drawing_state.status in
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
        Preview.request_animation_frame (Window.to_jv global.window) @@ fun _ ->
        let _ui = Lwd.quick_sample svg in
        (* Beware that due to this being ignored, a changed "root" element will
         not be updated by Lwd, only its reactive attributes/children *)
        ()
      in
      ()
    in
    let root = global.window |> Brr.Window.document |> Brr.Document.body in
    let content =
      Brr.El.find_first_by_selector ~root (Jstr.v "#slipshow-main")
      |> Option.get
    in
    El.append_children content [ Lwd.quick_sample svg ];
    Lwd.set_on_invalidate svg on_invalidate;
    ()
end

module Garbage = struct
  (** Handle the slipshow-drawing-mode class added to the body depending on the
      mode. *)

  let g (global : Global_state.t) () =
    let open Lwd_infix in
    let panel =
      let$* status = Lwd.get Drawing_state.status in
      match status with
      | Drawing Presenting -> (
          let$ tool = Lwd.get Drawing_state.live_drawing_state.tool in
          match tool with Pointer -> `Presenting | _ -> `Drawing)
      | Drawing (Recording _) -> Lwd.pure `Drawing
      | Editing -> Lwd.pure `Editing
    in
    let ui = Lwd.observe panel in
    let on_invalidate _ =
      let _ : int =
        Preview.request_animation_frame (Window.to_jv global.window) @@ fun _ ->
        let is_drawing = Lwd.quick_sample ui in
        let body = global.window |> Window.document |> Document.body in
        ignore
        @@
        match is_drawing with
        | `Presenting ->
            El.set_class !!"slipshow-drawing-mode" false body;
            El.set_class !!"slipshow-editing-mode" false body
        | `Drawing ->
            El.set_class !!"slipshow-drawing-mode" true body;
            El.set_class !!"slipshow-editing-mode" false body
        | `Editing ->
            El.set_class !!"slipshow-drawing-mode" false body;
            El.set_class !!"slipshow-editing-mode" true body
      in
      ()
    in
    let _ = Lwd.quick_sample ui in
    Lwd.set_on_invalidate ui on_invalidate;
    ()
end

module Ui = struct
  let init global () =
    let svg = Ui.el global in
    let svg = Lwd.observe svg in
    let on_invalidate _ =
      let _ : int =
        Preview.request_animation_frame (Window.to_jv global.window) @@ fun _ ->
        let _ui = Lwd.quick_sample svg in
        (* Beware that due to this being ignored, a changed "root" element will
         not be updated by Lwd, only its reactive attributes/children *)
        ()
      in
      ()
    in
    let content =
      let root = global.window |> Brr.Window.document |> Brr.Document.body in
      Brr.El.find_first_by_selector ~root (Jstr.v "#slipshow-vertical-flex")
      |> Option.get
    in
    El.append_children content [ Lwd.quick_sample svg ];
    Lwd.set_on_invalidate svg on_invalidate;
    ()
end

let connect global () =
  let open Lwd_infix in
  let panel =
    let handler =
      let$* status = Lwd.get Drawing_state.status
      and$ current_tool = Lwd.get Drawing_state.editing_tool in
      match status with
      | Editing -> (
          let$ replaying_state = Lwd.get current_replaying_state in
          match current_tool with
          | Move ->
              Lwd_seq.element
              @@ Editing_tools.Move.Preview.event global replaying_state
          | Select ->
              Lwd_seq.element
              @@ Editing_tools.Selection.Preview.event global replaying_state
          | Rescale ->
              Lwd_seq.element
              @@ Editing_tools.Scale.Preview.event global replaying_state)
      | _ -> Lwd.pure Lwd_seq.empty
    in
    let cursor =
      let$ current_tool = Lwd.get Drawing_state.editing_tool in
      match current_tool with
      | Select -> (!!"cursor", !!"crosshair")
      | Move -> (!!"cursor", !!"move")
      | Rescale -> (!!"cursor", !!"ne-resize")
    in
    let display =
      let$ status = Lwd.get Drawing_state.status in
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
      Preview.request_animation_frame (Window.to_jv global.window) @@ fun _ ->
      let _ui = Lwd.quick_sample ui in
      (* Beware that due to this being ignored, a changed "root" element will
         not be updated by Lwd, only its reactive attributes/children *)
      ()
    in
    ()
  in
  let main =
    let root = global.window |> Brr.Window.document |> Brr.Document.body in
    Brr.El.find_first_by_selector ~root (Jstr.v "#slipshow-main") |> Option.get
  in
  El.append_children main [ Lwd.quick_sample ui ];
  Lwd.set_on_invalidate ui on_invalidate;
  ()

let init_ui (global : Global_state.t) () =
  Preview.init_drawing_area global ();
  connect global ();
  Preview.for_events global ();
  Rec_in_progress.init global ();
  init_ui global ();
  Garbage.g global ();
  Ui.init global ()
(* ; *)
(* Time.el *)
