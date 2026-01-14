type resolved = [ `Resolved ]
type unresolved = [ `Unresolved ]

type 'a fm = {
  toplevel_attributes : Cmarkit.Attributes.t option;
  math_link : 'a option;
  theme : [ `Builtin of Themes.t | `External of string ] option;
  css_links : 'a list;
  js_links : 'a list;
  dimension : (int * int) option;
}

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

module Default = struct
  let dimension = (1440, 1080)

  let toplevel_attributes =
    Cmarkit.Attributes.make
      ~kv_attributes:
        [
          (("slip", Cmarkit.Meta.none), None);
          ( ("enter", Cmarkit.Meta.none),
            Some ({ v = "~duration:0"; delimiter = None }, Cmarkit.Meta.none) );
        ]
      ()

  let theme = `Builtin Themes.Default
end

let empty =
  Resolved
    {
      dimension = None;
      toplevel_attributes = None;
      math_link = None;
      theme = None;
      css_links = [];
      js_links = [];
    }

module String_to = struct
  let toplevel_attributes s =
    let s = String.trim s in
    let s =
      if String.length s > 0 && s.[0] = '{' then
        (* Just so emacs does not find an unmatched curly brace! *)
        let _ = '}' in
        s
      else "{" ^ s ^ "}"
    in
    let cmarkit = Cmarkit.Doc.of_string ~strict:false s in
    let cmarkit = Cmarkit.Doc.block cmarkit in
    match cmarkit with
    | Cmarkit.Block.Ext_standalone_attributes (attrs, _) -> Ok attrs
    | _ -> Error (`Msg "Can only be a set of attributes")

  let math_link s = s

  let theme s =
    match Themes.of_string s with
    | Some theme -> `Builtin theme
    | None -> `External s

  let css_link s = s

  let dimension s =
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
end

let get (field_name, convert) kv =
  List.assoc_opt field_name kv |> Option.map convert

let cut s c =
  String.index_opt s c
  |> Option.map @@ fun idx ->
     ( String.sub s 0 idx,
       String.trim @@ String.sub s (idx + 1) (String.length s - (idx + 1)) )

let of_string s =
  let assoc =
    s |> String.split_on_char '\n'
    |> List.filter_map @@ fun line ->
       let line = String.trim line in
       cut line ':'
  in
  let get x y =
    match get x y with
    | Some (Ok x) -> Some x
    | Some (Error (`Msg x)) ->
        Logs.warn (fun m -> m "Error in frontmatter: %s" x);
        None
    | None -> None
  in
  let toplevel_attributes =
    get ("toplevel-attributes", String_to.toplevel_attributes) assoc
  in
  let math_link =
    get ("math-link", fun x -> Ok (String_to.math_link x)) assoc
  in
  let theme = get ("theme", fun x -> Ok (String_to.theme x)) assoc in
  let files field =
    get (field, fun x -> Ok x) assoc
    |> Option.map (fun x -> String.split_on_char ' ' x)
    |> Option.map @@ List.filter (fun x -> not (String.equal " " x))
    |> Option.value ~default:[]
  in
  let css_links = files "css" in
  let js_links = files "js" in
  let dimension = get ("dimension", String_to.dimension) assoc in
  Ok
    (Unresolved
       { toplevel_attributes; math_link; theme; css_links; dimension; js_links })

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
  (frontmatter, rest)

let combine (Resolved cli_frontmatter) (Resolved frontmatter) =
  let combine_opt cli f = match cli with Some _ as x -> x | None -> f in
  (* TODO: warn on cli erasing frontmatter *)
  let toplevel_attributes =
    combine_opt cli_frontmatter.toplevel_attributes
      frontmatter.toplevel_attributes
  in
  let math_link = combine_opt cli_frontmatter.math_link frontmatter.math_link in
  let theme = combine_opt cli_frontmatter.theme frontmatter.theme in
  let dimension = combine_opt cli_frontmatter.dimension frontmatter.dimension in
  let css_links = cli_frontmatter.css_links @ frontmatter.css_links in
  let js_links = cli_frontmatter.js_links @ frontmatter.js_links in
  Resolved
    { toplevel_attributes; math_link; theme; css_links; dimension; js_links }
