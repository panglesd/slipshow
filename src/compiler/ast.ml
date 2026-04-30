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
end

module Block = struct
  module Code_block = Block.Code_block
  module Thematic_break = Block.Thematic_break

  module Heading = struct
    type layout = {
      indent : Layout.indent;
      after_opening : Layout.blanks;
      closing : Layout.string;
    }

    type t = { layout : layout; level : int; inline : Inline.t }
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
