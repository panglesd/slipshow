let of_string ?loc_offset ~file =
  let file = Fpath.to_string file in
  Cmarkit.Doc.of_string ~heading_auto_ids:false ~strict:false ~locs:true
    ?loc_offset ~file

let of_string ~file s =
  let frontmatter, s, loc_offset =
    match Frontmatter.extract s with
    | None -> (Frontmatter.empty, s, None)
    | Some { frontmatter = txt_fm; rest; rest_offset; fm_offset } ->
        let parent = Fpath.parent file in
        let to_uri s = Uri.of_string ~parent s in
        let frontmatter = Frontmatter.of_string ~to_uri file fm_offset txt_fm in
        (frontmatter, rest, Some rest_offset)
  in
  let doc = of_string ?loc_offset ~file s in
  (doc, frontmatter)
