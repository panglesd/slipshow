open Types

module Button = struct
  let get suffix =
    Brr.El.find_first_by_selector (Jstr.v (".slip-toolbar-" ^ suffix))
    |> Option.get

  let tool t = get (Tool.to_string t)
  let color c = get (Color.to_string c)

  let width (w : Width.t) =
    let s = function
      | Width.Small -> "small"
      | Medium -> "medium"
      | Large -> "large"
    in
    get (s w)

  let clear () = get "clear"
end

type t = { color : Color.t; width : Width.t; tool : Tool.t } [@@deriving yojson]

let of_string s =
  match Yojson.Safe.from_string s with
  | r -> of_yojson r
  | exception Yojson.Json_error e -> Error e

let of_string s =
  match of_string s with
  | Ok s -> Some s
  | Error e ->
      Brr.Console.(log [ "Error when converting back a state:"; e ]);
      None

let to_string v = v |> to_yojson |> Yojson.Safe.to_string
let color = ref Color.Blue
let width = ref Width.Medium
let tool = ref Tool.Pointer
let get_state () = { color = !color; width = !width; tool = !tool }

type 'a kind =
  | Tool : Tool.t kind
  | Color : Color.t kind
  | Width : Width.t kind

let selected_class (type a) = function
  | (Tool : a kind) -> "slip-set-tool"
  | Width -> "slip-set-width"
  | Color -> "slip-set-color"

let button : type a. a kind -> a -> Brr.El.t = function
  | (Tool : a kind) -> Button.tool
  | Width -> Button.width
  | Color -> Button.color

let state_ref : type a. a kind -> a ref = function
  | (Tool : a kind) -> tool
  | Width -> width
  | Color -> color

let set_current kind e =
  let class_ = Jstr.v (selected_class kind) in
  Brr.El.find_by_class class_ |> List.iter (Brr.El.set_class class_ false);
  Brr.El.set_class class_ true (button kind e);
  state_ref kind := e

let set_color c = set_current Color c
let set_width w = set_current Width w

let make_active () =
  let body = Brr.Document.body Brr.G.document in
  Brr.El.set_class (Jstr.v "slipshow-drawing-mode") true body

let make_inactive () =
  let body = Brr.Document.body Brr.G.document in
  Brr.El.set_class (Jstr.v "slipshow-drawing-mode") false body

let set_tool t =
  let () =
    match t with
    | Tool.Stroker _ | Eraser -> make_active ()
    | Pointer -> make_inactive ()
  in
  set_current Tool t

let get_tool () = !tool

module Strokes = struct
  type t = (string, Brr.El.t * Stroke.t) Hashtbl.t
  (** The ID is the key. We include the element too to avoid having to query for
      it. *)

  let all : t = Hashtbl.create 10

  let remove_id id =
    match Hashtbl.find_opt all id with
    | None -> ()
    | Some (el, _) ->
        Hashtbl.remove all id;
        Brr.El.remove el

  let remove_el elem =
    match Brr.El.at (Jstr.v "id") elem with
    | None -> Brr.El.remove elem
    | Some id ->
        let id = Jstr.to_string id in
        Hashtbl.remove all id;
        Brr.El.remove elem
end

type drawing_state =
  | Drawing of Brr.El.t * Stroke.t * float (* Initial time *)
  | Erasing of (float * float)
  | Pointing

let current_drawing_state = ref Pointing
