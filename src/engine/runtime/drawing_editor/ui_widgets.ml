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
  let selected = var in
  let handler1 =
    Brr_lwd.Elwd.handler Brr.Ev.mouseenter (fun _ -> Lwd.set selected true)
  in
  let handler2 =
    Brr_lwd.Elwd.handler Brr.Ev.mouseleave (fun _ -> Lwd.set selected false)
  in
  (Lwd.get selected, [ `P handler1; `P handler2 ])

let mouse_drag click drag end_ =
  let has_moved = ref false in
  let click_handler =
    Brr_lwd.Elwd.handler Brr.Ev.click (fun ev ->
        if !has_moved then () else click ev)
  in
  let move_handler =
    let mouse_move x y current_target =
     fun ev ->
      has_moved := true;
      let mouse_ev = Brr.Ev.as_type ev in
      let x' = Brr.Ev.Mouse.page_x mouse_ev in
      let y' = Brr.Ev.Mouse.page_y mouse_ev in
      drag ~x ~y ~dx:(x' -. x) ~dy:(y' -. y) ~current_target ev
    in
    Brr_lwd.Elwd.handler Brr.Ev.mousedown (fun ev ->
        Brr.Ev.prevent_default ev;
        has_moved := false;
        let mouse_ev = Brr.Ev.as_type ev in
        (* It would be nice to just pass the event itself, but outside of the
           event handler the current target may be [null] unfortunately stupid
           programming language... See
           https://developer.mozilla.org/en-US/docs/Web/API/Event/currentTarget *)
        let current_target = ev |> Brr.Ev.current_target in
        let x = Brr.Ev.Mouse.page_x mouse_ev in
        let y = Brr.Ev.Mouse.page_y mouse_ev in
        let id =
          Brr.Ev.listen Brr.Ev.mousemove
            (mouse_move x y current_target)
            (Brr.Document.body Brr.G.document |> Brr.El.as_target)
        in
        let opts = Brr.Ev.listen_opts ~once:true () in
        let _id =
          Brr.Ev.listen ~opts Brr.Ev.mouseup
            (fun _ ->
              Brr.Ev.unlisten id;
              end_ ())
            (Brr.Document.body Brr.G.document |> Brr.El.as_target)
        in
        ())
  in
  [ `P move_handler; `P click_handler ]
