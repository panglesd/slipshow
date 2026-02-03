(** Extensions to the Cmarkit AST *)

open Cmarkit

type slide = { content : Block.t; title : Inline.t attributed option }

type s_block =
  | Included of Block.t attributed node
  | Div of Block.t attributed node
  | Slide of slide attributed node
  | Slip of Block.t attributed node
  | SlipScript of Block.Code_block.t attributed node
  | Carousel of Block.t list attributed node
  | MermaidJS of Block.Code_block.t attributed node

type Block.t += S_block of s_block

let included d = S_block (Included d)
let div d = S_block (Div d)
let slide d = S_block (Slide d)
let slip d = S_block (Slip d)
let slipscript d = S_block (SlipScript d)
let mermaid_js d = S_block (MermaidJS d)
let carousel d = S_block (Carousel d)

type media = {
  uri : Asset.Uri.t;
  id : string;
  origin : Cmarkit.Inline.Link.t attributed node;
}

type s_inline =
  | Image of media
  | Svg of media
  | Video of media
  | Audio of media
  | Pdf of media
  | Hand_drawn of media

type Inline.t += S_inline of s_inline

let image i = S_inline (Image i)
let svg i = S_inline (Svg i)
let video i = S_inline (Video i)
let audio i = S_inline (Audio i)
let pdf i = S_inline (Pdf i)
let hand_drawn i = S_inline (Hand_drawn i)

module Files = struct
  type mode = [ `Base64 ]

  type t = {
    path : Fpath.t;
    content : string;
    used_by : string list;
    mode : mode;
  }

  type map = t Fpath.Map.t
end

type t = { doc : Cmarkit.Doc.t; files : Files.map }

module Folder = struct
  let block_ext_default f acc = function
    | Slide (({ content = b; title = Some (title, _) }, _), _) ->
        let acc = Folder.fold_inline f acc title in
        Folder.fold_block f acc b
    | Slide (({ content = b; title = None }, _), _)
    | Div ((b, _), _)
    | Included ((b, _), _)
    | Slip ((b, _), _) ->
        Folder.fold_block f acc b
    | MermaidJS _ | SlipScript _ -> acc
    | Carousel ((l, _), _) ->
        List.fold_left (fun acc x -> Folder.fold_block f acc x) acc l

  let block_ext_default f acc = function
    | S_block b -> block_ext_default f acc b
    | _ -> assert false

  let inline_ext_default f acc = function
    | Pdf { origin = (l, _), _; uri = _; id = _ }
    | Audio { origin = (l, _), _; uri = _; id = _ }
    | Video { origin = (l, _), _; uri = _; id = _ }
    | Hand_drawn { origin = (l, _), _; uri = _; id = _ }
    | Svg { origin = (l, _), _; uri = _; id = _ }
    | Image { origin = (l, _), _; uri = _; id = _ } ->
        Folder.fold_inline f acc (Cmarkit.Inline.Link.text l)

  let inline_ext_default f acc = function
    | S_inline i -> inline_ext_default f acc i
    | _ -> assert false

  let make ~block ~inline () =
    Folder.make ~block_ext_default ~inline_ext_default ~block ~inline ()
end

module Mapper = struct
  let ( let* ) = Option.bind
  let ( let+ ) x f = Option.map f x

  let block_ext_default m = function
    | Div ((b, attrs), meta) ->
        let* b = Mapper.map_block m b in
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        Some (Div ((b, attrs), meta))
    | Included ((b, attrs), meta) ->
        let* b = Mapper.map_block m b in
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        Some (Included ((b, attrs), meta))
    | Slide (({ content = b; title }, attrs), meta) ->
        let* b = Mapper.map_block m b in
        let title =
          let* title, attrs = title in
          let+ inline = Mapper.map_inline m title in
          (inline, (Mapper.map_attrs m (fst attrs), snd attrs))
        in
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        Some (Slide (({ content = b; title }, attrs), meta))
    | Slip ((b, attrs), meta) ->
        let* b = Mapper.map_block m b in
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        Some (Slip ((b, attrs), meta))
    | SlipScript ((s, attrs), meta) ->
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        Some (SlipScript ((s, attrs), meta))
    | MermaidJS ((s, attrs), meta) ->
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        Some (MermaidJS ((s, attrs), meta))
    | Carousel ((l, attrs), meta) -> (
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        List.filter_map (Mapper.map_block m) l |> function
        | [] -> None
        | l -> Some (Carousel ((l, attrs), meta)))

  let block_ext_default m = function
    | S_block b -> block_ext_default m b |> Option.map (fun b -> S_block b)
    | _ -> assert false

  let map_origin m ((l, (attrs, a_meta)), meta) =
    let attrs = Mapper.map_attrs m attrs in
    let text =
      Option.value ~default:Inline.empty
        (Mapper.map_inline m (Cmarkit.Inline.Link.text l))
    in
    let reference = Cmarkit.Inline.Link.reference l in
    let l = Cmarkit.Inline.Link.make text reference in
    ((l, (attrs, a_meta)), meta)

  let map_media m { origin; uri; id } =
    let origin = map_origin m origin in
    { origin; uri; id }

  let inline_ext_default m = function
    | Pdf media ->
        let media = map_media m media in
        Some (Pdf media)
    | Video media ->
        let media = map_media m media in
        Some (Video media)
    | Audio media ->
        let media = map_media m media in
        Some (Audio media)
    | Image media ->
        let media = map_media m media in
        Some (Image media)
    | Svg media ->
        let media = map_media m media in
        Some (Svg media)
    | Hand_drawn media ->
        let media = map_media m media in
        Some (Hand_drawn media)

  let inline_ext_default m = function
    | S_inline i -> inline_ext_default m i |> Option.map (fun i -> S_inline i)
    | _ -> assert false

  let make = Mapper.make ~block_ext_default ~inline_ext_default
end
