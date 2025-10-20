open Types

module type Stroker = sig
  (* type state *)
  type start_args
  type event

  val start :
    origin -> start_args -> id:string -> coord:float * float -> event option

  val continue : origin -> coord:float * float -> event option
  val end_ : (* coord:float * float ->  *) origin -> event option
  val execute : event -> unit
end

module type One_shot = sig
  (* type state *)
  type args
  type event

  val click : origin -> args -> event option
  val execute : event -> unit
end

module Draw : Stroker with type start_args = Types.Tool.stroker = struct
  (* type state = Brr.El.t * Stroke.t *)
  type start_args = Types.Tool.stroker

  type event =
    | Start of {
        origin : origin;
        stroker : Types.Tool.stroker;
        id : string;
        coord : float * float;
        width : Width.t;
        color : Color.t;
      }
    | Continue of { origin : origin; coord : float * float }
    | End of { origin : origin }

  let start origin stroker ~id ~coord =
    let state = State.get_state () in
    let color = state.color and width = state.width in
    Some (Start { origin; stroker; id; coord; color; width })

  let continue origin ~coord = Some (Continue { origin; coord })
  let end_ origin = Some (End { origin })

  let states : (origin, (Brr.El.t * Stroke.t) option) Hashtbl.t =
    Hashtbl.create 10

  let get_state origin = Hashtbl.find_opt states origin |> Option.join
  let set_state origin state = Hashtbl.replace states origin state

  let svg =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
    |> Option.get

  module Execute = struct
    let start origin stroker ~id ~coord ~color ~width =
      let opacity = match stroker with Tool.Highlighter -> 0.33 | Pen -> 1. in
      let end_at = (* Record.now () *) 0. in
      let path = [ (coord, end_at) ] in
      let options = Strokes.options_of stroker width in
      let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
      let stroke =
        { Stroke.path; options; opacity; id; color; scale; end_at }
      in
      let p = Strokes.create_elem_of_stroke stroke in
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
            (Some
               (Jstr.v
                  (Strokes.svg_path stroke.options stroke.scale stroke.path)))
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

  let execute = function
    | Start { origin; stroker; id; coord; color; width } ->
        Execute.start origin stroker ~id ~coord ~color ~width
    | Continue { origin; coord } -> Execute.continue origin ~coord
    | End { origin } -> Execute.end_ origin
end

module Erase : Stroker with type start_args = unit = struct
  type start_args = unit

  let states = Hashtbl.create 10
  let get_state origin = Hashtbl.find_opt states origin |> Option.join
  let set_state origin state = Hashtbl.replace states origin state

  type event = Erase of string list

  (* type state = float * float *)
  let start origin () ~id:_ ~coord =
    set_state origin (Some coord);
    None

  let continue origin ~coord =
    match get_state origin with
    | None -> None
    | Some last_point ->
        let ids =
          Hashtbl.fold
            (fun id (_elem, { Stroke.path; _ }) acc ->
              let intersect = Utils.intersect_poly path (coord, last_point) in
              let close_enough = Utils.close_enough_poly path coord in
              if intersect || close_enough then id :: acc else acc)
            State.Strokes.all []
        in
        set_state origin (Some coord);
        if List.is_empty ids then None else Some (Erase ids)

  let end_ origin =
    (* ~coord:_ *)
    set_state origin None;
    None

  (* module Execute = struct *)
  (* let start origin () ~id:_ ~coord = set_state origin (Some coord) *)

  (* let continue origin ~coord = *)
  (*   match  *)
  (*   match get_state origin with *)
  (*   | None -> () *)
  (*   | Some last_point -> *)
  (*       Hashtbl.iter *)
  (*         (fun _id (elem, { Stroke.path; _ }) -> *)
  (*           let intersect = Utils.intersect_poly path (coord, last_point) in *)
  (*           let close_enough = Utils.close_enough_poly path coord in *)
  (*           if intersect || close_enough then State.Strokes.remove_el elem) *)
  (*         State.Strokes.all; *)
  (*       set_state origin (Some coord) *)

  (* let end_ origin = (\* ~coord:_ *\) set_state origin None *)
  (* end *)

  let execute = function
    | Erase ids ->
        List.iter
          (fun id ->
            match Hashtbl.find_opt State.Strokes.all id with
            | None -> ()
            | Some (el, _) -> State.Strokes.remove_el el)
          ids
end

module Clear = struct
  type args = All | Origin of origin

  let concerned origin who =
    match who with All -> true | Origin o when o = origin -> true | _ -> false

  let click (origin : origin) (who : args) =
    Hashtbl.iter
      (fun _ (elem, _) -> State.Strokes.remove_el elem)
      State.Strokes.all
end
