let is_fast = ref false

(* I don't think we can really make a [finally]-style function: {!/Fut.t} does
   not support exceptions... *)
let with_fast f =
  let open Fut.Syntax in
  is_fast := true;
  let+ res = f () in
  is_fast := false;
  res

let is_fast () = !is_fast
