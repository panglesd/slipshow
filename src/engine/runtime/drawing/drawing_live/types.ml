module V1 = struct
  module Color = struct
    type t = Red | Blue | Green | Black | Yellow [@@deriving yojson]

    let to_string = function
      | Red -> "red"
      | Blue -> "blue"
      | Green -> "green"
      | Black -> "black"
      | Yellow -> "yellow"

    let all = [ Red; Blue; Green; Black; Yellow ]

    let of_string = function
      | "red" -> Red
      | "blue" -> Blue
      | "green" -> Green
      | "black" -> Black
      | "yellow" -> Yellow
      | _ -> Blue (* TODO: decide if we need to warn user? *)
  end

  module Width = struct
    type t = Small | Medium | Large [@@deriving yojson]
  end

  module Tool = struct
    type stroker = Pen | Highlighter [@@deriving yojson]

    type t = Stroker of stroker | Eraser | Pointer | Select | Move
    [@@deriving yojson]

    let to_string = function
      | Stroker Pen -> "pen"
      | Stroker Highlighter -> "highlighter"
      | Eraser -> "eraser"
      | Pointer -> "cursor"
      | Select -> "select"
      | Move -> "move"
  end

  module Stroke = struct
    type freehand_option = {
      size : float option;
      thinning : float option;
      smoothing : float option;
      streamline : float option;
      last : bool option;
    }
    [@@deriving yojson]

    let option_to_yojson v =
      let option =
        {
          size = Perfect_freehand.Options.size v;
          thinning = Perfect_freehand.Options.thinning v;
          smoothing = Perfect_freehand.Options.smoothing v;
          streamline = Perfect_freehand.Options.streamline v;
          last = Perfect_freehand.Options.last v;
        }
      in
      freehand_option_to_yojson option

    let option_of_yojson yojson =
      match freehand_option_of_yojson yojson with
      | Ok { size; thinning; smoothing; streamline; last } ->
          Ok
            (Perfect_freehand.Options.v ?size ?thinning ?smoothing ?streamline
               ?last ())
      | Error _ as e -> e

    type t = {
      id : string;
      scale : float;
      path : (float * float) list;
      color : Color.t;
      opacity : float;
      options : Perfect_freehand.Options.t;
          [@to_yojson option_to_yojson] [@of_yojson option_of_yojson]
    }
    [@@deriving yojson]

    let of_string s =
      match Yojson.Safe.from_string s with
      | r -> of_yojson r
      | exception Yojson.Json_error e -> Error e

    let of_string s =
      match of_string s with
      | Ok s -> Some s
      | Error e ->
          Brr.Console.(log [ "Error when converting back a stroke:"; e ]);
          None

    let to_string v = v |> to_yojson |> Yojson.Safe.to_string
  end
end

include V1

type origin = Self | Record of int | Sent of string [@@deriving yojson]

let origin_to_string v = v |> origin_to_yojson |> Yojson.Safe.to_string

let origin_of_string v =
  match Yojson.Safe.from_string v with
  | json -> (
      origin_of_yojson json |> function Ok s -> Some s | Error _ -> None)
  | exception Yojson.Json_error _ -> None

module Draw_event = struct
  type t =
    | End
    | Start of { id : string; state : string; coord : float * float }
    | Continue of { coord : float * float }
    | Clear
  (* [@@deriving sexp] *)
end
