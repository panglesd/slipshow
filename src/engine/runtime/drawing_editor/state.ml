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

module Recording = struct
  let current = Lwd.var None
  let set_current (c : Drawing.Action.Record.record option) = Lwd.set current c

  open Lwd_infix

  let el =
    Brr.Console.(log [ "NOW"; "invalidated" ]);
    let id_elem =
      let$ current = current |> Lwd.get in
      let id =
        match current with
        | None -> "custom_start_time"
        | Some current -> current.start_time |> string_of_float
      in
      Brr.El.txt' id
    in
    Brr_lwd.Elwd.div [ `R id_elem ]
end
