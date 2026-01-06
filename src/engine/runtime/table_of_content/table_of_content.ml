open Brr

let ( !! ) = Jstr.v
let inner_text = Brr.El.Prop.jstr !!"innerText"

let toggle_visibility window =
  let body = window |> Window.document |> Document.body in
  let c = Jstr.v "slipshow-toc-mode" in
  El.set_class c (not @@ El.class' c body) body

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

let entry_action global window step =
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
          let _ : unit Fut.t =
            Fast.with_fast @@ fun () -> Step.Next.goto global step window
          in
          Messaging.send_step global step `Fast)
        (Brr.El.as_target el)
    in
    ()
  in
  el

open Undoable.Syntax
open Fut.Syntax

let generate global window root =
  let categorized_els =
    Brr.El.fold_find_by_selector ~root
      (fun el acc -> categorize el :: acc)
      !!(Step.Action_scheduler.all_action_selector ^ ", h1, h2, h3, h4, h5")
      []
    |> List.rev |> List.concat
  in
  let rec loop undo entries step categorized_els =
    match categorized_els with
    | `Title t :: res ->
        let entries = entry_title t :: entries in
        loop undo entries step res
    | `Action a :: res ->
        if Step.Action_scheduler.is_action a then
          let* res =
            Step.Action_scheduler.AttributeActions.do_ global window a
          in
          let undo =
            let> () = undo in
            Fut.return res
          in
          let step = step + 1 in
          let entries = entry_action global window step :: entries in
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
  let els = entry_action global window 0 :: entries in
  let toc_el = Brr.El.div ~at:[ Brr.At.id !!"slipshow-toc" ] els in
  let horizontal_container =
    Brr.El.find_first_by_selector ~root (Jstr.v "#slipshow-horizontal-flex")
    |> Option.get
  in
  Brr.El.append_children horizontal_container [ toc_el ];
  let _unlisten =
    Brr.Ev.listen Brr.Ev.click
      (fun _ -> toggle_visibility global.window)
      (Brr.El.find_first_by_selector ~root (Jstr.v "#slipshow-counter")
      |> Option.get |> Brr.El.as_target)
  in
  ()
