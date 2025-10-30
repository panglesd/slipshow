open Lwd_infix
open State_types

let ( !! ) = Jstr.v
let total_length (recording : t) = Lwd.get recording.total_time
let px_int x = Jstr.append (Jstr.of_int x) !!"px"
let stroke_height = 20

let block_of_stroke recording (stroke : stro) =
  let selected =
    let$ selected = State.is_selected stroke
    and$ preselected = State.is_preselected stroke in
    let l =
      if selected then
        let height = px_int (stroke_height - 10) in
        [ (Brr.El.Style.height, height); (!!"border", !!"5px solid black") ]
      else if preselected then
        let height = px_int (stroke_height - 10) in
        [ (Brr.El.Style.height, height); (!!"border", !!"5px solid grey") ]
      else [ (Brr.El.Style.height, px_int stroke_height) ]
    in
    Lwd_seq.of_list ((!!"min-width", !!"1px") :: l)
  in
  let st =
    let left =
      let$ start_time = stroke.starts_at
      and$ total_length = total_length recording in
      let left = start_time *. 100. /. total_length in
      let left = Jstr.append (Jstr.of_float left) !!"%" in
      (Brr.El.Style.left, left)
    in
    let right =
      let$ end_time = stroke.end_at
      and$ total_length = total_length recording in
      let right = (total_length -. end_time) *. 100. /. total_length in
      let right = Jstr.append (Jstr.of_float right) !!"%" in
      (Brr.El.Style.right, right)
    in
    let top =
      let$ track = Lwd.get stroke.track in
      let top = px_int (track * stroke_height) in
      (Brr.El.Style.top, top)
    in
    let color =
      let$ color = Lwd.get stroke.color in
      let color = color |> Drawing.Color.to_string |> ( !! ) in
      (Brr.El.Style.background_color, color)
    in
    [
      `R left;
      `R right;
      `R top;
      `S selected;
      `P (Brr.El.Style.position, !!"absolute");
      `R color;
    ]
  in
  let block_of_erased (v : erased) =
    let t = Lwd.get v.at in
    let left =
      let$ start_time = t and$ total_length = total_length recording in
      let left = start_time *. 100. /. total_length in
      let left = Jstr.append (Jstr.of_float left) !!"%" in
      let left =
        Jstr.(v "calc(" + left + v " - " + of_int (stroke_height / 2) + v "px)")
      in
      (Brr.El.Style.left, left)
    in
    let top =
      let$ track = Lwd.get v.track in
      let top = px_int (track * stroke_height) in
      (Brr.El.Style.top, top)
    in
    let width =
      let$ selected = State.is_selected stroke
      and$ preselected = State.is_preselected stroke
      and$ erase_selected = Lwd.get v.selected
      and$ erase_preselected = Lwd.get v.preselected in
      let width =
        if selected || preselected || erase_selected || erase_preselected then
          stroke_height / 2
        else stroke_height
      in
      (Brr.El.Style.width, px_int width)
    in
    let selected =
      let$ selected = State.is_selected stroke
      and$ preselected = State.is_preselected stroke
      and$ erase_selected = Lwd.get v.selected
      and$ erase_preselected = Lwd.get v.preselected in
      let l =
        if selected || erase_selected then
          let height = px_int (stroke_height - 10) in
          [ (Brr.El.Style.height, height); (!!"border", !!"5px solid black") ]
        else if preselected || erase_preselected then
          let height = px_int (stroke_height - 10) in
          [ (Brr.El.Style.height, height); (!!"border", !!"5px solid grey") ]
        else [ (Brr.El.Style.height, px_int stroke_height) ]
      in
      Lwd_seq.of_list ((!!"min-width", !!"1px") :: l)
    in
    let st =
      [
        `R left;
        `R top;
        `S selected;
        `P (Brr.El.Style.position, !!"absolute");
        `R width;
        `P (Brr.El.Style.background_color, !!"lightgrey");
        `P (!!"border-radius", px_int (stroke_height / 2));
        (* `R color; *)
      ]
    in
    let ev_hover =
      let$ current_tool = Lwd.get State.current_tool in
      match current_tool with
      | Move -> Lwd_seq.empty
      | Select -> snd @@ Ui_widgets.hover ~var:stroke.preselected ()
    in
    let ev = [ `S ev_hover ] in
    Brr_lwd.Elwd.div ~ev ~st []
  in
  let$ erased_block =
    let$ erased = Lwd.get stroke.erased in
    match erased with
    | None -> Lwd_seq.empty
    | Some erased_at -> Lwd_seq.element @@ block_of_erased erased_at
  in
  let ev =
    let ev_hover =
      let$ current_tool = Lwd.get State.current_tool in
      match current_tool with
      | Move -> Lwd_seq.empty
      | Select -> snd @@ Ui_widgets.hover ~var:stroke.preselected ()
    in
    [ `S ev_hover ]
  in
  Lwd_seq.concat (Lwd_seq.element @@ Brr_lwd.Elwd.div ~ev ~st []) erased_block

let strokes recording =
  Lwd_table.map_reduce
    (fun _ s -> block_of_stroke recording s)
    Lwd_seq.lwd_monoid recording.strokes
  |> Lwd.join |> Lwd_seq.lift

let el recording =
  let strokes = strokes recording in
  let st =
    let height =
      let$ n_track = State.Track.n_track recording.strokes in
      ( Brr.El.Style.height,
        Jstr.append (Jstr.of_int ((n_track + 1) * 20)) !!"px" )
    in
    let cursor =
      let$ current_tool = Lwd.get State.current_tool in
      match current_tool with
      | Select -> (!!"cursor", !!"crosshair")
      | Move -> (!!"cursor", !!"move")
    in
    [ `P (Brr.El.Style.position, !!"relative"); `R height; `R cursor ]
  in
  let ev =
    let$ current_tool = Lwd.get State.current_tool in
    match current_tool with
    | Select ->
        Lwd_seq.element
        @@ Editor_tools.Selection.Timeline.event recording ~stroke_height
    | Move ->
        Lwd_seq.element
        @@ Editor_tools.Move.Timeline.event recording ~stroke_height
  in
  let box =
    let$* current_tool = Lwd.get State.current_tool in
    match current_tool with
    | Select -> Editor_tools.Selection.Timeline.box
    | Move -> Lwd.return Lwd_seq.empty
  in
  Brr_lwd.Elwd.div ~ev:[ `S ev ] ~st [ `S strokes; `S box ]
