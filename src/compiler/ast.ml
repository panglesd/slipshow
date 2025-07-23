(** Extensions to the Cmarkit AST *)

open Cmarkit

type slide = { content : Block.t; title : Inline.t attributed option }

type Block.t +=
  | Included of Block.t attributed node
  | Div of Block.t attributed node
  | Slide of slide attributed node
  | Slip of Block.t attributed node
  | SlipScript of Block.Code_block.t attributed node
  | Carousel of Block.t list attributed node

type media = {
  uri : Asset.Uri.t;
  id : string;
  origin : Cmarkit.Inline.Link.t attributed node;
}

type Inline.t += Image of media | Video of media | Audio of media

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
    | SlipScript _ -> acc
    | Carousel ((l, _), _) ->
        List.fold_left (fun acc x -> Folder.fold_block f acc x) acc l
    | _ -> assert false

  let inline_ext_default f acc = function
    | Audio { origin = (l, _), _; uri = _; id = _ }
    | Video { origin = (l, _), _; uri = _; id = _ }
    | Image { origin = (l, _), _; uri = _; id = _ } ->
        Folder.fold_inline f acc (Cmarkit.Inline.Link.text l)
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
    | Carousel ((l, attrs), meta) -> (
        let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in
        List.filter_map (Mapper.map_block m) l |> function
        | [] -> None
        | l -> Some (Carousel ((l, attrs), meta)))
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
    | Video media ->
        let media = map_media m media in
        Some (Video media)
    | Audio media ->
        let media = map_media m media in
        Some (Audio media)
    | Image media ->
        let media = map_media m media in
        Some (Image media)
    | _ -> assert false

  let make = Mapper.make ~block_ext_default ~inline_ext_default
end
