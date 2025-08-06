let ( !! ) = Jstr.v
let inner_text = Brr.El.Prop.jstr !!"innerText"

let toggle_visibility () =
  let body = Brr.Document.body Brr.G.document in
  let c = Jstr.v "slipshow-toc-mode" in
  Brr.El.set_class c (not @@ Brr.El.class' c body) body

let categorize el =
  let action =
    if Step.Action_scheduler.is_action el then [ `Action el ] else []
  in
  let title =
    match Brr.El.tag_name el |> Jstr.to_string with
    | "h1" | "h2" | "h3" | "h4" | "h5" -> [ `Title el ]
    | _ -> []
  in
  title @ action

let entry_title el =
  Brr.El.v (Brr.El.tag_name el)
    ~at:[ Brr.At.class' !!"slipshow-toc-content" ]
    [ Brr.El.txt (Brr.El.prop inner_text el) ]

let entry_action window step =
  let step_elem =
    [
      Brr.El.div
        ~at:[ Brr.At.class' !!"slipshow-toc-step" ]
        [ Brr.El.txt Jstr.(of_int step + !!".") ];
    ]
  in
  let at = [ Brr.At.class' !!"slipshow-toc-only-step" ] in
  let el = Brr.El.div ~at step_elem in
  let () =
    Brr.El.set_class !!"slipshow-toc-entry" true el;
    Brr.El.set_class !!("slipshow-toc-step-" ^ string_of_int step) true el;
    let _unlistener =
      Brr.Ev.listen Brr.Ev.click
        (fun _ ->
          let _ : unit Fut.t = Step.Next.goto step window in
          ())
        (Brr.El.as_target el)
    in
    ()
  in
  el

open Undoable.Syntax
open Fut.Syntax

let generate window root =
  let categorized_els =
    Brr.El.fold_find_by_selector ~root
      (fun el acc -> categorize el :: acc)
      !!(Step.Action_scheduler.all_action_selector ^ ", h1, h2, h3, h4, h5")
      []
    |> List.rev |> List.concat
  in
  let rec loop undo entries step categorized_els =
    let* () = Fut.tick ~ms:0 in
    match categorized_els with
    | `Title t :: res ->
        let entries = entry_title t :: entries in
        loop undo entries step res
    | `Action a :: res ->
        if Step.Action_scheduler.is_action a then
          let undo =
            let> () = undo in
            Step.Action_scheduler.AttributeActions.do_ window a
          in
          let step = step + 1 in
          let entries = entry_action window step :: entries in
          loop undo entries step categorized_els
        else loop undo entries step res
    | [] -> Fut.return (undo, List.rev entries)
  in
  let* undo, entries =
    Fast.with_counting @@ fun () ->
    loop (Undoable.return ()) [] 0 categorized_els
  in
  let* (), undo = undo in
  let+ () = undo () in
  let els = entry_action window 0 :: entries in
  let toc_el = Brr.El.div ~at:[ Brr.At.id !!"slipshow-toc" ] els in
  Brr.El.append_children (Brr.Document.body Brr.G.document) [ toc_el ];
  let _unlisten =
    Brr.Ev.listen Brr.Ev.click
      (fun _ -> toggle_visibility ())
      (Brr.El.find_first_by_selector (Jstr.v "#slipshow-counter")
      |> Option.get |> Brr.El.as_target)
  in
  ()
