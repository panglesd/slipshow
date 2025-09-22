open Brr

(*         <svg id="slipshow-drawing-elem" style="overflow:visible; position: absolute; z-index:1000"></svg>
 *)

let init_ui () =
  Console.(log [ "Setting up lwd" ]);
  let ui = State.Recording.el in
  let ui = Lwd.observe ui in
  let on_invalidate _ =
    let _ : int =
      G.request_animation_frame @@ fun _ ->
      let _ui = Lwd.quick_sample ui in
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
  (* let on_load _ = *)
  (*   Console.(log [ str "onload" ]); *)
  (* in *)
  (* ignore (Ev.listen Ev.dom_content_loaded on_load (Window.as_target G.window)); *)
  ()

let init_svg () =
  let svg = State.Svg.el in
  let svg = Lwd.observe svg in
  let on_invalidate _ =
    let _ : int =
      G.request_animation_frame @@ fun _ ->
      let _ui = Lwd.quick_sample svg in
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
  init_ui ()
