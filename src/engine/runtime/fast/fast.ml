type mode = Normal | Fast_move | Counting_for_toc

let mode = ref Normal

(* I don't think we can really make a [finally]-style function: {!/Fut.t} does
   not support exceptions... *)
let with_ new_mode f =
  let open Fut.Syntax in
  let old_mode = !mode in
  mode := new_mode;
  let+ res = f () in
  mode := old_mode;
  res

(* This is actually tricky: if we do two [with_] in parallel (which might happen
   if it's triggered by a keystroke) you don't know which mode you'll end
   with...
*)

let with_fast f =
  match !mode with
  | Fast_move -> f () (* To avoid the parallel problem mentioned above *)
  | _ -> with_ Fast_move f

let with_counting f = with_ Counting_for_toc f
let is_counting () = !mode = Counting_for_toc
let is_fast () = !mode = Fast_move
let get_mode () = !mode
