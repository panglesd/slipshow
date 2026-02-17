let of_string ?loc_offset ~file =
  let locs = Option.is_some file in
  Cmarkit.Doc.of_string ~heading_auto_ids:false ~strict:false ~locs ?loc_offset
    ?file
