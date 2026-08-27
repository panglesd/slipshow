type 'a loced = 'a * Cmarkit.Textloc.t

let combine_opt option_name x y =
  match (x, y) with
  | Some (alpha, loc1), Some (beta, loc2) when alpha <> beta ->
      Diagnosis.add @@ InconsistentOption { option_name; loc1; loc2 };
      x
  | Some _, _ -> x
  | None, _ -> y

module Local = struct
  type t = { attributes : Cmarkit.Attributes.t Cmarkit.node option }
  type 'a with_ = { x : 'a; fm : t }

  let empty = { attributes = None }
  let with_empty x = { x; fm = empty }
end

let math_link_key = "math-link"
let theme_key = "theme"
let dimension_key = "dimension"
let highlightjs_theme_key = "highlightjs-theme"
let math_mode_key = "math-mode"
let css_links_key = "css"
let js_links_key = "js"
let external_ids_key = "external-ids"

module Global = struct
  type t = {
    math_link : Uri.t loced option;
    theme : [ `Builtin of Themes.t | `External of Uri.t ] loced option;
    dimension : (int * int) loced option;
    highlightjs_theme : string loced option;
    math_mode : [ `Mathjax | `Katex ] loced option;
    css_links : Uri.t loced list;
    js_links : Uri.t loced list;
    external_ids : string list;
    toplevel_attributes : Cmarkit.Attributes.t Cmarkit.node option;
  }
  (** We keep an option even though there are default value to be able to merge
      two frontmatter. None and default value represent different things. *)

  type 'a with_ = { x : 'a; fm : t }

  let empty =
    {
      math_link = None;
      theme = None;
      dimension = None;
      highlightjs_theme = None;
      math_mode = None;
      css_links = [];
      js_links = [];
      external_ids = [];
      toplevel_attributes = None;
    }

  let with_empty x = { x; fm = empty }

  let combine x y =
    {
      math_link = combine_opt math_link_key x.math_link y.math_link;
      theme = combine_opt theme_key x.theme y.theme;
      dimension = combine_opt dimension_key x.dimension y.dimension;
      highlightjs_theme =
        combine_opt highlightjs_theme_key x.highlightjs_theme
          y.highlightjs_theme;
      math_mode = combine_opt math_mode_key x.math_mode y.math_mode;
      css_links = x.css_links @ y.css_links;
      js_links = x.js_links @ y.js_links;
      external_ids = x.external_ids @ y.external_ids;
      toplevel_attributes =
        (match (x.toplevel_attributes, y.toplevel_attributes) with
        | Some (a1, meta1), Some (a2, _meta2) ->
            (* Hopefully not merging the locations is fine *)
            Some
              ( Cmarkit.Attributes.merge ~keep_base:false ~base:a1 ~new_attrs:a2,
                meta1 )
        | (Some _ as a), _ | _, (Some _ as a) -> a
        | None, None -> None);
    }

  let uris
      ({
         math_link;
         theme;
         dimension = _;
         highlightjs_theme = _;
         math_mode = _;
         css_links;
         js_links;
         external_ids = _;
         toplevel_attributes = _;
       } :
        t) =
    let math_link = Option.to_list math_link in
    let theme =
      match theme with Some (`External uri, loc) -> [ (uri, loc) ] | _ -> []
    in
    List.concat [ math_link; theme; css_links; js_links ]
end

type t = { local : Local.t; global : Global.t }
type fm = t

module Attributes = struct
  type t = Cmarkit.Attributes.t Cmarkit.node

  let key = "attributes"
  let default = (Cmarkit.Attributes.empty, Cmarkit.Meta.none)

  let of_string ~to_uri:_ (s, loc) =
    let s, o =
      if String.length s > 0 && s.[0] = '{' then
        (* Just so emacs does not find an unmatched curly brace: '}'! *)
        (s, 0)
      else ("{" ^ s ^ "}", 1)
    in
    let loc_offset =
      (Cmarkit.Textloc.first_byte loc - o, Cmarkit.Textloc.first_line loc)
    in
    let file = Cmarkit.Textloc.file loc in
    let cmarkit =
      Cmarkit.Doc.of_string ~loc_offset ~locs:true ~file ~strict:false s
    in
    let cmarkit = Cmarkit.Doc.block cmarkit in
    match cmarkit with
    | Cmarkit.Block.Ext_standalone_attributes attrs -> Ok attrs
    | _ -> Error (`Msg "Failed to parse the attributes")

  let update_frontmatter (fm : fm) (v, meta1) =
    let v =
      match fm.local.attributes with
      | None -> v
      | Some (a, _meta2) ->
          (* Hopefully not merging the locations is fine *)
          Cmarkit.Attributes.merge ~keep_base:false ~base:a ~new_attrs:v
    in
    { fm with local = { attributes = Some (v, meta1) } }
end

module Toplevel_attributes = struct
  type t = Attributes.t

  let key = "toplevel-attributes"

  let default =
    ( Cmarkit.Attributes.make
        ~kv_attributes:
          [
            (("slip", Cmarkit.Meta.none), None);
            ( ("enter", Cmarkit.Meta.none),
              Some ({ v = "~duration:0"; delimiter = None }, Cmarkit.Meta.none)
            );
          ]
        (),
      Cmarkit.Meta.none )

  let of_string = Attributes.of_string

  let update_frontmatter (fm : fm) (v, meta1) =
    let v =
      match fm.global.toplevel_attributes with
      | None -> v
      | Some (a, _meta2) ->
          (* Hopefully not merging the locations is fine *)
          Cmarkit.Attributes.merge ~keep_base:false ~base:a ~new_attrs:v
    in
    {
      fm with
      global = { fm.global with toplevel_attributes = Some (v, meta1) };
    }
end

let ( let+ ) x f = Result.map f x

module Math_link = struct
  type t = Uri.t loced

  let key = math_link_key

  let of_string ~to_uri (s, loc) =
    let+ uri = to_uri s in
    ((uri, loc) : t)

  let update_frontmatter (fm : fm) v =
    let math_link = combine_opt key (Some v) fm.global.math_link in
    { fm with global = { fm.global with math_link } }
end

module Theme = struct
  type t = [ `Builtin of Themes.t | `External of Uri.t ] loced

  let key = theme_key
  let default = (`Builtin Themes.Default, Cmarkit.Textloc.none)

  let of_string ~to_uri (s, loc) =
    match Themes.of_string s with
    | Some theme -> Ok (`Builtin theme, loc)
    | None ->
        let+ theme = to_uri s in
        (`External theme, loc)

  let update_frontmatter (fm : fm) v =
    let theme = combine_opt key (Some v) fm.global.theme in
    { fm with global = { fm.global with theme } }
end

let parse_uri_list =
  let offset_loc loc i l =
    let first_line = Cmarkit.Textloc.first_line loc in
    let first_byte = Cmarkit.Textloc.first_byte loc + i in
    let last_line = first_line in
    let last_byte = first_byte + l - 1 in
    loc
    |> Cmarkit.Textloc.set_first ~first_byte ~first_line
    |> Cmarkit.Textloc.set_last ~last_byte ~last_line
  in
  fun ~to_uri (s, loc) ->
    s |> String.split_on_char ' '
    |> List.fold_left
         (fun (acc, i) -> function
           | "" -> (acc, i + 1)
           | x -> (
               let l = String.length x in
               let loc = offset_loc loc i l in
               let i = i + l + 1 in
               match to_uri x with
               | Error (`Msg msg) ->
                   Diagnosis.add @@ Simple { loc; msg };
                   (acc, i)
               | Ok uri -> ((uri, loc) :: acc, i)))
         ([], 0)
    |> fst |> List.rev |> Result.ok

module Css_links = struct
  type t = Uri.t loced list

  let key = css_links_key
  let of_string = parse_uri_list

  let update_frontmatter (fm : fm) v =
    { fm with global = { fm.global with css_links = v @ fm.global.css_links } }
end

module Js_links = struct
  type t = Uri.t loced list

  let key = js_links_key
  let of_string = parse_uri_list

  let update_frontmatter (fm : fm) v =
    { fm with global = { fm.global with js_links = v @ fm.global.js_links } }
end

module Dimension = struct
  type t = (int * int) loced

  let key = dimension_key
  let default = ((1440, 1080), Cmarkit.Textloc.none)

  let of_string ~to_uri:_ (s, loc) =
    let ( let* ) = Result.bind in
    let error =
      Error
        (`Msg "Expected \"4:3\", \"16:9\", or two integers separated by a 'x'")
    in
    let int_parser i =
      match int_of_string_opt i with Some i -> Ok i | None -> error
    in
    let res =
      match String.split_on_char 'x' s with
      | [ "4:3" ] -> Ok (1440, 1080)
      | [ "16:9" ] -> Ok (1920, 1080)
      | [ width; height ] ->
          let* width = int_parser width in
          let* height = int_parser height in
          Ok (width, height)
      | _ -> error
    in
    Result.map (fun x -> (x, loc)) res

  let of_string' = of_string ~to_uri:()

  let update_frontmatter (fm : fm) v =
    let dimension = combine_opt key (Some v) fm.global.dimension in
    { fm with global = { fm.global with dimension } }
end

module Hljs_theme = struct
  type t = string loced

  let key = highlightjs_theme_key
  let of_string ~to_uri:_ = fun (x, loc) -> Ok (x, loc)
  let default = ("default", Cmarkit.Textloc.none)

  let update_frontmatter (fm : fm) v =
    let highlightjs_theme =
      combine_opt key (Some v) fm.global.highlightjs_theme
    in
    { fm with global = { fm.global with highlightjs_theme } }
end

module Math_mode = struct
  type t = [ `Mathjax | `Katex ] loced

  let key = math_mode_key

  let of_string ~to_uri:_ = function
    | "mathjax", loc -> Ok (`Mathjax, loc)
    | "katex", loc -> Ok (`Katex, loc)
    | _ -> Error (`Msg "Expected \"mathjax\" or \"katex\"")

  let default = (`Mathjax, Cmarkit.Textloc.none)

  let update_frontmatter (fm : fm) v =
    let math_mode = combine_opt key (Some v) fm.global.math_mode in
    { fm with global = { fm.global with math_mode } }
end

module type Field = sig
  type t

  val key : string

  val of_string :
    to_uri:(string -> (Uri.t, [ `Msg of string ]) result) ->
    string * Cmarkit.Textloc.t ->
    (t, [ `Msg of string ]) result

  val update_frontmatter : fm -> t -> fm
end

module External_ids = struct
  type t = string list

  let key = external_ids_key

  let of_string ~to_uri:_ (s, _) =
    String.split_on_char ' ' s
    |> List.filter (fun x -> not @@ String.equal String.empty x)
    |> Result.ok

  let update_frontmatter (fm : fm) v =
    {
      fm with
      global = { fm.global with external_ids = v @ fm.global.external_ids };
    }
end

let all_fields =
  [
    (module Dimension : Field);
    (module Toplevel_attributes : Field);
    (module Math_link : Field);
    (module Theme : Field);
    (module Css_links : Field);
    (module Js_links : Field);
    (module Hljs_theme : Field);
    (module Math_mode : Field);
    (module External_ids : Field);
    (module Attributes : Field);
  ]

module SMap = struct
  include Map.Make (String)

  (* Not included before OCaml 5.1 *)
  let of_list bs = List.fold_left (fun m (k, v) -> add k v m) empty bs
end

let fields_map =
  all_fields
  |> List.map (fun ((module X : Field) as m) -> (X.key, m))
  |> SMap.of_list

let allowed_keys = all_fields |> List.map (fun (module X : Field) -> X.key)
let empty = { local = Local.empty; global = Global.empty }
let string_sub s idx idx' = (String.sub s idx idx', (idx, idx + idx' - 1))

let split_in_lines s =
  let accumulate n (start_loc : int) i acc =
    if start_loc = i then acc else (n, (start_loc, i)) :: acc
  in
  let rec loop acc start_loc n i =
    match s.[i] with
    | exception _ -> accumulate n start_loc i acc
    | '\r' when i + 1 < String.length s && s.[i + 1] = '\n' ->
        loop (accumulate n start_loc i acc) (i + 2) (n + 1) (i + 2)
    | '\n' -> loop (accumulate n start_loc i acc) (i + 1) (n + 1) (i + 1)
    | _ -> loop acc start_loc n (i + 1)
  in
  loop [] 0 1 0
  |> List.rev_map (fun (n, (x, y)) -> (n, String.sub s x (y - x), (x, y)))

let cut file offset (i, line, (byte_start, _)) c =
  (* Begin of copy from OCaml 5.5 *)
  let invalid_start ~start len =
    let open String in
    let i = string_of_int in
    invalid_arg
    @@ concat "" [ "start: "; i start; " not in range [0;"; i len; "]" ]
  in
  let find_first_index sat ?(start = 0) s =
    let open String in
    let len = length s in
    if not (0 <= start && start <= len) then invalid_start ~start len
    else
      let i = ref start in
      while !i < len && not (sat (unsafe_get s !i)) do
        incr i
      done;
      if !i < len then Some !i else None
  in
  let find_last_index sat ?start s =
    let open String in
    let len = length s in
    let start = match start with None -> len | Some s -> s in
    if not (0 <= start && start <= len) then invalid_start ~start len
    else
      let i = ref (if start = len then len - 1 else start) in
      while !i >= 0 && not (sat (unsafe_get s !i)) do
        decr i
      done;
      if !i < 0 then None else Some !i
  in
  let is_white = function ' ' | '\t' .. '\r' -> true | _ -> false in
  (* end of copy from OCaml 5.5 *)
  let i = i + 1 in
  let byte_start = byte_start + offset in
  let update_loc (beg, _end_) s =
    let beg, end_ =
      let i0 =
        find_first_index (fun x -> not @@ is_white x) s
        |> Option.value ~default:0
      in
      let i1 =
        find_last_index (fun x -> not @@ is_white x) s
        |> Option.value ~default:0
      in
      (beg + i0, beg + i1)
    in
    Cmarkit.Textloc.v ~file ~first_line:(i, byte_start)
      ~last_line:(i, byte_start) ~first_byte:(beg + byte_start)
      ~last_byte:(end_ + byte_start)
  in
  String.index_opt line c
  |> Option.map @@ fun idx ->
     let key, kloc = string_sub line 0 idx in
     let key = (String.trim key, update_loc kloc key) in
     let v, loc = string_sub line (idx + 1) (String.length line - (idx + 1)) in
     let v = (String.trim v, update_loc loc v) in
     (key, v)

let send_unrecognized_field ~key ~kloc:loc =
  Diagnosis.add (UnknownFrontmatterField { key; loc; allowed_keys })

let send_general_error ~key ~msg ~vloc =
  Diagnosis.add (FrontmatterParsing { key; msg; loc = vloc })

let of_string ~to_uri file offset s =
  let file_s = Fpath.to_string file in
  let raise_warning line =
    let loc =
      let i, _, (byte_start, byte_end) = line in
      let i = i + 1 in
      let first_byte = byte_start + offset
      and last_byte = byte_end + offset - 1 in
      Cmarkit.Textloc.v ~file:file_s ~first_line:(i, first_byte)
        ~last_line:(i, first_byte) ~first_byte ~last_byte
    in
    Diagnosis.add (InvalidFrontmatterLine { loc })
  in
  let assoc =
    s |> split_in_lines
    |> List.filter_map @@ fun line ->
       match cut file_s offset line ':' with
       | None ->
           raise_warning line;
           None
       | Some _ as res -> res
  in
  let handle_line fm ((key, kloc), ((_, vloc) as value)) =
    match SMap.find_opt key fields_map with
    | None ->
        send_unrecognized_field ~key ~kloc;
        fm
    | Some (module F) -> (
        match F.of_string ~to_uri value with
        | Ok x -> F.update_frontmatter fm x
        | Error (`Msg msg) ->
            send_general_error ~key ~msg ~vloc;
            fm)
  in
  List.fold_left handle_line empty assoc

let ( let* ) x f = Option.bind x f
let ( let+ ) x f = Option.map f x

let delimiter_end s start =
  let length = String.length s in
  let rec skip_whitespace index =
    if index >= length then None
    else
      match s.[index] with
      | ' ' | '\t' -> skip_whitespace (index + 1)
      | '\n' -> Some (index + 1)
      | '\r' when index + 1 < length && s.[index + 1] = '\n' -> Some (index + 2)
      | _ -> None
  in
  if
    start + 3 <= length
    && s.[start] = '-'
    && s.[start + 1] = '-'
    && s.[start + 2] = '-'
  then skip_whitespace (start + 3)
  else None

let find_opening s = delimiter_end s 0

let find_closing s start =
  let rec aux idx =
    match String.index_from_opt s idx '\n' with
    | None -> None
    | Some idx -> (
        let start = idx + 1 in
        match delimiter_end s start with
        | Some after -> Some (start, after)
        | None -> aux start)
  in
  aux start

type extraction = {
  frontmatter : string;
  rest : string;
  rest_offset : int * (int * int);
  fm_offset : int;
}

let extract s =
  let* start = find_opening s in
  let+ end_, after = find_closing s start in
  let frontmatter = String.sub s start (end_ - start) in
  let rest = String.sub s after (String.length s - after) in
  let offset =
    let rec n_lines acc index =
      if index < 0 then acc
      else
        let acc = if s.[index] = '\n' then acc + 1 else acc in
        n_lines acc (index - 1)
    in
    (after, (n_lines 0 (after - 1) + 1, after))
  in
  { frontmatter; rest; rest_offset = offset; fm_offset = start }
