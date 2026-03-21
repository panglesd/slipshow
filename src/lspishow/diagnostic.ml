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

let of_error (e : Diagnosis.t) =
  match e with
  | DuplicateID { id; occurrences } ->
      List.map
        (fun loc -> create ~loc "ID '%s' is not unique in the document" id)
        occurrences
  | MissingFile { file; error_msg; locs } ->
      List.map
        (fun loc ->
          create ~loc "Error when reading file '%s': %s" file error_msg)
        locs
  | WrongType { loc_reason; loc_block = _; expected_type } ->
      [
        create ~loc:loc_reason "This should have a '%s' as target" expected_type;
      ]
  | ParsingError { action = _; msg; loc } -> [ create ~loc "%s" msg ]
  | ParsingWarnor { warnor; loc } ->
      let res =
        match warnor with
        | UnusedArgument { action_name; possible_arguments = []; loc = ploc; _ }
          ->
            create ~loc ~ploc "Action %s takes no named arguments" action_name
        | UnusedArgument
            { action_name; argument_name = _; possible_arguments; loc = ploc }
          ->
            create ~loc ~ploc "Action %s only takes named arguments: '%s'"
              action_name
              (String.concat "', '" possible_arguments)
        | Parsing_failure { msg; loc = ploc } -> create ~loc ~ploc "%s" msg
      in
      [ res ]
  | MissingID { id; loc } -> [ create ~loc "Id '%s' could not be found" id ]
  | UnknownAttribute { attr; loc } ->
      [ create ~loc "Attribute '%s' is not known by slipshow" attr ]
  | UnknownFrontmatterField { key; loc; allowed_keys } ->
      [
        create ~loc
          "Frontmatter field '%s' is not interpreted by slipshow.\n\
           Recognized fields are: '%s'"
          key
          (String.concat "', '" allowed_keys);
      ]
  | FrontmatterParsing { key = _; msg; loc } -> [ create ~loc "%s" msg ]
  | InvalidFrontmatterLine { loc } ->
      [
        create ~loc
          "Frontmatter have to be of the form \"key:value\" on a single line.";
      ]
  | ChildrenClassWithValue { loc } ->
      [ create ~loc "Children classes cannot have a value" ]
