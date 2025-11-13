open Lwd_infix

let float ?(callback = fun _ -> ()) ?(ev = []) ?st ?(prop = []) ?type'
    ?(kind = `Change) var attrs =
  let h =
   fun ev ->
    let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
    let new_value = Jv.get el "value" |> Jv.to_string |> float_of_string in
    callback new_value;
    Lwd.set var new_value
  in
  let set =
    match kind with
    | `Change -> Brr_lwd.Elwd.handler Brr.Ev.change h
    | `Input -> Brr_lwd.Elwd.handler Brr.Ev.input h
  in
  let ev = `P set :: ev in
  let at =
    let type' =
      match type' with None -> [] | Some t -> [ `P (Brr.At.type' (Jstr.v t)) ]
    in
    type' @ attrs
  in
  let prop =
    let v =
      let$ v = Lwd.get var in
      (Jstr.v "value", Jv.of_float v)
    in
    `R v :: prop
  in
  Brr_lwd.Elwd.input ?st ~at ~ev ~prop ()

let string ?(callback = fun _ -> ()) ?(ev = []) ?st ?(prop = []) ?type'
    ?(kind = `Change) var attrs =
  let ev =
    let set =
      let h =
       fun ev ->
        let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
        let new_value = Jv.get el "value" |> Jv.to_string in
        callback new_value;
        Lwd.set var new_value
      in
      match kind with
      | `Change -> Brr_lwd.Elwd.handler Brr.Ev.change h
      | `Input -> Brr_lwd.Elwd.handler Brr.Ev.input h
    in
    `P set :: ev
  in
  let at =
    let type' =
      match type' with None -> [] | Some t -> [ `P (Brr.At.type' (Jstr.v t)) ]
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
  Brr_lwd.Elwd.input ?st ~at ~ev ~prop ()

let of_color (c : Drawing.Color.t Lwd.var) =
  let set =
    Brr_lwd.Elwd.handler Brr.Ev.change (fun ev ->
        let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
        let new_value =
          Jv.get el "value" |> Jv.to_string |> Drawing.Color.of_string
        in
        Brr.Console.(log [ new_value ]);
        Lwd.set c new_value)
  in
  let ev = [ `P set ] in
  let at =
    let v =
      let$ v = Lwd.get c in
      Brr.At.value (v |> Drawing.Color.to_string |> Jstr.of_string)
    in
    [ `R v ]
  in
  let children =
    List.map
      (fun col ->
        let at = if col = Lwd.peek c then [ Brr.At.selected ] else [] in
        `P (Brr.El.option ~at [ Brr.El.txt' (Drawing.Color.to_string col) ]))
      Drawing.Color.all
  in
  Brr_lwd.Elwd.select ~at ~ev children

let hover ?(var = Lwd.var false) () =
  let handler1 =
    Brr_lwd.Elwd.handler Brr.Ev.mouseenter (fun _ -> Lwd.set var true)
  in
  let handler2 =
    Brr_lwd.Elwd.handler Brr.Ev.mouseleave (fun _ -> Lwd.set var false)
  in
  (Lwd.get var, Lwd_seq.of_list [ handler1; handler2 ])

let is_pressed ev =
  let is_pressed = ( != ) 0 in
  is_pressed
    (ev |> Brr.Ev.as_type |> Brr.Ev.Pointer.as_mouse |> Brr.Ev.Mouse.buttons)

let mouse_drag start drag end_ =
  let mouse_move x y acc =
   fun ev ->
    let mouse_ev = Brr.Ev.as_type ev |> Brr.Ev.Pointer.as_mouse in
    let x' = Brr.Ev.Mouse.page_x mouse_ev in
    let y' = Brr.Ev.Mouse.page_y mouse_ev in
    drag ~x ~y ~dx:(x' -. x) ~dy:(y' -. y) acc ev
  in
  Brr_lwd.Elwd.handler Brr.Ev.pointerdown (fun ev ->
      Brr.Ev.prevent_default ev;
      let mouse_ev = Brr.Ev.as_type ev |> Brr.Ev.Pointer.as_mouse in
      let x = Brr.Ev.Mouse.page_x mouse_ev in
      let y = Brr.Ev.Mouse.page_y mouse_ev in
      let acc = start x y ev in
      let acc = ref acc in
      let mousemove_listener = ref None in
      let mouseup_listener = ref None in
      let unlisten () =
        Option.iter Brr.Ev.unlisten !mousemove_listener;
        Option.iter Brr.Ev.unlisten !mouseup_listener;
        end_ !acc ev
      in
      let id =
        Brr.Ev.listen Brr.Ev.pointermove
          (fun ev ->
            if is_pressed ev then acc := mouse_move x y !acc ev else unlisten ())
          (Brr.Document.body Brr.G.document |> Brr.El.as_target)
      in
      mousemove_listener := Some id;
      let opts = Brr.Ev.listen_opts ~once:true () in
      let id =
        Brr.Ev.listen ~opts Brr.Ev.pointerup
          (fun _ev -> unlisten ())
          (Brr.Document.body Brr.G.document |> Brr.El.as_target)
      in
      mouseup_listener := Some id;
      ())
