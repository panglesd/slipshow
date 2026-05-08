let linoloc_of_textloc (loc : Cmarkit.Textloc.t) =
  let start =
    let line, byte_pos = Cmarkit.Textloc.first_line loc in
    let line = line - 1 in
    let character = Cmarkit.Textloc.first_byte loc - byte_pos in
    Linol_lwt.Position.create ~character ~line
  in
  let end_ =
    let line, byte_pos = Cmarkit.Textloc.last_line loc in
    let line = line - 1 in
    let character = Cmarkit.Textloc.last_byte loc - byte_pos + 1 in
    Linol_lwt.Position.create ~character ~line
  in
  Linol_lwt.Range.create ~end_ ~start

let create ~loc ?ploc msg =
  let loc =
    match ploc with None -> loc | Some ploc -> Diagnosis.loc_of_ploc loc ploc
  in
  let range = linoloc_of_textloc loc in
  let severity = Linol_lwt.DiagnosticSeverity.Warning in
  Format.kasprintf
    (fun msg ->
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

let of_error ~file (e : Diagnosis.t) =
  let loc_in_file loc = String.equal (Cmarkit.Textloc.file loc) file in
  let if_in loc f = if loc_in_file loc then [ f () ] else [] in
  match e with
  | DuplicateID { id; occurrences } ->
      let occurrences = List.filter loc_in_file occurrences in
      List.map
        (fun loc -> create ~loc "ID '%s' is not unique in the document" id)
        occurrences
  | MissingFile { file; error_msg; locs } ->
      let locs = List.filter loc_in_file locs in
      List.map
        (fun loc ->
          create ~loc "Error when reading file '%s': %s" file error_msg)
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
