let of_string ?loc_offset ~file =
  let locs = Option.is_some file in
  Cmarkit.Doc.of_string ~heading_auto_ids:false ~strict:false ~locs ?loc_offset
    ?file

let of_string ~read_file ~file s =
  let file = Option.map Fpath.to_string file in
  let frontmatter, s, loc_offset =
    match Frontmatter.extract s with
    | None -> (Frontmatter.empty, s, (0, 0))
    | Some { frontmatter = txt_fm; rest; rest_offset; fm_offset } ->
        let file = Option.value ~default:"-" file in
        let to_asset = Asset.of_string ~read_file in
        let frontmatter =
          Frontmatter.of_string ~to_asset file fm_offset txt_fm
        in
        (frontmatter, rest, rest_offset)
  in
  let doc = of_string ~loc_offset ~file s in
  (doc, frontmatter)
