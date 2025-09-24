open Lwd_infix

let float ?type' ?(kind = `Change) var attrs =
  let h =
   fun ev ->
    let el = ev |> Brr.Ev.target |> Brr.Ev.target_to_jv in
    let new_value = Jv.get el "value" |> Jv.to_string |> float_of_string in
    Brr.Console.(log [ new_value ]);
    Lwd.set var new_value
  in
  let set =
    match kind with
    | `Change -> Brr_lwd.Elwd.handler Brr.Ev.change h
    | `Input -> Brr_lwd.Elwd.handler Brr.Ev.input h
  in
  let ev = [ `P set ] in
  let at =
    let v =
      let$ v = Lwd.get var in
      Brr.At.value (Jstr.of_float v)
    in
    let type' =
      match type' with None -> [] | Some t -> [ `P (Brr.At.type' (Jstr.v t)) ]
    in
    (`R v :: type') @ attrs
  in
  Brr_lwd.Elwd.input ~at ~ev ()

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

let hover ?(var = Lwd.var None) value () =
  let selected = var in
  let handler1 =
    Brr_lwd.Elwd.handler Brr.Ev.mouseenter (fun _ ->
        Lwd.set selected (Some value))
  in
  let handler2 =
    Brr_lwd.Elwd.handler Brr.Ev.mouseleave (fun _ -> Lwd.set selected None)
  in
  (Lwd.get selected, [ `P handler1; `P handler2 ])
