open Constants

open struct
  module Window = Brr.Window
  module G = Brr.G
  module El = Brr.El
  module Ev = Brr.Ev
  module Console = Brr.Console
end

type t = {
  scale_container : Brr.El.t;
  rotate_container : Brr.El.t;
  universe : Brr.El.t;
}

let translate_coords (x0, y0) =
  let { Coordinates.x; y; scale } = State.get_coord () in
  let x1 = (x0 /. scale) +. x in
  let y1 = (y0 /. scale) +. y in
  (x1, y1)

let pp { scale_container; rotate_container; universe } =
  Console.(
    log
      [
        ("scale_container", scale_container);
        ("rotate_container", rotate_container);
        ("universe", universe);
      ])

open Fut.Syntax

let setup el =
  let open Brr in
  let universe =
    El.div
      ~at:
        [
          At.class' (Jstr.v "slipshow-universe movable");
          At.id (Jstr.v "slipshow-universe");
        ]
      []
  in
  let scale_container =
    El.div ~at:[ At.class' (Jstr.v "slipshow-scale-container") ] [ universe ]
  in
  (* let _transitionEnd = *)
  (*   Brr.Ev.listen *)
  (*     (Brr.Ev.Type.create (Jstr.v "transitionstart")) *)
  (*     (fun _ -> *)
  (*       (\* Only do if scale has changed (or changed a lot) *\) *)
  (*       (\* "Blink" "contain" style from "" to "paint" to ""  *\) *)
  (*       let _ = *)
  (*         (\* let+ () = Fut.tick ~ms:600 in *\) *)
  (*         Brr.G.request_animation_frame (fun _ -> *)
  (*             Brr.El.set_inline_style (Jstr.v "contain") (Jstr.v "paint layout") *)
  (*               scale_container; *)
  (*             let _ = *)
  (*               (\* let+ () = Fut.tick ~ms:100 in *\) *)
  (*               Brr.G.request_animation_frame (fun _ -> *)
  (*                   Brr.El.set_inline_style (Jstr.v "contain") (Jstr.v "") *)
  (*                     scale_container) *)
  (*             in *)
  (*             Brr.Console.(log [ "YAAAAAAUUUUUUUUUUUU" ]); *)
  (*             ()) *)
  (*       in *)
  (*       ()) *)
  (*     (Brr.El.as_target scale_container) *)
  (* in *)
  let rotate_container =
    El.div
      ~at:[ At.class' (Jstr.v "slipshow-rotate-container") ]
      [ scale_container ]
  in
  Brr.El.insert_siblings `Replace el [ rotate_container ];
  Brr.El.append_children universe [ el ];
  let+ () =
    Browser.Css.set [ Width (width ()); Height (height ()) ] scale_container
  in
  { rotate_container; scale_container; universe }

let fast_move = ref false

let with_fast_moving f =
  fast_move := true;
  let+ () = f () in
  fast_move := false

let live_scale { scale_container; _ } =
  let compute_scale elem =
    let comp = El.computed_style (Jstr.v "transform") elem |> Jstr.to_string in
    let b = String.index_opt comp '(' in
    let e = String.index_opt comp ',' in
    match (b, e) with
    | Some b, Some e ->
        String.sub comp (b + 1) (e - b - 1)
        |> float_of_string_opt |> Option.value ~default:1.
    | _ -> 1.
  in
  compute_scale scale_container

let move_pure window ({ x; y; scale } as target : Coordinates.window) ~delay =
  let delay = if !fast_move then 0. else delay in
  let old_scale =
    let live_scale = live_scale window in
    let { Coordinates.scale = state_scale; _ } = State.get_coord () in
    let diff =
      Float.min live_scale state_scale /. Float.max live_scale state_scale
    in
    (* Live scale computes a less precise scale than state scale. If they are
       close together, may make sense to consider them "equal" and use the more
       precise one *)
    if diff < 0.95 then live_scale else state_scale
  in
  let transitions_style =
    if scale /. old_scale > 1.1 then `Zoom
    else if old_scale /. scale > 1.1 then `Unzoom
    else `Flat
  in
  let (scale_function, scale_delay), (universe_function, universe_delay) =
    let open Browser.Css in
    match transitions_style with
    | `Zoom ->
        ( (TransitionTiming "ease-in", TransitionDelay (0.5 *. delay)),
          (TransitionTiming "ease-out", TransitionDelay 0.) )
    | `Unzoom ->
        ( (TransitionTiming "ease-out", TransitionDelay 0.),
          (TransitionTiming "ease-in", TransitionDelay (0.5 *. delay)) )
    | `Flat ->
        ( (TransitionTiming "", TransitionDelay 0.),
          (TransitionTiming "", TransitionDelay 0.) )
  in
  State.set_coord target;
  let x = -.x +. (width () /. 2.) in
  let y = -.y +. (height () /. 2.) in
  let+ () = Browser.Css.set [ TransitionDuration delay ] window.scale_container
  and+ () = Browser.Css.set [ scale_function ] window.scale_container
  and+ () = Browser.Css.set [ scale_delay ] window.scale_container
  and+ () = Browser.Css.set [ TransitionDuration delay ] window.rotate_container
  and+ () = Browser.Css.set [ TransitionDuration delay ] window.universe
  and+ () = Browser.Css.set [ universe_function ] window.universe
  and+ () = Browser.Css.set [ universe_delay ] window.universe
  and+ () = Browser.Css.set [ Translate { x; y } ] window.universe
  and+ () = Browser.Css.set [ Scale scale ] window.scale_container in
  ()

let bound_x { universe; _ } = Brr.El.bound_x universe
let bound_y { universe; _ } = Brr.El.bound_y universe
