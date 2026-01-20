let setup ~speaker_view:child ~video_el:mirror_video ~mirror_button
    ~clone_button ~child_iframe ~src =
  let _unlisten =
    Brr.Ev.listen Brr.Ev.click
      (fun _ ->
        let open Fut.Syntax in
        let _ : unit Fut.t =
          let ( !! ) = Jstr.v in
          Brr.El.set_class !!"clone-mode" false
            (Brr.Document.body (Brr.Window.document child));
          Brr.El.set_class !!"mirror-mode" true
            (Brr.Document.body (Brr.Window.document child));
          let child_navigator =
            Jv.get (Brr.Window.to_jv child) "navigator" |> Brr.Navigator.of_jv
          in
          let devices = Brr_io.Media.Devices.of_navigator child_navigator in
          let constraints = Brr_io.Media.Stream.Constraints.av () in
          let+ media =
            Brr_io.Media.Devices.get_display_media devices constraints
          in
          match media with
          | Ok stream ->
              let provider = Brr_io.Media.El.Provider.of_media_stream stream in
              Brr_io.Media.El.set_src_object mirror_video (Some provider);
              Brr.El.set_at (Jstr.v "srcdoc") None child_iframe
          | Error e -> Brr.Console.(error [ e ])
        in
        ())
      (Brr.El.as_target mirror_button)
  in
  let _unlisten =
    Brr.Ev.listen Brr.Ev.click
      (fun _ ->
        let ( !! ) = Jstr.v in
        Brr.El.set_at (Jstr.v "srcdoc") (Some src) child_iframe;
        Brr.El.set_class !!"clone-mode" true
          (Brr.Document.body (Brr.Window.document child));
        Brr.El.set_class !!"mirror-mode" false
          (Brr.Document.body (Brr.Window.document child));
        let tracks =
          let stream = Brr_io.Media.El.capture_stream mirror_video in
          Brr_io.Media.Stream.get_tracks stream
        in
        List.iter (fun t -> Brr_io.Media.Track.stop t) tracks;
        Brr_io.Media.El.set_src_object mirror_video None)
      (Brr.El.as_target clone_button)
  in
  ()
