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
let left_selection = Lwd.var 0.
let right_selection = Lwd.var 0.
let selected : State_types.stro option Lwd.var = Lwd.var None
let is_playing = Lwd.var false

open Lwd_infix

let is_selected stroke =
  let$ selected = Lwd.get selected in
  match selected with None -> false | Some selected -> stroke == selected

let preselected : State_types.stro option Lwd.var = Lwd.var None

let is_preselected stroke =
  let$ preselected = Lwd.get preselected in
  match preselected with
  | None -> false
  | Some preselected -> stroke == preselected

module Recording = struct
  let current = Lwd.var None

  let set_current c =
    Lwd.set current (Option.map State_conversion.record_of_record c)

  let peek_current () = Lwd.peek current
  let current = Lwd.get current
end
