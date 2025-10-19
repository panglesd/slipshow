open Types

type origin = Self | Sent of string

module type T = sig
  (* type state *)
  type start_args

  val start : origin -> start_args -> id:string -> coord:float * float -> unit
  val continue : origin -> coord:float * float -> unit
  val end_ : (* coord:float * float ->  *) origin -> unit
end

module Draw (* : T with type start_args = Types.Tool.stroker *) = struct
  (* type state = Brr.El.t * Stroke.t *)
  type start_args = Types.Tool.stroker

  let states : (origin, (Brr.El.t * Stroke.t) option) Hashtbl.t =
    Hashtbl.create 10

  let get_state origin = Hashtbl.find_opt states origin |> Option.join
  let set_state origin state = Hashtbl.replace states origin state

  let svg_path options scale path =
    let path =
      List.rev_map
        (fun ((x, y), _) -> Perfect_freehand.Point.v (x *. scale) (y *. scale))
        path
    in
    let stroke = Perfect_freehand.get_stroke ~options path in
    let svg_path = Perfect_freehand.get_svg_path_from_stroke stroke in
    Jstr.to_string svg_path

  let create_elem_of_stroke
      { Stroke.options; scale; color; opacity; id; path; end_at = _ } =
    let p = Brr.El.v ~ns:`SVG (Jstr.v "path") [] in
    let set_at at v = Brr.El.set_at (Jstr.v at) (Some (Jstr.v v)) p in
    set_at "fill" (Color.to_string color);
    set_at "id" id;
    let () =
      let scale = 1. /. scale in
      let scale = string_of_float scale in
      Brr.El.set_inline_style (Jstr.v "transform")
        (Jstr.v @@ "scale3d(" ^ scale ^ "," ^ scale ^ "," ^ scale ^ ")")
        p
    in
    set_at "opacity" (string_of_float opacity);
    Brr.El.set_at (Jstr.v "d") (Some (Jstr.v (svg_path options scale path))) p;
    p

  let options_of stroke width =
    let size =
      match (stroke, width) with
      | Tool.Pen, Width.Small -> 6.
      | Pen, Medium -> 10.
      | Pen, Large -> 14.
      | Highlighter, Small -> 28.
      | Highlighter, Medium -> 38.
      | Highlighter, Large -> 48.
    in
    Perfect_freehand.Options.v ~thinning:0.5 ~smoothing:0.5 ~size
      ~streamline:0.5 ~last:false ()

  let svg =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
    |> Option.get

  let start origin stroker ~id ~coord =
    let opacity = match stroker with Tool.Highlighter -> 0.33 | Pen -> 1. in
    let end_at = (* Record.now () *) 0. in
    let state = State.get_state () in
    let path = [ (coord, end_at) ] in
    let options = options_of stroker state.width in
    let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
    let stroke =
      { Stroke.path; options; opacity; id; color = state.color; scale; end_at }
    in
    let p = create_elem_of_stroke stroke in
    Brr.El.append_children svg [ p ];
    set_state origin (Some (p, stroke))

  let continue origin ~coord =
    match get_state origin with
    | None -> ()
    | Some (el, stroke) ->
        let t = (* Record.now () *) 0. in
        let stroke =
          { stroke with Stroke.path = (coord, t) :: stroke.path; end_at = t }
        in
        Brr.El.set_at (Jstr.v "d")
          (Some (Jstr.v (svg_path stroke.options stroke.scale stroke.path)))
          el;
        set_state origin (Some (el, stroke))

  let end_ origin =
    (* ~coord:_ *)
    (* ((_, stroke) as state : state) *)
    (* let s = Stroke.to_string stroke in *)
    (* Brr.Console.(log [ "a stroke is: "; s ]); *)
    (* Record.record (Record.Stroke stroke); *)
    match get_state origin with
    | None -> ()
    | Some ((_, stroke) as state) ->
        set_state origin None;
        Hashtbl.add State.Strokes.all stroke.id state
end

module Erase : T with type start_args := unit = struct
  let states = Hashtbl.create 10
  let get_state origin = Hashtbl.find_opt states origin |> Option.join
  let set_state origin state = Hashtbl.replace states origin state

  (* type state = float * float *)

  let start origin () ~id:_ ~coord = set_state origin (Some coord)

  let continue origin ~coord =
    match get_state origin with
    | None -> ()
    | Some last_point ->
        Hashtbl.iter
          (fun _id (elem, { Stroke.path; _ }) ->
            let intersect = Utils.intersect_poly path (coord, last_point) in
            let close_enough = Utils.close_enough_poly path coord in
            if intersect || close_enough then State.Strokes.remove_el elem)
          State.Strokes.all;
        set_state origin (Some coord)

  let end_ origin = (* ~coord:_ *) set_state origin None
end
