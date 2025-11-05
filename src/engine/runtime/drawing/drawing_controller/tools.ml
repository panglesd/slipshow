(* open Lwd_infix *)
open Drawing_state.Live_coding

let very_quick_sample g =
  let root = Lwd.observe g in
  let res = Lwd.quick_sample root in
  Lwd.quick_release root;
  res

let ( !! ) = Jstr.v
let px_float x = Jstr.append (Jstr.of_float x) !!"px"

let coord_of_event ev =
  let mouse = Brr.Ev.as_type ev |> Brr.Ev.Pointer.as_mouse in
  let x = Brr.Ev.Mouse.client_x mouse and y = Brr.Ev.Mouse.client_y mouse in
  let main =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
  in
  let offset_x = Brr.El.bound_x main in
  (x -. offset_x, y)
  |> Normalization.translate_coords |> Universe.Window.translate_coords
  (* See system.css: we add padding to be able to write on the side of the
     content. *)
  |> fun (x, y) -> (x -. 2000., y -. 2000.)

module Draw_stroke = struct
  let starts_at l = List.hd (List.rev l) |> snd
  let end_at l = List.hd l |> snd

  let event strokes stroker color width =
    let coord_of_event x y =
      let main =
        Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
      in
      let offset_x = Brr.El.bound_x main in
      (x -. offset_x, y)
      |> Normalization.translate_coords |> Universe.Window.translate_coords
      (* See system.css: we add padding to be able to write on the side of the
     content. *)
      |> fun (x, y) -> (x -. 2000., y -. 2000.)
    in
    let start x y _ev =
      let x0, y0 = (x, y) in
      let x, y = coord_of_event x y in
      Brr.Console.(log [ "ABCDE" ]);
      let id =
        "id" ^ (Random.int 100000 |> string_of_int)
        (* TODO: id *)
      in
      let path = [ ((x, y), 0. (* TODO: time *)) ] in
      let el =
        (* let opacity = match tool with Highlighter -> 0.33 | Pen -> 1. in *)
        (* let options = Strokes.options_of stroker width in *)
        let path = Lwd.var path in
        let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
        let end_at = Lwd.map (Lwd.get path) ~f:end_at in
        let starts_at = Lwd.map (Lwd.get path) ~f:starts_at in
        (* let stroke = *)
        {
          id;
          scale;
          path;
          end_at;
          starts_at;
          color = Lwd.var color;
          stroker;
          width;
          selected = Lwd.var false;
          preselected = Lwd.var false;
          track = Lwd.var 0;
          erased = Lwd.var None;
          (* options; opacity; id; color; scale *)
        }
        (* in *)
        (* let p = Strokes.create_elem_of_stroke stroke in *)
        (* Brr.El.append_children svg [ p ]; *)
        (* set_state id (Some (p, stroke)); *)
        (* _ *)
      in
      Lwd_table.append' strokes el;
      (x0, y0, el)
      (* let position_var = (Lwd.var x, Lwd.var y, Lwd.var 0., Lwd.var 0.) in *)
      (* Lwd.set preview_selection_var (Some position_var); *)
      (* (x, y, position_var) *)
    in
    let drag ~dx ~dy ((x0, y0, el) as acc) _ev =
      let path = Lwd.peek el.path in
      let c = coord_of_event (x0 +. dx) (y0 +. dy) in
      let path = (c, 0. (* TODO: time *)) :: path in
      Lwd.set el.path path;
      acc
    in
    let end_ _ _ev = () in
    Drawing_editor.Ui_widgets.mouse_drag start drag end_
end

module Erase = struct
  let event strokes =
    let coord_of_event x y =
      let main =
        Brr.El.find_first_by_selector (Jstr.v "#slipshow-main") |> Option.get
      in
      let offset_x = Brr.El.bound_x main in
      (x -. offset_x, y)
      |> Normalization.translate_coords |> Universe.Window.translate_coords
      (* See system.css: we add padding to be able to write on the side of the
     content. *)
      |> fun (x, y) -> (x -. 2000., y -. 2000.)
    in
    let start x y _ev =
      (x, y)
      (* let position_var = (Lwd.var x, Lwd.var y, Lwd.var 0., Lwd.var 0.) in *)
      (* Lwd.set preview_selection_var (Some position_var); *)
      (* (x, y, position_var) *)
    in
    let drag ~dx ~dy (x, y) _ev =
      let nx, ny = (x +. dx, y +. dy) in
      let c0, c1 = (coord_of_event x y, coord_of_event nx ny) in
      let _strokes_to_erase =
        Lwd_table.iter
          (fun stro ->
            if Lwd.peek stro.erased |> Option.is_some then ()
            else
              let path = Lwd.peek stro.path in
              let intersect = Drawing.Utils.intersect_poly2 path (c0, c1) in
              let close_enough = Drawing.Utils.close_enough_poly2 path c1 in
              if intersect || close_enough then
                Lwd.set stro.erased
                  (Some
                     {
                       at = Lwd.var 0. (* TODO: time *);
                       track = Lwd.var (Lwd.peek stro.track);
                       selected = Lwd.var false;
                       preselected = Lwd.var false;
                     })
              else ())
          strokes
      in
      (x, y)
    in
    let end_ _ _ev = () in
    Drawing_editor.Ui_widgets.mouse_drag start drag end_
end

module Clear = struct
  let event strokes =
    Lwd_table.iter
      (fun stro ->
        if Lwd.peek stro.erased |> Option.is_some then ()
        else
          Lwd.set stro.erased
            (Some
               {
                 at = Lwd.var 0. (* TODO: time *);
                 track = Lwd.var (Lwd.peek stro.track);
                 selected = Lwd.var false;
                 preselected = Lwd.var false;
               }))
      strokes
end
