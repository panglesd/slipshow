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
    if Step.Action_scheduler.is_action el then Some (step + 1) else None
  in
  let content, tag_name =
    match Brr.El.tag_name el |> Jstr.to_string with
    | "h1" | "h2" | "h3" | "h4" | "h5" ->
        let content = Brr.El.prop inner_text el in
        (content, Brr.El.tag_name el)
    | _ ->
        let _content () =
          (* This is the old content, the toc looks better without the
             preview. Maybe the preview should be used in the title attribute,
             so I keep the code easily available here *)
          let cap = 100 in
          let content = Jstr.slice ~stop:cap (Brr.El.prop inner_text el) in
          if Jstr.length (Brr.El.prop inner_text el) > cap then
            Jstr.append content !!"..."
          else content
        in
        let content = !!"" in
        (content, !!"div")
  in
  let el = entry window step ~tag_name ~content in
  (el, step)

let toggle_visibility () =
  let body = Brr.Document.body Brr.G.document in
  let c = Jstr.v "slipshow-toc-mode" in
  Brr.El.set_class c (not @@ Brr.El.class' c body) body

let generate window root =
  let els =
    Brr.El.fold_find_by_selector ~root
      (fun el (step, acc) ->
        let el, new_step = categorize window step el in
        let step = Option.value ~default:step new_step in
        (step, el :: acc))
      !!(Step.Action_scheduler.all_action_selector ^ ", h1, h2, h3, h4, h5")
      (0, [])
    |> snd |> List.rev
  in
  let els = entry window (Some 0) ~tag_name:!!"div" ~content:!!"" :: els in
  let toc_el = Brr.El.div ~at:[ Brr.At.id !!"slipshow-toc" ] els in
  Brr.El.append_children (Brr.Document.body Brr.G.document) [ toc_el ];
  let _unlisten =
    Brr.Ev.listen Brr.Ev.click
      (fun _ -> toggle_visibility ())
      (Brr.El.find_first_by_selector (Jstr.v "#slipshow-counter")
      |> Option.get |> Brr.El.as_target)
  in
  ()
