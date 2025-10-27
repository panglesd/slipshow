open Types

type draw_start_args = {
  stroker : Types.Tool.stroker;
  width : Width.t;
  color : Color.t;
}
[@@deriving yojson]

module Draw = struct
  type start_args = draw_start_args [@@deriving yojson]

  module V1 = struct
    type event =
      | Start of { start_args : start_args; id : string; coord : float * float }
      | Continue of { coord : float * float; id : string }
      | End of { id : string }
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
  end

  include V1

  let state : string option ref = ref None

  let start start_args ~id ~coord =
    state := Some id;
    Some (Start { start_args; id; coord })

  let continue ~coord =
    match !state with None -> None | Some id -> Some (Continue { coord; id })

  let end_ () =
    match !state with
    | None -> None
    | Some id ->
        state := None;
        Some (End { id })

  let states : (string, (Brr.El.t * Stroke.t) option) Hashtbl.t =
    Hashtbl.create 10

  let get_state id = Hashtbl.find_opt states id |> Option.join
  let set_state id state = Hashtbl.replace states id state

  let svg =
    Brr.El.find_first_by_selector (Jstr.v "#slipshow-drawing-elem")
    |> Option.get

  module Execute = struct
    let start _origin stroker ~id ~coord ~color ~width =
      let opacity = match stroker with Tool.Highlighter -> 0.33 | Pen -> 1. in
      let path = [ coord ] in
      let options = Strokes.options_of stroker width in
      let { Universe.Coordinates.scale; _ } = Universe.State.get_coord () in
      let stroke = { Stroke.path; options; opacity; id; color; scale } in
      let p = Strokes.create_elem_of_stroke stroke in
      Brr.El.append_children svg [ p ];
      set_state id (Some (p, stroke))

    let continue _origin ~coord ~id =
      match get_state id with
      | None -> ()
      | Some (el, stroke) ->
          let stroke = { stroke with Stroke.path = coord :: stroke.path } in
          Brr.El.set_at (Jstr.v "d")
            (Some
               (Jstr.v
                  (Strokes.svg_path stroke.options stroke.scale stroke.path)))
            el;
          set_state id (Some (el, stroke))

    let end_ origin ~id =
      match get_state id with
      | None -> ()
      | Some (element, stroke) ->
          set_state id None;
          Hashtbl.add State.Strokes.all stroke.id { element; origin; stroke }
  end

  let execute origin = function
    | Start { start_args = { stroker; width; color }; id; coord } ->
        Execute.start origin stroker ~id ~coord ~color ~width
    | Continue { coord; id } -> Execute.continue origin ~coord ~id
    | End { id } -> Execute.end_ origin ~id

  let send event =
    let string = event_to_string event in
    Messaging.draw (Draw string)

  let coerce_event x = `Draw x
end

module Erase = struct
  type start_args = unit

  let states = Hashtbl.create 10
  let get_state origin = Hashtbl.find_opt states origin |> Option.join
  let set_state origin state = Hashtbl.replace states origin state

  module V1 = struct
    type event = Erase of (string * origin) list [@@deriving yojson]

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
  end

  include V1

  let start () ~id:_ ~coord =
    set_state Self (Some coord);
    None

  let continue ~coord =
    match get_state Self with
    | None -> None
    | Some last_point ->
        let self_origin = State.get_origin () in
        let ids =
          Hashtbl.fold
            (fun id { State.Strokes.stroke = { Stroke.path; _ }; origin; _ } acc
               ->
              if origin = self_origin then
                let intersect = Utils.intersect_poly path (coord, last_point) in
                let close_enough = Utils.close_enough_poly path coord in
                if intersect || close_enough then (id, origin) :: acc else acc
              else acc)
            State.Strokes.all []
        in
        set_state Self (Some coord);
        if List.is_empty ids then None else Some (Erase ids)

  let end_ () =
    set_state Self None;
    None

  let execute self_origin = function
    | Erase [] -> ()
    | Erase ids ->
        let ids =
          List.filter_map
            (fun (id, origin) -> if origin = self_origin then Some id else None)
            ids
        in
        List.iter
          (fun id ->
            match Hashtbl.find_opt State.Strokes.all id with
            | None -> ()
            | Some { element; _ } -> State.Strokes.remove_el element)
          ids

  let send event =
    let string = event_to_string event in
    Messaging.draw (Erase string)

  let coerce_event x = `Erase x
end

module Clear = struct
  type start_args = unit

  module V1 = struct
    type event = unit [@@deriving yojson]

    let event_of_string _ = Some ()
  end

  include V1

  let send () = Messaging.draw (Clear "")
  let trigger _start_args = Some ()

  (* let concerned origin who = *)
  (*   match who with All -> true | Origin o when o = origin -> true | _ -> false *)

  let execute (self_origin : origin) () =
    let _ids =
      Hashtbl.fold
        (fun id { State.Strokes.origin; _ } acc ->
          if origin = self_origin then (
            State.Strokes.remove_id id;
            id :: acc)
          else acc)
        State.Strokes.all []
    in
    ()
  (* TODO: turn fold back into iter *)
  (* Some (Erase ids (\* , Record.now () *\) (\* : Record.event *\)) *)

  let coerce_event x = `Clear x
end

type event =
  [ `Draw of Draw.event | `Erase of Erase.event | `Clear of Clear.event ]

module type Tool = sig
  type tool_event := event

  module V1 : sig
    type event [@@deriving yojson]

    val event_of_string : string -> event option
  end

  include module type of V1

  val coerce_event : event -> tool_event
  val execute : origin -> event -> unit
  val send : event -> unit
end

module type Stroker = sig
  type start_args

  include Tool

  val start : start_args -> id:string -> coord:float * float -> event option
  val continue : coord:float * float -> event option
  val end_ : unit -> event option
end

(* Just checking signatures *)
module _ : Stroker = Draw
module _ : Tool = Draw
module _ : Stroker = Erase
module _ : Tool = Erase
module _ : Tool = Clear
