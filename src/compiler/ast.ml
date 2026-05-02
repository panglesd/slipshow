(** Extensions to the Cmarkit AST *)

open Cmarkit
module Layout = Layout

type nonrec 'a node = 'a node
type nonrec 'a attributed = 'a attributed

module Meta = Meta
module Attributes = Attributes

module Inline = struct
  module Autolink = Inline.Autolink
  module Break = Inline.Break
  module Code_span = Inline.Code_span
  module Math_span = Inline.Math_span
  module Raw_html = Inline.Raw_html
  module Text = Inline.Text

  module rec Emphasis : sig
    type inline = T.t
    type t = { delim : Layout.char; inline : inline }
  end =
    Emphasis

  and Link : sig
    type inline = T.t
    type reference_layout = [ `Collapsed | `Full | `Shortcut ]

    type reference =
      [ `Inline of Link_definition.t attributed node
      | `Ref of reference_layout * Label.t * Label.t ]

    type t = { text : inline; reference : reference }

    val reference_definition : Label.defs -> t -> Label.def option
    val referenced_label : t -> Label.t option
  end = struct
    include Link

    let reference_definition defs l =
      match l.reference with
      | `Inline ld -> Some (Link_definition.Def ld)
      | `Ref (_, _, def) -> Label.Map.find_opt (Label.key def) defs

    let referenced_label l =
      match l.reference with `Inline _ -> None | `Ref (_, _, k) -> Some k
  end

  and Strikethrough : sig
    type t = T.t
  end =
    Strikethrough

  and Attributes_span : sig
    type t = { content : T.t; attrs : Attributes.t node }
  end =
    Attributes_span

  and Media : sig
    type t = {
      uri : Asset.Uri.t node;
      id : string;
      origin : Link.t attributed node;
    }
  end =
    Media

  and T : sig
    type t =
      | Strikethrough of Strikethrough.t attributed node
      | Math_span of Math_span.t attributed node
      | Attrs_span of Attributes_span.t node
      | Autolink of Autolink.t attributed node
      | Break of Break.t node
      | Code_span of Code_span.t attributed node
      | Emphasis of Emphasis.t attributed node
      | Inlines of t list node
      | Link of Link.t attributed node
      | Raw_html of Raw_html.t node
      | Strong_emphasis of Emphasis.t attributed node
      | Text of Text.t attributed node
      | Image of Media.t
      | Svg of Media.t
      | Video of Media.t
      | Audio of Media.t
      | Pdf of Media.t
      | Hand_drawn of Media.t
  end =
    T

  include T

  let to_plain_text ~break_on_soft (i : t) =
    let push s acc = (s :: List.hd acc) :: List.tl acc in
    let newline acc = [] :: List.rev (List.hd acc) :: List.tl acc in
    let rec loop ~break_on_soft acc = function
      | T.Autolink ((a, _), _) :: is ->
          let acc =
            push (String.concat "" [ "<"; fst (Autolink.link a); ">" ]) acc
          in
          loop ~break_on_soft acc is
      | Break (break, _) :: is when Break.type' break = `Hard ->
          loop ~break_on_soft (newline acc) is
      | Break (_, _) :: is ->
          let acc = if break_on_soft then newline acc else push " " acc in
          loop ~break_on_soft acc is
      | Code_span ((cs, _), _) :: is ->
          loop ~break_on_soft (push (Code_span.code cs) acc) is
      | Emphasis (({ inline; _ }, _), _) :: is
      | Strong_emphasis (({ inline; _ }, _), _) :: is ->
          loop ~break_on_soft acc (inline :: is)
      | Inlines (is', _) :: is ->
          loop ~break_on_soft acc (List.rev_append (List.rev is') is)
      | Link ((l, _), _) :: is -> loop ~break_on_soft acc (l.text :: is)
      | Raw_html _ :: is -> loop ~break_on_soft acc is
      | Text ((t, _), _) :: is -> loop ~break_on_soft (push t acc) is
      | Strikethrough ((i, _), _) :: is -> loop ~break_on_soft acc (i :: is)
      | Math_span ((m, _), _) :: is ->
          loop ~break_on_soft (push (Math_span.tex m) acc) is
      | Attrs_span _ :: is -> loop ~break_on_soft acc is
      | (Image _ | Svg _ | Video _ | Audio _ | Pdf _ | Hand_drawn _) :: is ->
          loop ~break_on_soft acc is
      | [] -> List.rev (List.rev (List.hd acc) :: List.tl acc)
    in
    loop ~break_on_soft ([] :: []) [ i ]

  let map_attrs f (i : t) =
    match i with
    | Strikethrough ((st, attrs), meta) -> Strikethrough ((st, f attrs), meta)
    | Math_span ((ms, attrs), meta) -> Math_span ((ms, f attrs), meta)
    | Attrs_span ({ content; attrs }, meta) ->
        Attrs_span ({ content; attrs = f attrs }, meta)
    | Autolink ((al, attrs), meta) -> Autolink ((al, f attrs), meta)
    | Break _ as br -> br
    | Code_span ((cs, attrs), meta) -> Code_span ((cs, f attrs), meta)
    | Emphasis ((em, attrs), meta) -> Emphasis ((em, f attrs), meta)
    | Inlines _ as is -> is
    | Link ((l, attrs), meta) -> Link ((l, f attrs), meta)
    | Raw_html _ as html -> html
    | Strong_emphasis ((sem, attrs), meta) ->
        Strong_emphasis ((sem, f attrs), meta)
    | Text ((text, attrs), meta) -> Text ((text, f attrs), meta)
    | Image { uri; id; origin = (l, attrs), meta } ->
        Image { uri; id; origin = ((l, f attrs), meta) }
    | Svg { uri; id; origin = (l, attrs), meta } ->
        Svg { uri; id; origin = ((l, f attrs), meta) }
    | Video { uri; id; origin = (l, attrs), meta } ->
        Video { uri; id; origin = ((l, f attrs), meta) }
    | Audio { uri; id; origin = (l, attrs), meta } ->
        Audio { uri; id; origin = ((l, f attrs), meta) }
    | Pdf { uri; id; origin = (l, attrs), meta } ->
        Pdf { uri; id; origin = ((l, f attrs), meta) }
    | Hand_drawn { uri; id; origin = (l, attrs), meta } ->
        Hand_drawn { uri; id; origin = ((l, f attrs), meta) }

  let get_attrs (i : t) =
    match i with
    | Strikethrough ((_, attrs), _) -> Some attrs
    | Math_span ((_, attrs), _) -> Some attrs
    | Attrs_span ({ content = _; attrs }, _) -> Some attrs
    | Autolink ((_, attrs), _) -> Some attrs
    | Break _ -> None
    | Code_span ((_, attrs), _) -> Some attrs
    | Emphasis ((_, attrs), _) -> Some attrs
    | Inlines _ -> None
    | Link ((_, attrs), _) -> Some attrs
    | Raw_html _ -> None
    | Strong_emphasis ((_, attrs), _) -> Some attrs
    | Text ((_, attrs), _) -> Some attrs
    | Image { origin = (_, attrs), _; _ } -> Some attrs
    | Svg { origin = (_, attrs), _; _ } -> Some attrs
    | Video { origin = (_, attrs), _; _ } -> Some attrs
    | Audio { origin = (_, attrs), _; _ } -> Some attrs
    | Pdf { origin = (_, attrs), _; _ } -> Some attrs
    | Hand_drawn { origin = (_, attrs), _; _ } -> Some attrs
end

module Block = struct
  module Code_block = Block.Code_block
  module Thematic_break = Block.Thematic_break

  module Heading = struct
    type t = {
      layout : Cmarkit.Block.Heading.layout;
      level : int;
      inline : Inline.t;
    }
  end

  module Html_block = Block.Html_block

  module rec Block_quote : sig
    type t = { indent : Layout.indent; block : T.t }
  end =
    Block_quote

  and List_item : sig
    type t = {
      before_marker : Layout.indent;
      marker : Layout.string node;
      after_marker : Layout.indent;
      block : T.t;
      ext_task_marker : Uchar.t node option;
    }
  end =
    List_item

  and List' : sig
    type type' = [ `Unordered of Layout.char | `Ordered of int * Layout.char ]
    type t = { type' : type'; tight : bool; items : List_item.t node list }
  end =
    List'

  and Paragraph : sig
    type t = {
      leading_indent : Layout.indent;
      inline : Inline.t;
      trailing_blanks : Layout.blanks;
    }
  end =
    Paragraph

  and Slide : sig
    type t = { content : T.t; title : Inline.t attributed option }
  end =
    Slide

  and Table : sig
    type align = [ `Left | `Center | `Right ]
    type sep = align option * Layout.count
    type cell_layout = Layout.blanks * Layout.blanks

    type row =
      [ `Header of (Inline.t * cell_layout) list
      | `Sep of sep node list
      | `Data of (Inline.t * cell_layout) list ]

    type t = {
      indent : Layout.indent;
      col_count : int;
      rows : (row node * Layout.blanks) list;
    }
  end =
    Table

  and Attribute_definition : sig
    type t = {
      indent : Layout.indent;
      label : Label.t;
      attrs : Attributes.t node;
    }
  end =
    Attribute_definition

  and T : sig
    type t =
      | Blank_line of Layout.blanks node
      | Block_quote of Block_quote.t attributed node
      | Blocks of T.t list node
      | Code_block of Code_block.t attributed node
      | Heading of Heading.t attributed node
      | Html_block of Html_block.t attributed node
      | Link_reference_definition of Link_definition.t attributed node
      | List of List'.t attributed node
      | Paragraph of Paragraph.t attributed node
      | Thematic_break of Thematic_break.t attributed node
      | Included of T.t attributed node
      | Div of T.t attributed node
      | Slide of Slide.t attributed node
      | Slip of T.t attributed node
      | SlipScript of Code_block.t attributed node
      | Carousel of T.t list attributed node
      | MermaidJS of Code_block.t attributed node
      | Math_block of Code_block.t attributed node
      | Table of Table.t attributed node
      | Standalone_attributes of Attributes.t node
      | Attribute_definition of Attribute_definition.t attributed node
  end =
    T

  include T

  let meta (b : t) =
    match b with
    | Blank_line (_, meta) -> meta
    | Block_quote (_, meta) -> meta
    | Blocks (_, meta) -> meta
    | Code_block (_, meta) -> meta
    | Heading (_, meta) -> meta
    | Html_block (_, meta) -> meta
    | Link_reference_definition (_, meta) -> meta
    | List (_, meta) -> meta
    | Paragraph (_, meta) -> meta
    | Thematic_break (_, meta) -> meta
    | Included (_, meta) -> meta
    | Div (_, meta) -> meta
    | Slide (_, meta) -> meta
    | Slip (_, meta) -> meta
    | SlipScript (_, meta) -> meta
    | Carousel (_, meta) -> meta
    | MermaidJS (_, meta) -> meta
    | Math_block (_, meta) -> meta
    | Table (_, meta) -> meta
    | Standalone_attributes (_, meta) -> meta
    | Attribute_definition (_, meta) -> meta

  let map_attrs f (b : t) =
    match b with
    | Blank_line _ as bl -> bl
    | Block_quote ((bq, attrs), meta) -> Block_quote ((bq, f attrs), meta)
    | Blocks _ as bs -> bs
    | Code_block ((cb, attrs), meta) -> Code_block ((cb, f attrs), meta)
    | Heading ((h, attrs), meta) -> Heading ((h, f attrs), meta)
    | Html_block ((html_block, attrs), meta) ->
        Html_block ((html_block, f attrs), meta)
    | Link_reference_definition ((lrd, attrs), meta) ->
        Link_reference_definition ((lrd, f attrs), meta)
    | List ((l, attrs), meta) -> List ((l, f attrs), meta)
    | Paragraph ((p, attrs), meta) -> Paragraph ((p, f attrs), meta)
    | Thematic_break ((tb, attrs), meta) -> Thematic_break ((tb, f attrs), meta)
    | Included ((inc, attrs), meta) -> Included ((inc, f attrs), meta)
    | Div ((div, attrs), meta) -> Div ((div, f attrs), meta)
    | Slide ((slide, attrs), meta) -> Slide ((slide, f attrs), meta)
    | Slip ((slip, attrs), meta) -> Slip ((slip, f attrs), meta)
    | SlipScript ((sc, attrs), meta) -> SlipScript ((sc, f attrs), meta)
    | Carousel ((c, attrs), meta) -> Carousel ((c, f attrs), meta)
    | MermaidJS ((mer, attrs), meta) -> MermaidJS ((mer, f attrs), meta)
    | Math_block ((mb, attrs), meta) -> Math_block ((mb, f attrs), meta)
    | Table ((table, attrs), meta) -> Table ((table, f attrs), meta)
    | Standalone_attributes _ as attrs -> attrs
    | Attribute_definition ((ad, attrs), meta) ->
        Attribute_definition ((ad, f attrs), meta)

  let get_attrs (b : t) =
    match b with
    | Blank_line _ -> None
    | Block_quote ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Blocks _ -> None
    | Code_block ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Heading ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Html_block ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Link_reference_definition ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | List ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Paragraph ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Thematic_break ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Included ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Div ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Slide ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Slip ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | SlipScript ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Carousel ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | MermaidJS ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Math_block ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Table ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Standalone_attributes attrs ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
    | Attribute_definition ((_, attrs), _) ->
        Some (map_attrs (fun _ -> (Attributes.empty, Meta.none)) b, attrs)
end

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

type t = { doc : Block.t; files : Files.map; defs : Label.defs }
