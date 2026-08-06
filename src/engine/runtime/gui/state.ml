open Types

let status = Lwd.var Select
let current : Brr.El.t option Lwd.var = Lwd.var None

(* let _root : _ Lwd.root = *)
(*   let last = ref None in *)
(*   let ( !! ) = Jstr.v in *)
(*   let activate_class = !!"slipshow-activated" in *)
(*   let on_invalidate new_el = *)
(*     (match !last with *)
(*     | None -> () *)
(*     | Some old_el -> Brr.El.set_class activate_class false old_el); *)
(*     (match new_el with *)
(*     | None -> () *)
(*     | Some new_el -> Brr.El.set_class activate_class true new_el); *)
(*     last := new_el *)
(*   in *)
(*   Lwd.observe ~on_invalidate (Lwd.get current) *)
