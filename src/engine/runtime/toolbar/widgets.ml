open Lwd_infix
open Brr_lwd

let set_handler v value = Elwd.handler Brr.Ev.click (fun _ -> Lwd.set v value)
let ( !! ) = Jstr.v

let panel_icon ?ev ?(at = []) ?st el =
  Elwd.div ?ev ~at:(`P (Brr.At.class' !!"slipshow-icon") :: at) ?st el

let panel_button ?label_for ?shortcut ?handler ?(at = []) ~icon text =
  let shortcut =
    match shortcut with
    | None -> []
    | Some shortcut ->
        [
          `P
            (Brr.El.kbd
               ~at:[ Brr.At.class' !!"slipshow-key" ]
               [ Brr.El.txt' shortcut ]);
        ]
  in
  let text =
    let txt =
      match label_for with
      | None ->
          let$ text = text in
          Brr.El.txt' text
      | Some lbl ->
          let$ text = text in
          Brr.El.label
            ~at:[ Brr.At.style !!"cursor:pointer"; Brr.At.for' !!lbl ]
            [ Brr.El.txt' text ]
    in
    Elwd.div ~at:[ `P (Brr.At.style !!"flex-grow:11") ] [ `R txt ]
  in
  Elwd.div
    ~at:(`P (Brr.At.class' !!"slipshow-button") :: at)
    ~ev:(match handler with None -> [] | Some c -> [ `P c ])
    ([ `R icon; `R text ] @ shortcut)

let panel_block ?class_ ~buttons () =
  Elwd.div
    ~at:
      ((match class_ with None -> [] | Some c -> [ `P (Brr.At.class' !!c) ])
      @ [ `P (Brr.At.class' !!"tool-block") ])
    buttons

let toplevel_panel_el =
  Elwd.div ~at:[ `P (Brr.At.class' !!"slip-writing-toolbar") ]
