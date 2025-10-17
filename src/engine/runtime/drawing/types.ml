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
    type t = Stroker of stroker | Eraser | Pointer [@@deriving yojson]

    let to_string = function
      | Stroker Pen -> "pen"
      | Stroker Highlighter -> "highlighter"
      | Eraser -> "eraser"
      | Pointer -> "cursor"
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
      path : ((float * float) * float) list (* TODO: (position * time) list *);
      end_at : float;
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
