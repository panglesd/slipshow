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
  uri : Asset.Uri.t node;
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

  let continue_block f c acc =
    let open Block in
    match c with
    | Blank_line _ | Code_block _ | Html_block _ | Ext_standalone_attributes _
    | Link_reference_definition _ | Thematic_break _ | Ext_math_block _
    | Ext_attribute_definition _ ->
        acc
    | Heading ((h, _attrs), _) ->
        Folder.fold_inline f acc (Block.Heading.inline h)
    | Block_quote ((bq, _attrs), _) ->
        Folder.fold_block f acc (Cmarkit.Block.Block_quote.block bq)
    | Blocks (bs, _) -> List.fold_left (Folder.fold_block f) acc bs
    | List ((l, _attrs), _) ->
        let fold_list_item m acc (i, _) =
          Folder.fold_block m acc (Block.List_item.block i)
        in
        List.fold_left (fold_list_item f) acc (List'.items l)
    | Paragraph ((p, _attrs), _) ->
        Folder.fold_inline f acc (Block.Paragraph.inline p)
    | Ext_table ((t, _attrs), _) ->
        let fold_row acc ((r, _), _) =
          match r with
          | `Header is | `Data is ->
              List.fold_left
                (fun acc (i, _) -> Folder.fold_inline f acc i)
                acc is
          | `Sep _ -> acc
        in
        List.fold_left fold_row acc (Table.rows t)
    | Ext_footnote_definition ((_fn, _attrs), _) -> acc (* TODO: do *)
    | S_block b -> (
        match b with
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
            List.fold_left (fun acc x -> Folder.fold_block f acc x) acc l)
    | _ -> assert false

  let continue_inline f i acc =
    let open Inline in
    match i with
    | Autolink _ | Break _ | Code_span _ | Raw_html _ | Text _ | Ext_math_span _
      ->
        acc
    | Image ((l, _), _) | Link ((l, _), _) ->
        let text = Link.text l in
        Folder.fold_inline f acc text
    | Ext_attrs (attrs, _) ->
        let inline = Attributes_span.content attrs in
        Folder.fold_inline f acc inline
    | Emphasis ((e, _), _) ->
        let inline = Emphasis.inline e in
        Folder.fold_inline f acc inline
    | Strong_emphasis ((e, _), _) ->
        let inline = Emphasis.inline e in
        Folder.fold_inline f acc inline
    | Inlines (is, _) -> List.fold_left (Folder.fold_inline f) acc is
    | Ext_strikethrough ((inline, _), _) ->
        let inline = Strikethrough.inline inline in
        Folder.fold_inline f acc inline
    | S_inline ext -> (
        match ext with
        | Hand_drawn m | Image m | Svg m | Video m | Audio m | Pdf m ->
            let (link, _), _ = m.origin in
            let inline = Link.text link in
            Folder.fold_inline f acc inline)
    | _ -> assert false
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

module Fold_mapper = struct
  let ( $ ) f (x, meta) =
    let acc, res = f x in
    (acc, (res, meta))

  let map_origin (m : 'a Fold_mapper.t) acc ((l, attrs), meta) =
    let acc, attrs = m.attrs acc $ attrs in
    let acc, text = m.inline m acc (Cmarkit.Inline.Link.text l) in
    let text = Option.value ~default:Cmarkit.Inline.empty text in
    let reference = Cmarkit.Inline.Link.reference l in
    let l = Cmarkit.Inline.Link.make text reference in
    (acc, ((l, attrs), meta))

  let map_media m acc { origin; uri; id } =
    let acc, origin = map_origin m acc origin in
    (acc, { origin; uri; id })

  let block (m : 'a Fold_mapper.t) acc = function
    | S_block b ->
        let acc, b =
          match b with
          | Included ((block, attrs), meta) ->
              let acc, attrs = m.attrs acc $ attrs in
              let acc, block = m.block m acc block in
              let res =
                Option.map (fun block -> Included ((block, attrs), meta)) block
              in
              (acc, res)
          | Div ((block, attrs), meta) ->
              let acc, attrs = m.attrs acc $ attrs in
              let acc, block = m.block m acc block in
              let res =
                Option.map (fun block -> Div ((block, attrs), meta)) block
              in
              (acc, res)
          | Slide (({ content; title }, attrs), meta) ->
              let acc, attrs = m.attrs acc $ attrs in
              let acc, content = m.block m acc content in
              let acc, title =
                match title with
                | None -> (acc, None)
                | Some (title, t_attrs) ->
                    let acc, t_attrs = m.attrs acc $ t_attrs in
                    let acc, title = m.inline m acc title in
                    let title =
                      Option.map (fun title -> (title, t_attrs)) title
                    in
                    (acc, title)
              in
              let res =
                Option.map
                  (fun content -> Slide (({ content; title }, attrs), meta))
                  content
              in
              (acc, res)
          | Slip ((block, attrs), meta) ->
              let acc, attrs = m.attrs acc $ attrs in
              let acc, block = m.block m acc block in
              let res =
                Option.map (fun block -> Slip ((block, attrs), meta)) block
              in
              (acc, res)
          | SlipScript ((s, attrs), meta) ->
              let acc, attrs = m.attrs acc $ attrs in
              (acc, Some (SlipScript ((s, attrs), meta)))
          | MermaidJS ((s, attrs), meta) ->
              let acc, attrs = m.attrs acc $ attrs in
              (acc, Some (MermaidJS ((s, attrs), meta)))
          | Carousel ((bs, attrs), meta) -> (
              let acc, attrs = m.attrs acc $ attrs in
              let acc, bs = List.fold_left_map (m.block m) acc bs in
              match List.filter_map Fun.id bs with
              | [] -> (acc, None)
              | bs -> (acc, Some (Carousel ((bs, attrs), meta))))
        in
        let res = Option.map (fun b -> S_block b) b in
        (acc, res)
    | normal -> Fold_mapper.default.block m acc normal

  let inline (m : 'a Fold_mapper.t) acc = function
    | S_inline i ->
        let acc, i =
          match i with
          | Image media ->
              let acc, media = map_media m acc media in
              (acc, Image media)
          | Svg media ->
              let acc, media = map_media m acc media in
              (acc, Svg media)
          | Video media ->
              let acc, media = map_media m acc media in
              (acc, Video media)
          | Audio media ->
              let acc, media = map_media m acc media in
              (acc, Audio media)
          | Pdf media ->
              let acc, media = map_media m acc media in
              (acc, Pdf media)
          | Hand_drawn media ->
              let acc, media = map_media m acc media in
              (acc, Hand_drawn media)
        in
        (acc, Some (S_inline i))
    | normal -> Fold_mapper.default.inline m acc normal

  let default = { Fold_mapper.default with block; inline }

  let make ?(block = block) ?(inline = inline) ?attrs () =
    Fold_mapper.make ~block ~inline ?attrs ()
end

module Utils = struct
  module Block = struct
    (** Get the attributes of a cmarkit node, returns them and the element
        stripped of its attributes *)
    let update_attribute :
        (Attributes.t node -> Attributes.t node) ->
        Block.t ->
        (Block.t * Attributes.t node) option =
     fun attr_upd ->
      let open Block in
      function
      (* Standard Cmarkit nodes *)
      | Blank_line _ | Blocks _ -> None
      | Block_quote ((bq, attrs), meta) ->
          Some (Block_quote ((bq, attr_upd attrs), meta), attrs)
      | Code_block ((cb, attrs), meta) ->
          Some (Code_block ((cb, attr_upd attrs), meta), attrs)
      | Heading ((h, attrs), meta) ->
          Some (Heading ((h, attr_upd attrs), meta), attrs)
      | Html_block ((hb, attrs), meta) ->
          Some (Html_block ((hb, attr_upd attrs), meta), attrs)
      | Link_reference_definition _ -> None
      | List ((l, attrs), meta) -> Some (List ((l, attr_upd attrs), meta), attrs)
      | Paragraph ((p, attrs), meta) ->
          Some (Paragraph ((p, attr_upd attrs), meta), attrs)
      | Thematic_break ((tb, attrs), meta) ->
          Some (Thematic_break ((tb, attr_upd attrs), meta), attrs)
      (* Extension Cmarkit nodes *)
      | Ext_standalone_attributes attrs ->
          Some (Ext_standalone_attributes (attr_upd attrs), attrs)
      | Ext_math_block ((mb, attrs), meta) ->
          Some (Ext_math_block ((mb, attr_upd attrs), meta), attrs)
      | Ext_table ((table, attrs), meta) ->
          Some (Ext_table ((table, attr_upd attrs), meta), attrs)
      | Ext_footnote_definition _ | Ext_attribute_definition _ -> None
      (* Slipshow nodes *)
      | S_block b -> (
          match b with
          | Included ((inc, attrs), meta) ->
              Some (included ((inc, attr_upd attrs), meta), attrs)
          | Div ((d, attrs), meta) ->
              Some (div ((d, attr_upd attrs), meta), attrs)
          | Slide ((s, attrs), meta) ->
              Some (slide ((s, attr_upd attrs), meta), attrs)
          | Slip ((s, attrs), meta) ->
              Some (slip ((s, attr_upd attrs), meta), attrs)
          | SlipScript ((slscr, attrs), meta) ->
              Some (slipscript ((slscr, attr_upd attrs), meta), attrs)
          | MermaidJS ((slscr, attrs), meta) ->
              Some (mermaid_js ((slscr, attr_upd attrs), meta), attrs)
          | Carousel ((c, attrs), meta) ->
              Some (carousel ((c, attr_upd attrs), meta), attrs))
      | _ -> None

    (** Get the attributes of a cmarkit node, returns them and the element
        stripped of its attributes *)
    let get_attribute b =
      let no_attrs = (Attributes.empty, Meta.none) in
      let attr_upd _ = no_attrs in
      update_attribute attr_upd b

    (** Get the attributes of a cmarkit node, returns them and the element
        stripped of its attributes *)
    let merge_attribute new_attrs b =
      let merge (base, meta) =
        (Attributes.merge ~base ~new_attrs, meta)
        (* Old attributes take precendence over "new" one *)
      in
      match update_attribute merge b with None -> b | Some (b, _) -> b

    let meta b =
      let ext b =
        match b with
        | S_block b -> (
            match b with
            | Included (_, meta) -> meta
            | Div (_, meta) -> meta
            | Slide (_, meta) -> meta
            | Slip (_, meta) -> meta
            | SlipScript (_, meta) -> meta
            | Carousel (_, meta) -> meta
            | MermaidJS (_, meta) -> meta)
        | _ -> assert false
      in
      Block.meta ~ext b
  end

  module Inline = struct
    (** Get the attributes of a cmarkit node, returns them and the element
        stripped of its attributes *)
    let update_attribute :
        (Attributes.t node -> Attributes.t node) ->
        Inline.t ->
        (Inline.t * Attributes.t node) option =
     fun attr_upd ->
      let open Inline in
      function
      (* Standard Cmarkit nodes *)
      | Autolink ((al, attrs), meta) ->
          Some (Autolink ((al, attr_upd attrs), meta), attrs)
      | Break _ -> None
      | Code_span ((cs, attrs), meta) ->
          Some (Code_span ((cs, attr_upd attrs), meta), attrs)
      | Emphasis ((em, attrs), meta) ->
          Some (Emphasis ((em, attr_upd attrs), meta), attrs)
      | Image ((im, attrs), meta) ->
          Some (Image ((im, attr_upd attrs), meta), attrs)
      | Inlines _ -> None
      | Link ((link, attrs), meta) ->
          Some (Link ((link, attr_upd attrs), meta), attrs)
      | Raw_html _ -> None
      | Strong_emphasis ((sem, attrs), meta) ->
          Some (Strong_emphasis ((sem, attr_upd attrs), meta), attrs)
      | Text ((txt, attrs), meta) ->
          Some (Text ((txt, attr_upd attrs), meta), attrs)
      (* Extension Cmarkit nodes *)
      | Ext_strikethrough ((strk, attrs), meta) ->
          Some (Ext_strikethrough ((strk, attr_upd attrs), meta), attrs)
      | Ext_math_span ((ms, attrs), meta) ->
          Some (Ext_math_span ((ms, attr_upd attrs), meta), attrs)
      | Ext_attrs (attr_span, meta) ->
          let inline = Attributes_span.content attr_span in
          let attrs = Attributes_span.attrs attr_span in
          Some
            ( Ext_attrs (Attributes_span.make inline (attr_upd attrs), meta),
              attrs )
      (* Slipshow nodes *)
      | S_inline i -> (
          match i with
          | Hand_drawn m ->
              let (link, attrs), meta = m.origin in
              let origin = ((link, attr_upd attrs), meta) in
              Some (S_inline (Hand_drawn { m with origin }), attrs)
          | Image m ->
              let (link, attrs), meta = m.origin in
              let origin = ((link, attr_upd attrs), meta) in
              Some (S_inline (Image { m with origin }), attrs)
          | Svg m ->
              let (link, attrs), meta = m.origin in
              let origin = ((link, attr_upd attrs), meta) in
              Some (S_inline (Svg { m with origin }), attrs)
          | Video m ->
              let (link, attrs), meta = m.origin in
              let origin = ((link, attr_upd attrs), meta) in
              Some (S_inline (Video { m with origin }), attrs)
          | Audio m ->
              let (link, attrs), meta = m.origin in
              let origin = ((link, attr_upd attrs), meta) in
              Some (S_inline (Audio { m with origin }), attrs)
          | Pdf m ->
              let (link, attrs), meta = m.origin in
              let origin = ((link, attr_upd attrs), meta) in
              Some (S_inline (Pdf { m with origin }), attrs))
      | _ -> None

    (** Get the attributes of a cmarkit node, returns them and the element
        stripped of its attributes *)
    let get_attribute b =
      let no_attrs = (Attributes.empty, Meta.none) in
      let attr_upd _ = no_attrs in
      update_attribute attr_upd b

    (** Get the attributes of a cmarkit node, returns them and the element
        stripped of its attributes *)
    let merge_attribute new_attrs b =
      let merge (base, meta) =
        (Attributes.merge ~base ~new_attrs, meta)
        (* Old attributes take precendence over "new" one *)
      in
      match update_attribute merge b with None -> b | Some (b, _) -> b

    let meta i =
      let ext i =
        match i with
        | S_inline i -> (
            match i with
            | Image { origin = _, meta; _ } -> meta
            | Svg { origin = _, meta; _ } -> meta
            | Video { origin = _, meta; _ } -> meta
            | Audio { origin = _, meta; _ } -> meta
            | Pdf { origin = _, meta; _ } -> meta
            | Hand_drawn { origin = _, meta; _ } -> meta)
        | _ -> assert false
      in
      Inline.meta ~ext i
  end
end

module Bol = struct
  type t = [ `Block of Block.t | `Inline of Inline.t ]

  let text_loc (bol : t) =
    match bol with
    | `Block b -> b |> Utils.Block.meta |> Meta.textloc
    | `Inline i -> i |> Utils.Inline.meta |> Meta.textloc
end
