open Lwd_infix
open Brr
open Brr_lwd

let float ?(callback = fun _ -> ()) ?(ev = []) ?st ?(prop = []) ?type'
    ?(kind = `Change) var attrs =
  let h =
   fun ev ->
    let el = ev |> Ev.target |> Ev.target_to_jv in
    let new_value = Jv.get el "value" |> Jv.to_string |> float_of_string in
    callback new_value;
    if Ev.is_trusted ev then Lwd.set var new_value;
    let () =
      let el = ev |> Ev.target |> Ev.target_to_jv |> El.of_jv in
      (* We unfocus so that shortcuts work *)
      El.set_has_focus false el
    in
    ()
  in
  let set =
    match kind with
    | `Change -> Elwd.handler Ev.change h
    | `Input -> Elwd.handler Ev.input h
  in
  let ev = `P set :: ev in
  let at =
    let type' =
      match type' with None -> [] | Some t -> [ `P (At.type' (Jstr.v t)) ]
    in
    type' @ attrs
  in
  let prop =
    let v =
      let$ f = Lwd.get var in
      let i = Float.to_int f in
      (Jstr.v "value", Jv.of_int i)
    in
    `R v :: prop
  in
  Elwd.input ?st ~at ~ev ~prop ()

let string ?(callback = fun _ -> ()) ?(ev = []) ?st ?(prop = []) ?type'
    ?(kind = `Change) var attrs =
  let ev =
    let set =
      let h =
       fun ev ->
        let el = ev |> Ev.target |> Ev.target_to_jv in
        let new_value = Jv.get el "value" |> Jv.to_string in
        callback new_value;
        Lwd.set var new_value
      in
      match kind with
      | `Change -> Elwd.handler Ev.change h
      | `Input -> Elwd.handler Ev.input h
    in
    `P set :: ev
  in
  let at =
    let type' =
      match type' with None -> [] | Some t -> [ `P (At.type' (Jstr.v t)) ]
    in
    type' @ attrs
  in
  let prop =
    let v =
      let$ v = Lwd.get var in
      (Jstr.v "value", Jv.of_string v)
    in
    `R v :: prop
  in
  Elwd.input ?st ~at ~ev ~prop ()

let hover ?(var = Lwd.var false) () =
  let handler1 = Elwd.handler Ev.mouseenter (fun _ -> Lwd.set var true) in
  let handler2 = Elwd.handler Ev.mouseleave (fun _ -> Lwd.set var false) in
  (Lwd.get var, Lwd_seq.of_list [ handler1; handler2 ])

let is_pressed ev =
  let is_pressed = ( != ) 0 in
  is_pressed (ev |> Ev.as_type |> Ev.Pointer.as_mouse |> Ev.Mouse.buttons)

(** - [start] takes as input the original coordinates of the click, as well as
      the raw event. It returns an accumulator.
    - [drag] takes as input the original coordinates of the start of the drag,
      the difference with the current position of the mouse, the last
      accumulator and the raw event. Must return an accumulator.
    - [end_] takes as input the last accumulator and the raw event, and should
      return unit. *)
let mouse_drag start drag end_ =
  let mouse_move x y acc =
   fun ev ->
    let mouse_ev = Ev.as_type ev |> Ev.Pointer.as_mouse in
    let x' = Ev.Mouse.page_x mouse_ev in
    let y' = Ev.Mouse.page_y mouse_ev in
    drag ~x ~y ~dx:(x' -. x) ~dy:(y' -. y) acc ev
  in
  Elwd.handler Ev.pointerdown (fun ev ->
      Ev.prevent_default ev;
      let mouse_ev = Ev.as_type ev |> Ev.Pointer.as_mouse in
      let x = Ev.Mouse.page_x mouse_ev in
      let y = Ev.Mouse.page_y mouse_ev in
      let acc = start x y ev in
      let acc = ref acc in
      let mousemove_listener = ref None in
      let mouseup_listener = ref None in
      let unlisten () =
        Option.iter Ev.unlisten !mousemove_listener;
        Option.iter Ev.unlisten !mouseup_listener;
        end_ !acc ev
      in
      let id =
        Ev.listen Ev.pointermove
          (fun ev ->
            if is_pressed ev then acc := mouse_move x y !acc ev else unlisten ())
          (Document.body G.document |> El.as_target)
      in
      mousemove_listener := Some id;
      let opts = Ev.listen_opts ~once:true () in
      let id =
        Ev.listen ~opts Ev.pointerup
          (fun _ev -> unlisten ())
          (Document.body G.document |> El.as_target)
      in
      mouseup_listener := Some id;
      ())
