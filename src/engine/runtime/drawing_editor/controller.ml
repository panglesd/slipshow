let total_time =
  let total_time =
    let open Lwd_infix in
    let$* recording = State.Recording.current in
    match recording with
    | None -> Lwd.return 0.
    | Some recording -> Lwd.get recording.total_time
  in
  let total_time = Lwd.observe total_time in
  fun () -> Lwd.quick_sample total_time

let handle ev =
  let key = ev |> Brr.Ev.as_type |> Brr.Ev.Keyboard.key |> Jstr.to_string in
  Brr.Console.(log [ "key:"; key ]);
  match key with
  | "ArrowLeft" ->
      let new_time = Float.max 0. (Lwd.peek State.time -. 100.) in
      Lwd.set State.time new_time;
      true
  | "ArrowRight" ->
      let new_time = Float.min (total_time ()) (Lwd.peek State.time +. 100.) in
      Lwd.set State.time new_time;
      true
  | "m" ->
      Lwd.set State.current_tool Move;
      true
  | "s" ->
      Lwd.set State.current_tool Select;
      true
  | " " ->
      if Lwd.peek State.is_playing then State.stop () else State.play ();
      true
  | _ -> false
