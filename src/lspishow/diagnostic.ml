let corrected_position ~positionEncoding s ~utf8_bol ~utf8_position =
  match positionEncoding with
  | `UTF8 -> utf8_position - utf8_bol
  | `UTF16 ->
      let len = String.length s in
      let target_u8 = Int.min utf8_position len in
      let rec loop u8_idx u16_idx =
        if u8_idx >= target_u8 then u16_idx
        else
          let d = String.get_utf_8_uchar s u8_idx in
          let d_len = Uchar.utf_decode_length d in
          if u8_idx + d_len > target_u8 then u16_idx
            (* Target offset falls inside a multi-byte UTF-8 character... *)
          else
            let u = Uchar.utf_decode_uchar d in
            let u16_len = if Uchar.to_int u >= 0x10000 then 2 else 1 in
            loop (u8_idx + d_len) (u16_idx + u16_len)
      in
      loop utf8_bol 0

let pos_of_textloc ~source ~positionEncoding ~line ~byte =
  let line, utf8_bol = line in
  let character =
    corrected_position ~positionEncoding source ~utf8_bol ~utf8_position:byte
  in
  (line - 1, character)

let linoloc_of_textloc ~source ~positionEncoding (loc : Cmarkit.Textloc.t) =
  let start =
    let line = Cmarkit.Textloc.first_line loc in
    let byte = Cmarkit.Textloc.first_byte loc in
    let line, character =
      pos_of_textloc ~source ~positionEncoding ~line ~byte
    in
    Linol_lwt.Position.create ~character ~line
  in
  let end_ =
    let line = Cmarkit.Textloc.last_line loc in
    let byte = Cmarkit.Textloc.last_byte loc in
    let line, character =
      pos_of_textloc ~source ~positionEncoding ~line ~byte
    in
    let character = character + 1 in
    Linol_lwt.Position.create ~character ~line
  in
  Linol_lwt.Range.create ~end_ ~start

let create ~source ~positionEncoding ~loc ?ploc msg =
  let ( let+ ) x f = Option.map f x in
  Format.kasprintf
    (fun msg ->
      let+ source = source in
      let loc =
        match ploc with
        | None -> loc
        | Some ploc -> Diagnosis.loc_of_ploc loc ploc
      in
      let range = linoloc_of_textloc ~source ~positionEncoding loc in
      let severity = Linol_lwt.DiagnosticSeverity.Warning in
      Linol.Lsp.Types.Diagnostic.create ~severity ~message:(`String msg) ~range
        ())
    msg

(* let in_file file (e : Diagnosis.t) = *)
(*   let loc_in_file loc = String.equal (Cmarkit.Textloc.file loc) file in *)
(*   let if_non_empty l f = match l with [] -> None | _ :: _ -> Some (f ()) in *)
(*   let open Diagnosis in *)
(*   match e with *)
(*   | DuplicateID e -> *)
(*       let occurrences = List.filter loc_in_file e.occurrences in *)
(*       if_non_empty occurrences @@ fun () -> DuplicateID { e with occurrences } *)
(*   | MissingFile e -> *)
(*       let locs = List.filter loc_in_file e.locs in *)
(*       if_non_empty locs @@ fun () -> MissingFile { e with locs } *)
(*   | WrongType { loc_reason; loc_block; expected_type } -> _ *)
(*   | ParsingError _ -> _ *)
(*   | ParsingWarnor _ -> _ *)
(*   | InconsistentOption _ -> _ *)
(*   | MissingID _ -> _ *)
(*   | UnknownAttribute _ -> _ *)
(*   | UnknownFrontmatterField _ -> _ *)
(*   | FrontmatterParsing _ -> _ *)
(*   | InvalidFrontmatterLine _ -> _ *)
(*   | ChildrenClassWithValue _ -> _ *)

let get_source fpath ~(units : Slipshow.Ast.unit' Fpath.map) =
  match Fpath.Map.find_opt fpath units with
  | Some { source; _ } -> source
  | None -> None

let of_error ~positionEncoding ~(units : Slipshow.Ast.unit' Fpath.map) ~root
    ~file (e : Diagnosis.t) =
  let create ~loc ?ploc s =
    let file = Cmarkit.Textloc.file loc in
    let source = get_source (Fpath.v file) ~units in
    create ~positionEncoding ~source ~loc ?ploc s
  in
  let loc_in_file loc =
    let path1 =
      Fpath.normalize
      @@ Fpath.( // ) (Fpath.parent root) (Fpath.v (Cmarkit.Textloc.file loc))
    in
    let path2 = Fpath.normalize file in
    Fpath.equal path1 path2
  in
  let if_in loc f = if loc_in_file loc then Option.to_list (f ()) else [] in
  match e with
  | DuplicateID { id; occurrences } ->
      let occurrences = List.filter loc_in_file occurrences in
      List.filter_map
        (fun loc -> create ~loc "ID '%s' is not unique in the document" id)
        occurrences
  | MissingFile { file; error_msg; locs } ->
      let locs = List.filter loc_in_file locs in
      let draw_precision =
        if String.ends_with ~suffix:".draw" file then
          "\n\
           Open the record panel in the preview to record and save a draw file."
        else ""
      in
      List.filter_map
        (fun loc ->
          create ~loc "Error when reading file '%s': %s%s" file error_msg
            draw_precision)
        locs
  | WrongType { loc_reason; loc_block = _; expected_type } ->
      if_in loc_reason @@ fun () ->
      create ~loc:loc_reason "This should have a '%s' as target" expected_type
  | ParsingError { action = _; msg; loc } ->
      if_in loc @@ fun () -> create ~loc "%s" msg
  | ParsingWarnor { warnor; loc } ->
      let res =
        match warnor with
        | UnusedArgument { action_name; possible_arguments = []; loc = ploc; _ }
          ->
            if_in loc @@ fun () ->
            create ~loc ~ploc "Action %s takes no named arguments" action_name
        | UnusedArgument
            { action_name; argument_name = _; possible_arguments; loc = ploc }
          ->
            if_in loc @@ fun () ->
            create ~loc ~ploc "Action %s only takes named arguments: '%s'"
              action_name
              (String.concat "', '" possible_arguments)
        | Parsing_failure { msg; loc = ploc } ->
            if_in loc @@ fun () -> create ~loc ~ploc "%s" msg
      in
      res
  | MissingID { id; loc } ->
      if_in loc @@ fun () -> create ~loc "Id '%s' could not be found" id
  | UnknownAttribute { attr; loc } ->
      if_in loc @@ fun () ->
      create ~loc "Attribute '%s' is not known by slipshow" attr
  | UnknownFrontmatterField { key; loc; allowed_keys } ->
      if_in loc @@ fun () ->
      create ~loc
        "Frontmatter field '%s' is not interpreted by slipshow.\n\
         Recognized fields are: '%s'"
        key
        (String.concat "', '" allowed_keys)
  | FrontmatterParsing { key = _; msg; loc } ->
      if_in loc @@ fun () -> create ~loc "%s" msg
  | InvalidFrontmatterLine { loc } ->
      if_in loc @@ fun () ->
      create ~loc
        "Frontmatter have to be of the form \"key:value\" on a single line."
  | ChildrenClassWithValue { loc } ->
      if_in loc @@ fun () -> create ~loc "Children classes cannot have a value"
  | InconsistentOption { option_name; loc1; loc2 } ->
      ( if_in loc1 @@ fun () ->
        create ~loc:loc1
          "option '%s' is defined multiple times in an incompatible way"
          option_name )
      @ if_in loc2
      @@ fun () ->
      create ~loc:loc2
        "option '%s' is defined multiple times in an incompatible way"
        option_name
