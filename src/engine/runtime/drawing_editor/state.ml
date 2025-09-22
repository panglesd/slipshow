module Stroke = struct
  let current = Lwd.var None
  let set_current (c : Drawing.Stroke.t) = Lwd.set current (Some c)

  open Lwd_infix

  let el =
    let$* current = current |> Lwd.get in
    let id =
      match current with None -> "custom_id" | Some current -> current.id
    in
    let id_elem = Brr.El.txt' id in
    Brr_lwd.Elwd.div [ `P id_elem ]
end

let time = Lwd.var 0.

module Recording = struct
  let current = Lwd.var None

  let set_current c =
    Lwd.set current (Option.map State_conversion.record_of_record c)

  let peek_current () = Lwd.peek current
  let current = Lwd.get current
end
