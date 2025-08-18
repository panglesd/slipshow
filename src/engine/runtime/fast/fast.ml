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

let with_fast f = with_ Fast_move f
let with_counting f = with_ Counting_for_toc f
let is_counting () = !mode = Counting_for_toc
let is_fast () = !mode = Fast_move
let get_mode () = !mode
