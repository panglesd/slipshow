type resolved = [ `Resolved ]
type unresolved = [ `Unresolved ]

type 'a fm = {
  toplevel_attributes : Cmarkit.Attributes.t option;
  math_link : 'a option;
  theme : [ `Builtin of Themes.t | `External of string ] option;
  css_links : 'a list;
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
    }

module Default = struct
  let dimension = (1440, 1080)

  let toplevel_attributes =
    Cmarkit.Attributes.make
      ~kv_attributes:[ (("slip", Cmarkit.Meta.none), None) ]
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

module Yaml_to = struct
  let expect_string name =
    let error =
      Format.sprintf "'%s' in frontmatter must be given as a string" name
    in
    Error (`Msg error)

  let toplevel_attributes = function
    | `String s -> String_to.toplevel_attributes s
    | _ -> expect_string "toplevel attributes"

  let math_link = function
    | `String s -> Ok (String_to.math_link s)
    | _ -> expect_string "math-link"

  let theme = function
    | `String s -> Ok (String_to.theme s)
    | _ -> expect_string "theme"

  let css_link = function `String s -> Ok s | _ -> expect_string "css-link"
  let ( let* ) = Result.bind

  let css_links = function
    | `String s -> Ok [ s ]
    | `A a ->
        let* res =
          List.fold_left
            (fun acc l ->
              let* acc = acc in
              let* res = css_link l in
              Ok (res :: acc))
            (Ok []) a
        in
        Ok (List.rev res)
    | _ ->
        Error
          (`Msg
             "'css-links' in frontmatter must be given as a string or an array \
              of string")

  let dimension = function
    | `String s -> String_to.dimension s
    | _ -> expect_string "dimension"
end

let get (field_name, convert) kv_yaml =
  List.assoc_opt field_name kv_yaml |> Option.map convert

let of_yaml yaml =
  match yaml with
  | `O kv_yaml ->
      let get x y =
        match get x y with
        | Some (Ok x) -> Some x
        | Some (Error (`Msg x)) ->
            Logs.warn (fun m -> m "Error in frontmatter: %s" x);
            None
        | None -> None
      in
      let toplevel_attributes =
        get ("toplevel-attributes", Yaml_to.toplevel_attributes) kv_yaml
      in
      let math_link = get ("math-link", Yaml_to.math_link) kv_yaml in
      let theme = get ("theme", Yaml_to.theme) kv_yaml in
      let css_links =
        get ("css", Yaml_to.css_links) kv_yaml |> Option.value ~default:[]
      in
      let dimension = get ("dimension", Yaml_to.dimension) kv_yaml in
      Ok
        (Unresolved
           { toplevel_attributes; math_link; theme; css_links; dimension })
  | _ ->
      Error
        (`Msg "Malformed YAML frontmatter: Needs to be a list of key-values")

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
  let frontmatter = Yaml.of_string frontmatter in
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
  Resolved { toplevel_attributes; math_link; theme; css_links; dimension }
