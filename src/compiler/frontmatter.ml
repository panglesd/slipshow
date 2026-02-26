type resolved = [ `Resolved ]
type unresolved = [ `Unresolved ]

type 'a fm = {
  toplevel_attributes : Cmarkit.Attributes.t option;
  math_link : 'a option;
  theme : [ `Builtin of Themes.t | `External of string ] option;
  css_links : 'a list;
  js_links : 'a list;
  dimension : (int * int) option;
  highlightjs_theme : string option;
  math_mode : [ `Mathjax | `Katex ] option;
  external_ids : string list;
}
(** We keep an option even though there are default value to be able to merge
    two frontmatter. None and default value represent different things. *)

module Toplevel_attributes = struct
  type t = Cmarkit.Attributes.t

  let key = "toplevel-attributes"

  let default =
    Cmarkit.Attributes.make
      ~kv_attributes:
        [
          (("slip", Cmarkit.Meta.none), None);
          ( ("enter", Cmarkit.Meta.none),
            Some ({ v = "~duration:0"; delimiter = None }, Cmarkit.Meta.none) );
        ]
      ()

  let of_string s =
    let s = String.trim s in
    let s =
      if String.length s > 0 && s.[0] = '{' then
        (* Just so emacs does not find an unmatched curly brace: '}'! *)
        s
      else "{" ^ s ^ "}"
    in
    let cmarkit = Cmarkit.Doc.of_string ~strict:false s in
    let cmarkit = Cmarkit.Doc.block cmarkit in
    match cmarkit with
    | Cmarkit.Block.Ext_standalone_attributes (attrs, _) -> Ok attrs
    | _ -> Error (`Msg "Failed to parse the attributes")

  let update_frontmatter (fm : _ fm) v =
    { fm with toplevel_attributes = Some v }
end

module Math_link = struct
  type t = string

  let key = "math-link"
  let of_string s = Ok s
  let update_frontmatter (fm : _ fm) v = { fm with math_link = Some v }
end

module Theme = struct
  type t = [ `Builtin of Themes.t | `External of string ]

  let key = "theme"
  let default = `Builtin Themes.Default

  let of_string s =
    match Themes.of_string s with
    | Some theme -> Ok (`Builtin theme)
    | None -> Ok (`External s)

  let update_frontmatter (fm : _ fm) v = { fm with theme = Some v }
end

module Css_links = struct
  type t = string list

  let key = "css"

  let of_string s =
    s |> String.split_on_char ' '
    |> List.filter (fun x -> not (String.equal "" x))
    |> Result.ok

  let update_frontmatter (fm : _ fm) v =
    { fm with css_links = v @ fm.css_links }
end

module Js_links = struct
  type t = string list

  let key = "js"

  let of_string s =
    s |> String.split_on_char ' '
    |> List.filter (fun x -> not (String.equal "" x))
    |> Result.ok

  let update_frontmatter (fm : _ fm) v = { fm with js_links = v @ fm.js_links }
end

module Dimension = struct
  type t = int * int

  let key = "dimension"
  let default = (1440, 1080)

  let of_string s =
    let ( let* ) = Result.bind in
    let error =
      Error
        (`Msg "Expected \"4:3\", \"16:9\", or two integers separated by a 'x'")
    in
    let int_parser i =
      match int_of_string_opt i with Some i -> Ok i | None -> error
    in
    match String.split_on_char 'x' s with
    | [ "4:3" ] -> Ok (1440, 1080)
    | [ "16:9" ] -> Ok (1920, 1080)
    | [ width; height ] ->
        let* width = int_parser width in
        let* height = int_parser height in
        Ok (width, height)
    | _ -> error

  let update_frontmatter (fm : _ fm) v = { fm with dimension = Some v }
end

module Hljs_theme = struct
  type t = string

  let key = "highlightjs-theme"
  let of_string = fun x -> Ok x
  let default = "default"
  let update_frontmatter (fm : _ fm) v = { fm with highlightjs_theme = Some v }
end

module Math_mode = struct
  type t = [ `Mathjax | `Katex ]

  let key = "math-mode"

  let of_string = function
    | "mathjax" -> Ok `Mathjax
    | "katex" -> Ok `Katex
    | _ -> Error (`Msg "Expected \"mathjax\" or \"katex\"")

  let default = `Mathjax
  let update_frontmatter (fm : _ fm) v = { fm with math_mode = Some v }
end

module type Field = sig
  type t

  val key : string
  val of_string : string -> (t, [ `Msg of string ]) result
  val update_frontmatter : string fm -> t -> string fm
end

module External_ids = struct
  type t = string list

  let key = "external-ids"

  let of_string s =
    String.split_on_char ' ' s
    |> List.filter (fun x -> not @@ String.equal String.empty x)
    |> Result.ok

  let update_frontmatter (fm : _ fm) v =
    { fm with external_ids = v @ fm.external_ids }
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

type 'a t =
  | Unresolved : string fm -> unresolved t
  | Resolved : Asset.t fm -> resolved t

let resolve (Unresolved fm) ~to_asset =
  Resolved
    {
      fm with
      math_link = Option.map to_asset fm.math_link;
      css_links = List.map to_asset fm.css_links;
      js_links = List.map to_asset fm.js_links;
    }

let empty_fm =
  {
    dimension = None;
    toplevel_attributes = None;
    math_link = None;
    theme = None;
    css_links = [];
    js_links = [];
    highlightjs_theme = None;
    math_mode = None;
    external_ids = [];
  }

let empty = Resolved empty_fm

(* let get (field_name, convert) kv = *)
(*   List.assoc_opt field_name kv |> Option.map convert *)

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

let of_string file offset s =
  let assoc =
    s |> split_in_lines
    |> List.filter_map @@ fun line -> cut file offset line ':'
  in
  let handle_line fm ((key, kloc), (value, vloc)) =
    match SMap.find_opt key fields_map with
    | None ->
        send_unrecognized_field ~key ~kloc;
        fm
    | Some (module F) -> (
        match F.of_string value with
        | Ok x -> F.update_frontmatter fm x
        | Error (`Msg msg) ->
            send_general_error ~key ~msg ~vloc;
            fm)
  in
  let fm = List.fold_left handle_line empty_fm assoc in
  Unresolved fm

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
  (frontmatter, rest, offset, start)

let combine (Resolved cli_frontmatter) (Resolved frontmatter) =
  let combine_opt cli f = match cli with Some _ as x -> x | None -> f in
  (* TODO: warn on cli erasing frontmatter *)
  let toplevel_attributes =
    combine_opt cli_frontmatter.toplevel_attributes
      frontmatter.toplevel_attributes
  in
  let math_link = combine_opt cli_frontmatter.math_link frontmatter.math_link in
  let math_mode = combine_opt cli_frontmatter.math_mode frontmatter.math_mode in
  let theme = combine_opt cli_frontmatter.theme frontmatter.theme in
  let dimension = combine_opt cli_frontmatter.dimension frontmatter.dimension in
  let css_links = cli_frontmatter.css_links @ frontmatter.css_links in
  let js_links = cli_frontmatter.js_links @ frontmatter.js_links in
  let highlightjs_theme =
    combine_opt cli_frontmatter.highlightjs_theme frontmatter.highlightjs_theme
  in
  let external_ids = cli_frontmatter.external_ids @ frontmatter.external_ids in
  Resolved
    {
      toplevel_attributes;
      math_link;
      theme;
      css_links;
      dimension;
      js_links;
      highlightjs_theme;
      math_mode;
      external_ids;
    }
