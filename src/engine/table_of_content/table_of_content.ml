let ( !! ) = Jstr.v
let inner_text = Brr.El.Prop.jstr !!"innerText"

let entry window step ~tag_name ~content =
  let step_elem =
    match step with
    | None -> []
    | Some step ->
        [
          Brr.El.div
            ~at:[ Brr.At.class' !!"slipshow-toc-step" ]
            [ Brr.El.txt Jstr.(of_int step + !!".") ];
        ]
  in
  let content_elem =
    if Jstr.is_empty content then []
    else
      [
        Brr.El.v tag_name
          ~at:[ Brr.At.class' !!"slipshow-toc-content" ]
          [ Brr.El.txt content ];
      ]
  in
  let at =
    if Jstr.is_empty content then [ Brr.At.class' !!"slipshow-toc-only-step" ]
    else []
  in
  let el = Brr.El.div ~at (step_elem @ content_elem) in
  let () =
    match step with
    | None -> ()
    | Some step ->
        Brr.El.set_class !!"slipshow-toc-entry" true el;
        Brr.El.set_class !!("slipshow-toc-step-" ^ string_of_int step) true el;
        let _unistener =
          Brr.Ev.listen Brr.Ev.click
            (fun _ ->
              let _ : unit Fut.t = Step.Next.goto step window in
              ())
            (Brr.El.as_target el)
        in
        ()
  in
  el

let categorize window step el =
  let step =
    match (Brr.El.at !!"step" el, Brr.El.at !!"pause" el) with
    | None, None -> None
    | _ -> Some (step + 1)
  in
  let content, tag_name =
    match Brr.El.tag_name el |> Jstr.to_string with
    | "h1" | "h2" | "h3" | "h4" | "h5" ->
        let content = Brr.El.prop inner_text el in
        (content, Brr.El.tag_name el)
    | _ ->
        let cap = 80 in
        let content = Jstr.slice ~stop:cap (Brr.El.prop inner_text el) in
        let content =
          if Jstr.length (Brr.El.prop inner_text el) > cap then
            Jstr.append content !!"..."
          else content
        in
        (content, !!"div")
  in
  let el = entry window step ~tag_name ~content in
  (el, step)

let generate window root =
  let els =
    Brr.El.fold_find_by_selector ~root
      (fun el (step, acc) ->
        let el, new_step = categorize window step el in
        let step = Option.value ~default:step new_step in
        (step, el :: acc))
      !!"[pause], [step], h1, h2, h3, h4, h5"
      (0, [])
    |> snd |> List.rev
  in
  let els = entry window (Some 0) ~tag_name:!!"div" ~content:!!"" :: els in
  let toc_el = Brr.El.div ~at:[ Brr.At.id !!"slipshow-toc" ] els in
  Brr.El.append_children (Brr.Document.body Brr.G.document) [ toc_el ]
