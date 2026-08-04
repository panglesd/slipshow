open Brr

let ( !! ) = Jstr.v
let activate_class = !!"slipshow-activated"

let activate id =
  match El.find_first_by_selector !!("#" ^ id) with
  | None -> ()
  | Some el -> El.set_class activate_class true el
