open Ast

module Fold_mapper = struct
  type 'a t = {
    block : 'a t -> 'a -> Block.t -> 'a * Block.t;
    inline : 'a t -> 'a -> Inline.t -> 'a * Inline.t;
  }

  let block f acc b =
    match b with
    | ( Block.Blank_line _ | Thematic_break _ | Html_block _ | Math_block _
      | Attribute_definition _ | Standalone_attributes _
      | Link_reference_definition _ | SlipScript _ | MermaidJS _ | Code_block _
        ) as x ->
        (acc, x)
    | Paragraph ((({ inline; _ } as p), attrs), meta) ->
        let acc, inline = f.inline f acc inline in
        (acc, Paragraph (({ p with inline }, attrs), meta))
    | Heading ((({ inline; _ } as h), attrs), meta) ->
        let acc, inline = f.inline f acc inline in
        (acc, Heading (({ h with inline }, attrs), meta))
    | Included ((block, attrs), meta) ->
        let acc, block = f.block f acc block in
        (acc, Included ((block, attrs), meta))
    | Div ((block, attrs), meta) ->
        let acc, block = f.block f acc block in
        (acc, Div ((block, attrs), meta))
    | Slip ((block, attrs), meta) ->
        let acc, block = f.block f acc block in
        (acc, Slip ((block, attrs), meta))
    | Block_quote ((bq, attrs), meta) ->
        let acc, block = f.block f acc bq.block in
        (acc, Block_quote (({ bq with block }, attrs), meta))
    | Slide (({ content; title }, attrs), meta) ->
        let acc, title =
          match title with
          | None -> (acc, None)
          | Some (title, meta) ->
              let acc, title = f.inline f acc title in
              (acc, Some (title, meta))
        in
        let acc, content = f.block f acc content in
        (acc, Slide (({ content; title }, attrs), meta))
    | Carousel ((blocks, attrs), meta) ->
        let acc, l =
          List.fold_left
            (fun (acc, l) b ->
              let acc, b = f.block f acc b in
              (acc, b :: l))
            (acc, []) blocks
        in
        (acc, Carousel ((List.rev l, attrs), meta))
    | Blocks (blocks, meta) ->
        let acc, l =
          List.fold_left
            (fun (acc, l) b ->
              let acc, b = f.block f acc b in
              (acc, b :: l))
            (acc, []) blocks
        in
        (acc, Blocks (List.rev l, meta))
    | List ((lis, attrs), meta) ->
        let acc, items =
          List.fold_left
            (fun (acc, l) (({ Block.List_item.block; _ } as li), meta) ->
              let acc, block = f.block f acc block in
              (acc, ({ li with block }, meta) :: l))
            (acc, []) lis.items
        in
        let items = List.rev items in
        (acc, List (({ lis with items }, attrs), meta))
    | Table ((table, attrs), meta) ->
        let acc, rows =
          List.fold_left
            (fun (acc, l) ((row, attrs), meta) ->
              match row with
              | `Sep _ -> (acc, ((row, attrs), meta) :: l)
              | (`Header lds | `Data lds) as i ->
                  let acc, lds =
                    List.fold_left
                      (fun (acc, l) (inline, meta) ->
                        let acc, inline = f.inline f acc inline in
                        (acc, (inline, meta) :: l))
                      (acc, []) lds
                  in
                  let r x =
                    match i with `Header _ -> `Header x | `Data _ -> `Data x
                  in
                  (acc, ((r (List.rev lds), attrs), meta) :: l))
            (acc, []) table.rows
        in
        let rows = List.rev rows in
        let table = { table with rows } in
        (acc, Table ((table, attrs), meta))

  let inline f acc = function
    | ( Inline.Autolink _ | Break _ | Raw_html _ | Text _ | Math_span _
      | Code_span _ ) as x ->
        (acc, x)
    | Strong_emphasis ((({ inline; _ } as se), attrs), meta) ->
        let acc, inline = f.inline f acc inline in
        (acc, Strong_emphasis (({ se with inline }, attrs), meta))
    | Emphasis ((({ inline; _ } as e), attrs), meta) ->
        let acc, inline = f.inline f acc inline in
        (acc, Emphasis (({ e with inline }, attrs), meta))
    | Strikethrough ((inline, attrs), meta) ->
        let acc, inline = f.inline f acc inline in
        (acc, Strikethrough ((inline, attrs), meta))
    | Attrs_span (({ content; _ } as attrs_span), meta) ->
        let acc, content = f.inline f acc content in
        (acc, Attrs_span ({ attrs_span with content }, meta))
    | Inlines (inlines, meta) ->
        let acc, inlines =
          List.fold_left
            (fun (acc, l) inline ->
              let acc, inline = f.inline f acc inline in
              (acc, inline :: l))
            (acc, []) inlines
        in
        (acc, Inlines (List.rev inlines, meta))
    | Link ((({ text; _ } as media), attrs), meta) ->
        let acc, text = f.inline f acc text in
        (acc, Link (({ media with text }, attrs), meta))
    | Svg ({ origin = (({ text; _ } as link), attrs), meta; _ } as media) ->
        let acc, text = f.inline f acc text in
        let origin = (({ link with text }, attrs), meta) in
        (acc, Svg { media with origin })
    | Video ({ origin = (({ text; _ } as link), attrs), meta; _ } as media) ->
        let acc, text = f.inline f acc text in
        let origin = (({ link with text }, attrs), meta) in
        (acc, Video { media with origin })
    | Pdf ({ origin = (({ text; _ } as link), attrs), meta; _ } as media) ->
        let acc, text = f.inline f acc text in
        let origin = (({ link with text }, attrs), meta) in
        (acc, Pdf { media with origin })
    | Audio ({ origin = (({ text; _ } as link), attrs), meta; _ } as media) ->
        let acc, text = f.inline f acc text in
        let origin = (({ link with text }, attrs), meta) in
        (acc, Audio { media with origin })
    | Hand_drawn ({ origin = (({ text; _ } as link), attrs), meta; _ } as media)
      ->
        let acc, text = f.inline f acc text in
        let origin = (({ link with text }, attrs), meta) in
        (acc, Hand_drawn { media with origin })
    | Image ({ origin = (({ text; _ } as link), attrs), meta; _ } as media) ->
        let acc, text = f.inline f acc text in
        let origin = (({ link with text }, attrs), meta) in
        (acc, Image { media with origin })

  let default = { block; inline }
end

module Folder = struct
  type 'a t = {
    block : 'a t -> 'a -> Block.t -> 'a;
    inline : 'a t -> 'a -> Inline.t -> 'a;
  }

  let block f acc = function
    | Block.Blank_line _ | Thematic_break _ | Html_block _ | Math_block _
    | Attribute_definition _ | Standalone_attributes _
    | Link_reference_definition _ | SlipScript _ | MermaidJS _ | Code_block _ ->
        acc
    | Paragraph (({ inline; _ }, _), _) | Heading (({ inline; _ }, _), _) ->
        f.inline f acc inline
    | Block_quote ((block, _), _) -> f.block f acc block.block
    | Included ((block, _), _) | Div ((block, _), _) | Slip ((block, _), _) ->
        f.block f acc block
    | Slide (({ content; title }, _), _) ->
        let acc =
          match title with
          | None -> acc
          | Some (title, _) -> f.inline f acc title
        in
        f.block f acc content
    | Carousel ((blocks, _), _) | Blocks (blocks, _) ->
        List.fold_left (f.block f) acc blocks
    | List ((lis, _), _) ->
        List.fold_left
          (fun acc ({ Block.List_item.block; _ }, _) -> f.block f acc block)
          acc lis.items
    | Table ((table, _), _) ->
        List.fold_left
          (fun acc ((row, _), _) ->
            match row with
            | `Header lds | `Data lds ->
                List.fold_left
                  (fun acc (inline, _) -> f.inline f acc inline)
                  acc lds
            | `Sep _ -> acc)
          acc table.rows

  let inline f acc = function
    | Inline.Autolink _ | Break _ | Raw_html _ | Text _ | Math_span _
    | Code_span _ ->
        acc
    | Strong_emphasis (({ inline; _ }, _), _)
    | Emphasis (({ inline; _ }, _), _)
    | Strikethrough ((inline, _), _) ->
        f.inline f acc inline
    | Attrs_span ({ content; _ }, _) -> f.inline f acc content
    | Inlines (inlines, _) -> List.fold_left (f.inline f) acc inlines
    | Link (({ text; _ }, _), _)
    | Svg { origin = ({ text; _ }, _), _; _ }
    | Video { origin = ({ text; _ }, _), _; _ }
    | Pdf { origin = ({ text; _ }, _), _; _ }
    | Audio { origin = ({ text; _ }, _), _; _ }
    | Hand_drawn { origin = ({ text; _ }, _), _; _ }
    | Image { origin = ({ text; _ }, _), _; _ } ->
        f.inline f acc text

  let default = { block; inline }
end

module Mapper = struct
  type 'a t = {
    block : 'a t -> Block.t -> Block.t;
    inline : 'a t -> Inline.t -> Inline.t;
  }

  let rec of_fold_mapper f_orig' =
    let block f b =
      let f' = to_fold_mapper f in
      let (), res = f_orig'.Fold_mapper.block f' () b in
      res
    in
    let inline f b =
      let f' = to_fold_mapper f in
      let (), res = f_orig'.Fold_mapper.inline f' () b in
      res
    in
    { block; inline }

  and to_fold_mapper f_orig =
    let block f' () b =
      let f = of_fold_mapper f' in
      ((), f_orig.block f b)
    in
    let inline f' () b =
      let f = of_fold_mapper f' in
      ((), f.inline f b)
    in
    { Fold_mapper.block; inline }

  let default = of_fold_mapper Fold_mapper.default
  (* let ( let* ) = Option.bind *)
  (* let ( let+ ) x f = Option.map f x *)

  (* let block_ext_default m = function *)
  (*   | Div ((b, attrs), meta) -> *)
  (*       let* b = Mapper.map_block m b in *)
  (*       let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in *)
  (*       Some (Div ((b, attrs), meta)) *)
  (*   | Included ((b, attrs), meta) -> *)
  (*       let* b = Mapper.map_block m b in *)
  (*       let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in *)
  (*       Some (Included ((b, attrs), meta)) *)
  (*   | Slide (({ content = b; title }, attrs), meta) -> *)
  (*       let* b = Mapper.map_block m b in *)
  (*       let title = *)
  (*         let* title, attrs = title in *)
  (*         let+ inline = Mapper.map_inline m title in *)
  (*         (inline, (Mapper.map_attrs m (fst attrs), snd attrs)) *)
  (*       in *)
  (*       let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in *)
  (*       Some (Slide (({ content = b; title }, attrs), meta)) *)
  (*   | Slip ((b, attrs), meta) -> *)
  (*       let* b = Mapper.map_block m b in *)
  (*       let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in *)
  (*       Some (Slip ((b, attrs), meta)) *)
  (*   | SlipScript ((s, attrs), meta) -> *)
  (*       let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in *)
  (*       Some (SlipScript ((s, attrs), meta)) *)
  (*   | MermaidJS ((s, attrs), meta) -> *)
  (*       let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in *)
  (*       Some (MermaidJS ((s, attrs), meta)) *)
  (*   | Carousel ((l, attrs), meta) -> ( *)
  (*       let attrs = (Mapper.map_attrs m (fst attrs), snd attrs) in *)
  (*       List.filter_map (Mapper.map_block m) l |> function *)
  (*       | [] -> None *)
  (*       | l -> Some (Carousel ((l, attrs), meta))) *)

  (* let block_ext_default m = function *)
  (*   | S_block b -> block_ext_default m b |> Option.map (fun b -> S_block b) *)
  (*   | _ -> assert false *)

  (* let map_origin m ((l, (attrs, a_meta)), meta) = *)
  (*   let attrs = Mapper.map_attrs m attrs in *)
  (*   let text = *)
  (*     Option.value ~default:Inline.empty *)
  (*       (Mapper.map_inline m (Cmarkit.Inline.Link.text l)) *)
  (*   in *)
  (*   let reference = Cmarkit.Inline.Link.reference l in *)
  (*   let l = Cmarkit.Inline.Link.make text reference in *)
  (*   ((l, (attrs, a_meta)), meta) *)

  (* let map_media m { origin; uri; id } = *)
  (*   let origin = map_origin m origin in *)
  (*   { origin; uri; id } *)

  (* let inline_ext_default m = function *)
  (*   | Pdf media -> *)
  (*       let media = map_media m media in *)
  (*       Some (Pdf media) *)
  (*   | Video media -> *)
  (*       let media = map_media m media in *)
  (*       Some (Video media) *)
  (*   | Audio media -> *)
  (*       let media = map_media m media in *)
  (*       Some (Audio media) *)
  (*   | Image media -> *)
  (*       let media = map_media m media in *)
  (*       Some (Image media) *)
  (*   | Svg media -> *)
  (*       let media = map_media m media in *)
  (*       Some (Svg media) *)
  (*   | Hand_drawn media -> *)
  (*       let media = map_media m media in *)
  (*       Some (Hand_drawn media) *)

  (* let inline_ext_default m = function *)
  (*   | S_inline i -> inline_ext_default m i |> Option.map (fun i -> S_inline i) *)
  (*   | _ -> assert false *)

  (* let make = Mapper.make ~block_ext_default ~inline_ext_default *)
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
      | Standalone_attributes attrs ->
          Some (Standalone_attributes (attr_upd attrs), attrs)
      | Math_block ((mb, attrs), meta) ->
          Some (Math_block ((mb, attr_upd attrs), meta), attrs)
      | Table ((table, attrs), meta) ->
          Some (Table ((table, attr_upd attrs), meta), attrs)
      | Attribute_definition _ -> None
      (* Slipshow nodes *)
      | Included ((inc, attrs), meta) ->
          Some (Included ((inc, attr_upd attrs), meta), attrs)
      | Div ((d, attrs), meta) -> Some (Div ((d, attr_upd attrs), meta), attrs)
      | Slide ((s, attrs), meta) ->
          Some (Slide ((s, attr_upd attrs), meta), attrs)
      | Slip ((s, attrs), meta) -> Some (Slip ((s, attr_upd attrs), meta), attrs)
      | SlipScript ((slscr, attrs), meta) ->
          Some (SlipScript ((slscr, attr_upd attrs), meta), attrs)
      | MermaidJS ((slscr, attrs), meta) ->
          Some (MermaidJS ((slscr, attr_upd attrs), meta), attrs)
      | Carousel ((c, attrs), meta) ->
          Some (Carousel ((c, attr_upd attrs), meta), attrs)

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
      match b with
      | Block.Included (_, meta) -> meta
      | Div (_, meta) -> meta
      | Slide (_, meta) -> meta
      | Slip (_, meta) -> meta
      | SlipScript (_, meta) -> meta
      | Carousel (_, meta) -> meta
      | MermaidJS (_, meta) -> meta
      | Blank_line (_, meta)
      | Block_quote (_, meta)
      | Blocks (_, meta)
      | Code_block (_, meta)
      | Heading (_, meta)
      | Html_block (_, meta)
      | Link_reference_definition (_, meta)
      | Attribute_definition (_, meta)
      | List (_, meta)
      | Paragraph (_, meta)
      | Thematic_break (_, meta)
      | Math_block (_, meta)
      | Table (_, meta) ->
          meta
      | Standalone_attributes (_, meta) -> meta
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
      | Inlines _ -> None
      | Link ((link, attrs), meta) ->
          Some (Link ((link, attr_upd attrs), meta), attrs)
      | Raw_html _ -> None
      | Strong_emphasis ((sem, attrs), meta) ->
          Some (Strong_emphasis ((sem, attr_upd attrs), meta), attrs)
      | Text ((txt, attrs), meta) ->
          Some (Text ((txt, attr_upd attrs), meta), attrs)
      (* Extension Cmarkit nodes *)
      | Strikethrough ((strk, attrs), meta) ->
          Some (Strikethrough ((strk, attr_upd attrs), meta), attrs)
      | Math_span ((ms, attrs), meta) ->
          Some (Math_span ((ms, attr_upd attrs), meta), attrs)
      | Attrs_span ({ content; attrs }, meta) ->
          Some (Attrs_span ({ content; attrs = attr_upd attrs }, meta), attrs)
      (* Slipshow nodes *)
      | Hand_drawn m ->
          let (link, attrs), meta = m.origin in
          let origin = ((link, attr_upd attrs), meta) in
          Some (Hand_drawn { m with origin }, attrs)
      | Image m ->
          let (link, attrs), meta = m.origin in
          let origin = ((link, attr_upd attrs), meta) in
          Some (Image { m with origin }, attrs)
      | Svg m ->
          let (link, attrs), meta = m.origin in
          let origin = ((link, attr_upd attrs), meta) in
          Some (Svg { m with origin }, attrs)
      | Video m ->
          let (link, attrs), meta = m.origin in
          let origin = ((link, attr_upd attrs), meta) in
          Some (Video { m with origin }, attrs)
      | Audio m ->
          let (link, attrs), meta = m.origin in
          let origin = ((link, attr_upd attrs), meta) in
          Some (Audio { m with origin }, attrs)
      | Pdf m ->
          let (link, attrs), meta = m.origin in
          let origin = ((link, attr_upd attrs), meta) in
          Some (Pdf { m with origin }, attrs)

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
      match i with
      | Inline.Autolink (_, meta)
      | Break (_, meta)
      | Code_span (_, meta)
      | Emphasis (_, meta)
      | Inlines (_, meta)
      | Link (_, meta)
      | Raw_html (_, meta)
      | Strong_emphasis (_, meta)
      | Text (_, meta)
      | Strikethrough (_, meta)
      | Math_span (_, meta)
      | Attrs_span (_, meta)
      | Image { origin = _, meta; _ }
      | Svg { origin = _, meta; _ }
      | Video { origin = _, meta; _ }
      | Audio { origin = _, meta; _ }
      | Pdf { origin = _, meta; _ }
      | Hand_drawn { origin = _, meta; _ } ->
          meta
  end
end

module Bol = struct
  type t = [ `Block of Block.t | `Inline of Inline.t ]

  let text_loc (bol : t) =
    match bol with
    | `Block b -> b |> Utils.Block.meta |> Meta.textloc
    | `Inline i -> i |> Utils.Inline.meta |> Meta.textloc
end
