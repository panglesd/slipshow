open Types

module type Tool = sig
  type event

  val event_of_string : string -> event option
  val execute : origin -> event -> Record.event option
  val send : event -> unit
end

module type Stroker = sig
  type start_args

  include Tool

  val start : start_args -> id:string -> coord:float * float -> event option
  val continue : coord:float * float -> event option
  val end_ : event option
end

type draw_start_args = {
  stroker : Types.Tool.stroker;
  width : Width.t;
  color : Color.t;
}
[@@deriving yojson]

module Draw : Stroker with type start_args = draw_start_args = struct
  type start_args = draw_start_args [@@deriving yojson]

  type event =
    | Start of { start_args : start_args; id : string; coord : float * float }
    | Continue of { coord : float * float }
    | End
  [@@deriving yojson]

  let event_to_string ev = ev |> event_to_yojson |> Yojson.Safe.to_string

  let event_of_string s =
    match Yojson.Safe.from_string s with
    | r -> event_of_yojson r
    | exception Yojson.Json_error e -> Error e

  let event_of_string s =
    match event_of_string s with
    | Ok s -> Some s
    | Error e ->
        Brr.Console.(
          log [ "Error when converting back a draw tool event:"; e; s ]);
        None

  let start start_args ~id ~coord = Some (Start { start_args; id; coord })
  let continue ~coord = Some (Continue { coord })
  let end_ = Some End

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
      let end_at = Record.now () in
      let path = [ (coord, end_at) ] in
      let options = Strokes.options_of stroker width in
      let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
      let stroke =
        { Stroke.path; options; opacity; id; color; scale; end_at }
      in
      let p = Strokes.create_elem_of_stroke stroke in
      Brr.El.append_children svg [ p ];
      set_state origin (Some (p, stroke));
      None

    let continue origin ~coord =
      match get_state origin with
      | None -> None
      | Some (el, stroke) ->
          let t = Record.now () in
          let stroke =
            { stroke with Stroke.path = (coord, t) :: stroke.path; end_at = t }
          in
          Brr.El.set_at (Jstr.v "d")
            (Some
               (Jstr.v
                  (Strokes.svg_path stroke.options stroke.scale stroke.path)))
            el;
          set_state origin (Some (el, stroke));
          None

    let end_ origin =
      match get_state origin with
      | None -> None
      | Some ((_, stroke) as state) ->
          set_state origin None;
          Hashtbl.add State.Strokes.all stroke.id state;
          Some (Record.Stroke stroke)
  end

  let execute origin = function
    | Start { start_args = { stroker; width; color }; id; coord } ->
        Execute.start origin stroker ~id ~coord ~color ~width
    | Continue { coord } -> Execute.continue origin ~coord
    | End -> Execute.end_ origin

  let send event =
    let string = event_to_string event in
    Messaging.draw (Draw string)
end

module Erase (* : Stroker with type start_args = unit *) = struct
  type start_args = unit

  let states = Hashtbl.create 10
  let get_state origin = Hashtbl.find_opt states origin |> Option.join
  let set_state origin state = Hashtbl.replace states origin state

  type event = Erase of string list [@@deriving yojson]

  let event_to_string ev = ev |> event_to_yojson |> Yojson.Safe.to_string

  let event_of_string s =
    match Yojson.Safe.from_string s with
    | r -> event_of_yojson r
    | exception Yojson.Json_error e -> Error e

  let event_of_string s =
    match event_of_string s with
    | Ok s -> Some s
    | Error e ->
        Brr.Console.(log [ "Error when converting back an erase event:"; e ]);
        None

  let start () ~id:_ ~coord =
    set_state Self (Some coord);
    None

  let continue ~coord =
    match get_state Self with
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
        set_state Self (Some coord);
        if List.is_empty ids then None else Some (Erase ids)

  let end_ =
    set_state Self None;
    None

  let execute _origin = function
    | Erase [] -> None
    | Erase ids ->
        List.iter
          (fun id ->
            match Hashtbl.find_opt State.Strokes.all id with
            | None -> ()
            | Some (el, _) -> State.Strokes.remove_el el)
          ids;
        Some (Record.Erase (ids, Record.now ()))

  let send event =
    let string = event_to_string event in
    Messaging.draw (Erase string)
end

module Clear = struct
  type start_args = unit
  type event = unit

  let event_of_string _ = Some ()
  let send () = Messaging.draw (Clear "")
  let trigger _start_args = Some ()

  (* let concerned origin who = *)
  (*   match who with All -> true | Origin o when o = origin -> true | _ -> false *)

  let execute (_origin : origin) () =
    Hashtbl.iter
      (fun _ (elem, _) -> State.Strokes.remove_el elem)
      State.Strokes.all;
    Some (Clear (Record.now ()) : Record.event)
end
