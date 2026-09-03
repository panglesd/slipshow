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
          let _ : unit Fut.t =
            Step.Next.go_to ~send_message:true ~mode:Fast.fast step window
          in
          ())
        (Brr.El.as_target el)
    in
    ()
  in
  el

open Undoable.Syntax
open Fut.Syntax

let generate window root =
  let mode = Fast.counting_for_toc in
  let categorized_els =
    Brr.El.fold_find_by_selector ~root
      (fun el acc -> categorize el :: acc)
      !!(Step.Action_scheduler.all_action_selector ^ ", h1, h2, h3, h4, h5")
      []
    |> List.rev |> List.concat
  in
  let same el el' = Jv.equal (Brr.El.to_jv el) (Brr.El.to_jv el') in
  let blank el =
    Brr.El.is_txt el && Jstr.is_empty (Jstr.trim (Brr.El.txt_text el))
  in
  let rec opens_with a ~title =
    match List.filter (Fun.negate blank) (Brr.El.children a) with
    | first :: _ -> same first title || opens_with first ~title
    | [] -> false
  in
  let rec hoist_opening_titles = function
    (* When an action has first element (computed recursively) a title, the title
       should be first in the toc (just as when a title is an action) *)
    | (`Action a as action) :: `Title t :: rest
      when (not (Step.Action_scheduler.is_action t)) && opens_with a ~title:t ->
        `Title t :: action :: hoist_opening_titles rest
    | x :: rest -> x :: hoist_opening_titles rest
    | [] -> []
  in
  let categorized_els = hoist_opening_titles categorized_els in
  let rec loop ~auto_continue undo entries step categorized_els =
    match categorized_els with
    | `Title t :: res ->
        let entries = entry_title t :: entries in
        loop ~auto_continue undo entries step res
    | `Action a :: res ->
        if Step.Action_scheduler.is_action a then
          let* res =
            Step.Action_scheduler.AttributeActions.do_ ~mode window a
          in
          let undo =
            let> () = undo in
            Fut.return res
          in
          let step = if auto_continue then step else step + 1 in
          let entries =
            if auto_continue then entries
            else entry_action window step :: entries
          in
          let auto_continue = Brr.El.at !!"auto-continue" a |> Option.is_some in
          loop ~auto_continue undo entries step categorized_els
        else loop ~auto_continue undo entries step res
    | [] -> Fut.return (undo, List.rev entries)
  in
  let* undo, entries =
    loop ~auto_continue:false (Undoable.return ()) [] 0 categorized_els
  in
  let* (), undo = undo in
  let+ () = undo () in
  let els = entry_action window 0 :: entries in
  let toc_el = Brr.El.div ~at:[ Brr.At.id !!"slipshow-toc" ] els in
  let horizontal_container =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-horizontal-flex")
    |> Option.get
  in
  Brr.El.append_children horizontal_container [ toc_el ];
  let _unlisten =
    Brr.Ev.listen Brr.Ev.click
      (fun _ -> toggle_visibility ())
      (Brr.El.find_first_by_selector (Jstr.v "#slipshow-counter")
      |> Option.get |> Brr.El.as_target)
  in
  ()
