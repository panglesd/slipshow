open Brr

let init () =
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
  El.append_children (Document.body G.document) [ Lwd.quick_sample ui ];
  Lwd.set_on_invalidate ui on_invalidate;
  (* let on_load _ = *)
  (*   Console.(log [ str "onload" ]); *)
  (* in *)
  (* ignore (Ev.listen Ev.dom_content_loaded on_load (Window.as_target G.window)); *)
  ()
