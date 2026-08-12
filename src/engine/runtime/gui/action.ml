open Brr

let ( !! ) = Jstr.v
let activate_class = !!"slipshow-activated"

let activate_el el =
  match El.at !!"gui" el with
  | None -> ()
  | Some _ ->
      let () =
        match Lwd.peek State.current with
        | Some old_el when old_el <> el ->
            El.set_class activate_class false old_el
        | _ -> ()
      in
      Drawing_state.Status.set Gui_mode;
      Lwd.set State.current (Some el);
      if Lwd.peek State.status = Select then Lwd.set State.status Move;
      El.set_class activate_class true el

let activate id =
  match id with
  | Common_types.Id id -> (
      match El.find_first_by_selector !!("#" ^ id) with
      | None -> ()
      | Some el -> activate_el el)
  | Loc loc -> (
      match
        El.find_first_by_selector
          !!("[" ^ Common_types.Special_strings.gui_loc ^ "=\"" ^ loc ^ "\"]")
      with
      | None -> ()
      | Some el -> activate_el el)

let deactivate () =
  Drawing_state.Status.set (Drawing Presenting);
  match Lwd.peek State.current with
  | Some old_el ->
      Lwd.set State.current None;
      El.set_class activate_class false old_el
  | None -> ()
