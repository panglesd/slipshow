(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr
open Fut.Result_syntax
open Brr_canvas
open Brr_io
open Brr_webaudio

(* Button *)

let toggle ?at onclick ~off:off_label ~on:on_label =
  let on = ref false in
  let but = El.button ?at [El.txt' off_label] in
  let onclick _e =
    onclick !on;
    on := not !on;
    El.set_children but [El.txt' (if !on then on_label else off_label)];
  in
  ignore (Ev.listen Ev.click onclick (El.as_target but)); but

(* Audio viz. *)

let set_canvas_size cnv ~r =
  let el = Canvas.to_el cnv in
  let w = El.inner_w el in
  let h = Jstr.(of_int (truncate (w *. r)) + v "px") in
  El.set_inline_style El.Style.height h el;
  Canvas.set_size_to_layout_size cnv

let clear_canvas c ~w ~h =
  C2d.set_fill_style c (C2d.color (Jstr.v "#EEE"));
  C2d.fill_rect c ~x:0. ~y:0. ~w ~h

let wave_data c ~x ~y ~w ~h data =
  C2d.set_stroke_style c (C2d.color (Jstr.v "#000"));
  C2d.set_line_width c (1. *. Window.device_pixel_ratio G.window);
  let p = C2d.Path.create () in
  let slice_width = w /. float (Tarray.length data) in
  let x = ref x in
  let ba = Tarray.to_bigarray1 data in
  for i = 0 to Bigarray.Array1.dim ba - 1 do
    let v = float (Bigarray.Array1.get ba i) /. 128. in
    let y = y +. v *. (h /. 2.) in
    if i = 0 then C2d.Path.move_to p ~x:!x ~y else
    C2d.Path.line_to p ~x:!x ~y;
    x := !x +. slice_width;
  done;
  C2d.stroke c p

let freq_data c ~x ~y ~w ~h data =
  C2d.set_fill_style c (C2d.color (Jstr.v "#000"));
  let bw = (w /. float (Tarray.length data)) *. 5. in
  let x = ref x in
  let ba = Tarray.to_bigarray1 data in
  for i = 0 to Bigarray.Array1.dim ba - 1 do
    let bh = float (Bigarray.Array1.get ba i) /. 2. in
    C2d.fill_rect c ~x:!x ~y:(y +. h -. 0.5 *. bh) ~w:bw ~h:bh;
    x := !x +. bw +. (1. *. Window.device_pixel_ratio G.window);
  done

let draw_sound_data cnv wave freq =
  let c = C2d.get_context cnv in
  let w = float @@ Canvas.w cnv in
  let h = float @@ Canvas.h cnv in
  let hh = 0.5 *. h in
  clear_canvas c ~w ~h;
  wave_data c ~x:0. ~y:0. ~w ~h:hh wave;
  freq_data c ~x:0. ~y:hh ~w ~h:hh freq;
  ()

let draw_data cnv get_data =
  let rec draw _ =
    let wave, freq = get_data () in
    draw_sound_data cnv wave freq;
    ignore (G.request_animation_frame draw)
  in
  draw 0.

let analyser c =
  let a = Audio.Node.Analyser.create c in
  let len = Audio.Node.Analyser.frequency_bin_count a in
  let w = Tarray.create Tarray.Uint8 len in
  let f = Tarray.create Tarray.Uint8 len in
  let get_data () =
    Audio.Node.Analyser.get_byte_time_domain_data a w;
    Audio.Node.Analyser.get_byte_frequency_data a f;
    w, f
  in
  a, get_data

(* Audio *)

let ctx_and_dst = ref None
let setup_audio_dst cnv =
  let c = Audio.Context.as_base (Audio.Context.create ()) in
  let analyser, get_data = analyser c in
  let analyser = Audio.Node.Analyser.as_node analyser in
  let out = Audio.Context.Base.destination c in
  Audio.Node.(connect_node analyser ~dst:(Destination.as_node out));
  draw_data cnv get_data;
  ctx_and_dst := Some (c, analyser)

(* Oscillator source *)

let buzz = ref None
let buzz_node c =
  let type' = Audio.Node.Oscillator.Type.sine in
  let opts = Audio.Node.Oscillator.opts ~type' ~frequency:440. () in
  Audio.Node.Oscillator.create c ~opts

let rec start_buzz cnv = match !ctx_and_dst with
| None -> setup_audio_dst cnv; start_buzz cnv
| Some (c, dst) ->
    match !buzz with
    | Some b -> ()
    | None ->
        let b = buzz_node c in
        Audio.Node.Oscillator.start b;
        Audio.Node.(connect_node (Oscillator.as_node b) ~dst);
        buzz := Some b

let stop_buzz () = match !buzz with
| None -> ()
| Some b ->
    Audio.Node.Oscillator.stop b;
    Audio.Node.(disconnect (Oscillator.as_node b));
    buzz := None

let toggle_buzz cnv on = if on then stop_buzz () else start_buzz cnv

(* Microphone source *)

let mic = ref None
let mic_node c =
  let md = Media.Devices.of_navigator G.navigator in
  let audio = Media.Stream.Constraints.v ~audio:(`Yes None) () in
  Fut.bind (Media.Devices.get_user_media md audio) @@ function
  | Error _ as e -> Fut.return e
  | Ok stream ->
      let opts = Audio.Node.Media_stream_source.opts ~stream () in
      Fut.ok (Audio.Node.Media_stream_source.create c ~opts)

let rec start_mic cnv = match !ctx_and_dst with
| None -> setup_audio_dst cnv; start_mic cnv
| Some (c, dst) ->
    match !mic with
    | Some m -> Audio.Node.(connect_node (Media_stream_source.as_node m) ~dst)
    | None -> (* racy *)
        Fut.await (mic_node c) @@ function
        | Error _ as e -> Console.log_if_error e ~use:()
        | Ok n -> mic := (Some n); start_mic cnv

let stop_mic () = match !mic with
| None -> ()
| Some m -> Audio.Node.disconnect (Audio.Node.Media_stream_source.as_node m)

let toggle_mic cnv on = if on then stop_mic () else start_mic cnv

(* Main *)

let main () =
  let h1 = El.h1 [El.txt' "Web audio test"] in
  let cnv = Canvas.create [] in
  let view = El.p [Canvas.to_el cnv ] in
  let buzz = toggle (toggle_buzz cnv) ~off:"Pitch my 440" ~on:"Stop it!" in
  let mic = toggle (toggle_mic cnv) ~off:"Mic!" ~on:"Drop mic!" in
  let children = [h1; El.p [buzz; mic]; view] in
  El.set_children (Document.body G.document) children;
  let* _ev = Fut.map Result.ok (Ev.next Ev.load (Window.as_target G.window)) in
  set_canvas_size cnv ~r:0.25;
  Fut.ok ()

let () = ignore (main ())
