type 'a loced = 'a * Cmarkit.Textloc.t

module Local = struct
  type t = { toplevel_attributes : Cmarkit.Attributes.t Cmarkit.node option }
  type 'a with_ = { x : 'a; fm : t }

  let empty = { toplevel_attributes = None }
  let with_empty x = { x; fm = empty }
end

module Global = struct
  type t = {
    math_link : Asset.t loced option;
    theme : [ `Builtin of Themes.t | `External of string ] loced option;
    dimension : (int * int) loced option;
    highlightjs_theme : string loced option;
    math_mode : [ `Mathjax | `Katex ] loced option;
    css_links : Asset.t list;
    js_links : Asset.t list;
    external_ids : string list;
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
    }

  let with_empty x = { x; fm = empty }

  let combine x y =
    let opt x y = match x with Some _ -> x | _ -> y in
    {
      math_link = opt x.math_link y.math_link;
      theme = opt x.theme y.theme;
      dimension = opt x.dimension y.dimension;
      highlightjs_theme = opt x.highlightjs_theme y.highlightjs_theme;
      math_mode = opt x.math_mode y.math_mode;
      css_links = x.css_links @ y.css_links;
      js_links = x.js_links @ y.js_links;
      external_ids = x.external_ids @ y.external_ids;
    }
end

type t = { local : Local.t; global : Global.t }
type fm = t

module Toplevel_attributes = struct
  type t = Cmarkit.Attributes.t Cmarkit.node

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

  let of_string ~to_asset:_ (s, loc) =
    let s = String.trim s in
    let s =
      if String.length s > 0 && s.[0] = '{' then
        (* Just so emacs does not find an unmatched curly brace: '}'! *)
        s
      else "{" ^ s ^ "}"
    in
    let loc_offset =
      (Cmarkit.Textloc.first_byte loc, fst @@ Cmarkit.Textloc.first_line loc)
    in
    let file = Cmarkit.Textloc.file loc in
    let cmarkit =
      Cmarkit.Doc.of_string ~loc_offset ~locs:true ~file ~strict:false s
    in
    let cmarkit = Cmarkit.Doc.block cmarkit in
    match cmarkit with
    | Cmarkit.Block.Ext_standalone_attributes attrs -> Ok attrs
    | _ -> Error (`Msg "Failed to parse the attributes")

  let update_frontmatter (fm : fm) v =
    { fm with local = { toplevel_attributes = Some v } }
end

module Math_link = struct
  type t = Asset.t loced

  let key = "math-link"
  let of_string ~to_asset (s, loc) = Ok (to_asset s, loc)

  let update_frontmatter (fm : fm) v =
    { fm with global = { fm.global with math_link = Some v } }
end

module Theme = struct
  type t = [ `Builtin of Themes.t | `External of string ] loced

  let key = "theme"
  let default = (`Builtin Themes.Default, Cmarkit.Textloc.none)

  let of_string ~to_asset:_ (s, loc) =
    match Themes.of_string s with
    | Some theme -> Ok (`Builtin theme, loc)
    | None -> Ok (`External s, loc)

  let update_frontmatter (fm : fm) v =
    { fm with global = { fm.global with theme = Some v } }
end

module Css_links = struct
  type t = Asset.t list

  let key = "css"

  let of_string ~to_asset (s, _) =
    s |> String.split_on_char ' '
    |> List.filter_map (function "" -> None | x -> Some (to_asset x))
    |> Result.ok

  let update_frontmatter (fm : fm) v =
    { fm with global = { fm.global with css_links = v @ fm.global.css_links } }
end

module Js_links = struct
  type t = Asset.t list

  let key = "js"

  let of_string ~to_asset (s, _) =
    s |> String.split_on_char ' '
    |> List.filter_map (function "" -> None | x -> Some (to_asset x))
    |> Result.ok

  let update_frontmatter (fm : fm) v =
    { fm with global = { fm.global with js_links = v @ fm.global.js_links } }
end

module Dimension = struct
  type t = (int * int) loced

  let key = "dimension"
  let default = ((1440, 1080), Cmarkit.Textloc.none)

  let of_string ~to_asset:_ (s, loc) =
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

  let of_string' = of_string ~to_asset:()

  let update_frontmatter (fm : fm) v =
    { fm with global = { fm.global with dimension = Some v } }
end

module Hljs_theme = struct
  type t = string loced

  let key = "highlightjs-theme"
  let of_string ~to_asset:_ = fun (x, loc) -> Ok (x, loc)
  let default = ("default", Cmarkit.Textloc.none)

  let update_frontmatter (fm : fm) v =
    { fm with global = { fm.global with highlightjs_theme = Some v } }
end

module Math_mode = struct
  type t = [ `Mathjax | `Katex ] loced

  let key = "math-mode"

  let of_string ~to_asset:_ = function
    | "mathjax", loc -> Ok (`Mathjax, loc)
    | "katex", loc -> Ok (`Katex, loc)
    | _ -> Error (`Msg "Expected \"mathjax\" or \"katex\"")

  let default = (`Mathjax, Cmarkit.Textloc.none)

  let update_frontmatter (fm : fm) v =
    { fm with global = { fm.global with math_mode = Some v } }
end

module type Field = sig
  type t

  val key : string

  val of_string :
    to_asset:(string -> Asset.t) ->
    string * Cmarkit.Textloc.t ->
    (t, [ `Msg of string ]) result

  val update_frontmatter : fm -> t -> fm
end

module External_ids = struct
  type t = string list

  let key = "external-ids"

  let of_string ~to_asset:_ (s, _) =
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

let fields_names = all_fields |> List.map (fun (module X : Field) -> X.key)
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
  let i = i + 1 in
  let byte_start = byte_start + offset in
  let update_loc (beg, end_) =
    Cmarkit.Textloc.v ~file ~first_line:(i, byte_start)
      ~last_line:(i, byte_start) ~first_byte:(beg + byte_start)
      ~last_byte:(end_ + byte_start)
  in
  String.index_opt line c
  |> Option.map @@ fun idx ->
     let key, kloc = string_sub line 0 idx in
     let key = (String.trim key, update_loc kloc) in
     let v, loc = string_sub line (idx + 1) (String.length line - (idx + 1)) in
     let v = (String.trim v, update_loc loc) in
     (key, v)

let send_unrecognized_field ~key ~kloc =
  let msg = "Frontmatter field '" ^ key ^ "' is not interpreted by slipshow" in
  let n =
    "Recognized fields are: '" ^ String.concat "', '" fields_names ^ "'"
  in
  Diagnosis.add
    (General
       { msg; notes = [ n ]; labels = [ ("", kloc) ]; code = "Frontmatter" })

let send_general_error ~key ~msg ~vloc =
  Diagnosis.add
    (General
       {
         msg = "Error while parsing frontmatter field '" ^ key ^ "'";
         notes = [];
         labels = [ (msg, vloc) ];
         code = "Frontmatter";
       })

let of_string ~to_asset file offset s =
  let raise_warning line =
    let loc =
      let i, _, (byte_start, byte_end) = line in
      let i = i + 1 in
      let first_byte = byte_start + offset
      and last_byte = byte_end + offset - 1 in
      Cmarkit.Textloc.v ~file ~first_line:(i, byte_start)
        ~last_line:(i, byte_start) ~first_byte ~last_byte
    in
    let msg = "Invalid frontmatter entry" in
    let note =
      "Frontmatter have to be of the form \"key:value\" on a single line."
    in
    let notes = [ note ] in
    Diagnosis.add
      (General { msg; notes; labels = [ ("", loc) ]; code = "Frontmatter" })
  in
  let assoc =
    s |> split_in_lines
    |> List.filter_map @@ fun line ->
       match cut file offset line ':' with
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
        match F.of_string ~to_asset value with
        | Ok x -> F.update_frontmatter fm x
        | Error (`Msg msg) ->
            send_general_error ~key ~msg ~vloc;
            fm)
  in
  List.fold_left handle_line empty assoc

let ( let* ) x f = Option.bind x f
let ( let+ ) x f = Option.map f x

let find_opening s =
  if
    String.starts_with ~prefix:"---\n" s
    || String.starts_with ~prefix:"---\r\n" s
  then if s.[4] = '\n' then Some 3 else Some 4
  else None

let find_closing s start =
  let is_closing idx =
    s.[idx + 1] = '-'
    && s.[idx + 2] = '-'
    && s.[idx + 3] = '-'
    && (s.[idx + 4] = '\n' || (s.[idx + 4] = '\r' && s.[idx + 5] = '\n'))
  in
  let closing_length idx = if s.[idx + 4] = '\n' then 4 else 5 in
  let rec aux idx =
    match String.index_from_opt s idx '\n' with
    | None -> None
    | Some idx -> (
        try
          if is_closing idx then Some (idx + 1, idx + 1 + closing_length idx)
          else aux (idx + 1)
        with Invalid_argument _ -> None)
  in
  aux start

type extraction = {
  frontmatter : string;
  rest : string;
  rest_offset : int * int;
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
    (after, n_lines 0 (after - 1))
  in
  { frontmatter; rest; rest_offset = offset; fm_offset = start }
