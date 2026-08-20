let of_string ?loc_offset ~file =
  let file = Fpath.to_string file in
  Cmarkit.Doc.of_string ~heading_auto_ids:false ~strict:false ~locs:true
    ?loc_offset ~file

let of_string ~read_file ~file s =
  let frontmatter, s, loc_offset =
    match Frontmatter.extract s with
    | None -> (Frontmatter.empty, s, (0, 0))
    | Some { frontmatter = txt_fm; rest; rest_offset; fm_offset } ->
        let parent = Fpath.parent file in
        let to_asset s = Asset.of_string ~parent ~read_file s in
        let frontmatter =
          Frontmatter.of_string ~to_asset file fm_offset txt_fm
        in
        (frontmatter, rest, rest_offset)
  in
  let doc = of_string ~loc_offset ~file s in
  (doc, frontmatter)
