open Fut.Syntax

let find_next_pause () =
  Brr.El.find_first_by_selector (Jstr.v "[pause], [step]")

let update_pause_ancestors () =
  let () =
    Brr.El.fold_find_by_selector
      (fun elem () ->
        Brr.Console.(log [ "Removing class for"; elem ]);
        Brr.El.set_class (Jstr.v "pauseAncestor") false elem)
      (Jstr.v ".pauseAncestor") ()
  in
  let () =
    match find_next_pause () with
    | None -> ()
    | Some elem ->
        let rec hide_parent elem =
          if Brr.El.class' (Jstr.v "universe") elem then ()
          else Brr.El.set_class (Jstr.v "pauseAncestor") true elem;
          match Brr.El.parent elem with
          | None -> ()
          | Some elem -> hide_parent elem
        in
        hide_parent elem
  in
  Fut.tick ~ms:0

let clear_pause elem =
  Brr.El.set_at (Jstr.v "pause") None elem;
  Brr.El.set_at (Jstr.v "step") None elem;
  update_pause_ancestors ()

let next () =
  match find_next_pause () with
  | None -> Fut.return ()
  | Some pause -> clear_pause pause
