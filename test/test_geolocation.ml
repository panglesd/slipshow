(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr
open Brr_io
open Fut.Result_syntax

let handle_error ~view = function
| Ok () ->  ()
| Error e ->
    let err = Geolocation.Error.message e in
    let msg = El.p [El.txt Jstr.(v "An error occured: " + err)] in
    El.set_children view [msg]

let button ?at onclick label =
  let but = El.button ?at [El.txt (Jstr.v label)] in
  ignore (Ev.listen Ev.click (fun _e -> onclick but) (El.as_target but)); but

let log_pos pos view =
  let label n = El.em El.[txt Jstr.(v n + v ":")] in
  let mag ?frac value unit = Jstr.(of_float ?frac value + v unit) in
  let mag_option ?frac value unit = match value with
  | None -> Jstr.v "n/a" | Some value -> mag ?frac value unit
  in
  let geopos =
    let frac = 5 (* meter precision *) in
    let lat = Jstr.of_float ~frac @@ Geolocation.Pos.latitude pos in
    let lon = Jstr.of_float ~frac @@ Geolocation.Pos.longitude pos in
    let coords = El.txt Jstr.(lat + v ", " + lon) in
    let acc = Geolocation.Pos.accuracy pos in
    let osm = Jstr.v "https://www.openstreetmap.org" in
    let href = Jstr.(osm + v "/#map=15/" + lat + v "/" + lon) in
    let link = El.a ~at:[At.href href] [coords] in
    El.li [label "Coordinates"; El.sp (); link; El.nbsp (); El.nbsp ();
           label "accuracy"; El.sp (); El.txt (mag acc "m"); ]
  in
  let altitude =
    let alt = Geolocation.Pos.altitude pos in
    let alt = El.txt (mag_option alt "m") in
    let acc = Geolocation.Pos.altitude_accuracy pos in
    El.li [label "Altitude"; El.sp (); alt; El.nbsp (); El.nbsp ();
           label "accuracy"; El.sp (); El.txt (mag_option acc "m") ]
  in
  let heading_speed =
    let heading = Geolocation.Pos.heading pos in
    let heading = El.txt (mag_option heading "°") in
    let speed = Geolocation.Pos.speed pos in
    El.li [ label "Heading"; El.sp (); heading; El.nbsp (); El.nbsp ();
            label "speed"; El.sp (); El.txt (mag_option speed "m/s") ]
  in
  let timestamp =
    let ts = Geolocation.Pos.timestamp_ms pos in
    El.li [label "Timestamp"; El.sp (); El.txt (mag ts "ms") ]
  in
  let fields = [ geopos; altitude; timestamp; heading_speed; timestamp ] in
  El.set_children view [El.ul fields]

let det_label = "Determining position…"
let watch_label = "Watch position"

let show_pos ~opts view but =
  ignore @@ Fut.map (handle_error ~view) @@
  let () = El.set_children view [El.p [El.txt' det_label]] in
  let* pos = Geolocation.get ~opts (Geolocation.of_navigator G.navigator) in
  log_pos pos view;
  Fut.ok ()

let toggle_watch_pos ~opts view =
  let wid = ref None in
  let geoloc = Geolocation.of_navigator G.navigator in
  fun but -> match !wid with
  | None ->
      let log = function
      | Ok pos -> log_pos pos view
      | Error _ as e -> handle_error ~view e
      in
      wid := Some (Geolocation.watch ~opts geoloc log);
      El.set_children view [El.p [El.txt' det_label]];
      El.set_children but [El.txt' "Stop watching"]
  | Some id ->
      wid := None;
      Geolocation.unwatch geoloc id;
      El.set_children but [El.txt' watch_label]

let main () =
  let h1 = El.h1 [El.txt' "Geolocation test"] in
  let view = El.p [] in
  let opts = Geolocation.opts ~high_accuracy:true () in
  let show = button (show_pos ~opts view) "Show position" in
  let watch = button (toggle_watch_pos ~opts view) watch_label in
  let children = [h1; El.p [show; watch]; view] in
  El.set_children (Document.body G.document) children

let () = main ()
