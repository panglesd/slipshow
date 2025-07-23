(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr
open Brr_io
open Fut.Result_syntax

let with_log_group ?closed msg f =
  Console.group ?closed msg; f (); Console.group_end ()

let dump_track t =
  with_log_group ~closed:true Console.[str "Track:"; t] @@ fun () ->
  if Jv.has "getCapabilities" t (* FF is missing the fun. *)
  then Console.(log [str "Caps:"; Media.Track.get_capabilities t])
  else Console.(log [str "Caps: getCapabilities unsuppported"]);
  Console.(log [str "Constraints:"; Media.Track.get_constraints t]);
  Console.(log [str "Settings:"; Media.Track.get_settings t])

let dump_stream av =
  with_log_group Console.[str "Stream:"; av] @@ fun () ->
  List.iter dump_track (Media.Stream.get_tracks av)

let dump_devices ds =
  with_log_group Console.([str "Devices"]) @@ fun () ->
  List.iter (fun d -> Console.(log [d])) ds

let handle_error ~view = function
| Ok () ->  ()
| Error e ->
    let err = Jv.Error.message e in
    let ui_msg = match Jv.Error.enum e with
    | `Not_allowed_error -> Jstr.v "Can't do anything without your permission! "
    | `Not_found_error -> Jstr.v "Don't have a camera? "
    | _ -> Jstr.v "An error occured: "
    in
    let msg = El.p [El.txt (Jstr.append ui_msg err)] in
    El.append_children view [msg]

let button ?at onclick label =
  let but = El.button ?at [El.txt (Jstr.v label)] in
  ignore (Ev.listen Ev.click (fun _e -> onclick ()) (El.as_target but)); but

let fullscreen_button ~view video =
  let no_fullscreen = not (Document.fullscreen_available G.document) in
  let at = At.[if' no_fullscreen disabled] in
  let onclick () =
    ignore @@ Fut.map (handle_error ~view) (El.request_fullscreen video)
  in
  button ~at onclick "Watch fullscreen"

let stop_stream ~view s =
  List.iter Media.Track.stop (Media.Stream.get_tracks s);
  El.set_children view []

let play_stream ~view s =
  let at = [At.true' (Jstr.v "playsinline")] (* avoid default fs on mobile *) in
  let video = El.video ~at [El.txt' "No video stream."] in
  let m = Media.El.of_el video in
  let fullscreen = fullscreen_button ~view video in
  let stop = button (fun () -> stop_stream ~view s) "Stop" in
  let src = Some (Media.El.Provider.of_media_stream s) in
  let () = Media.El.set_src_object m src in
  let* () = Media.El.play m in
  El.set_children view [El.div [fullscreen; stop]; video];
  Fut.ok ()

let test_stream ~view kind stream () =
  let get_media = match kind with
  | `Camera -> Media.Devices.get_user_media
  | `Screen -> Media.Devices.get_display_media
  in
  ignore @@ Fut.map (handle_error ~view) @@
  let md = Media.Devices.of_navigator G.navigator in
  let* ds = Media.Devices.enumerate md in
  let () = dump_devices ds in
  let () = Option.iter (stop_stream ~view) !stream (* close previous one *) in
  let* s = get_media md (Media.Stream.Constraints.av ()) in
  let () = dump_stream s in
  (stream := Some s; play_stream ~view s)

let main () =
  let h1 = El.h1 [El.txt' "Media test"] in
  let info = El.txt' "Media information is dumped in the browser console."in
  let stream = ref None in
  let view = El.p [] in
  let cam = button (test_stream ~view `Camera stream) "Open camera" in
  let screen = button (test_stream ~view `Screen stream) "Share screen" in
  let children = [h1; El.p [info]; El.p [cam; screen]; view] in
  El.set_children (Document.body G.document) children

let () = main ()
