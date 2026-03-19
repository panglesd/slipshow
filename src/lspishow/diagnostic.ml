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

let of_error (e : Diagnosis.t) =
  match e with
  | DuplicateID _ -> [] (* TODO: do *)
  | MissingFile { file; error_msg; locs } ->
      List.map
        (fun loc ->
          let range = linoloc_of_textloc loc in
          let message =
            Format.asprintf "Error when reading file '%s': %s" file error_msg
          in
          Linol.Lsp.Types.Diagnostic.create ~message:(`String message) ~range ())
        locs
  | WrongType { loc_reason; loc_block = _; expected_type } ->
      let range = linoloc_of_textloc loc_reason in
      let message =
        Format.asprintf "This should have a '%s' as target" expected_type
      in
      [ Linol.Lsp.Types.Diagnostic.create ~message:(`String message) ~range () ]
  | ParsingError { action = _; msg; loc } ->
      let range = linoloc_of_textloc loc in
      [ Linol.Lsp.Types.Diagnostic.create ~message:(`String msg) ~range () ]
  | ParsingWarnor { warnor; loc } ->
      let msg, range =
        match warnor with
        | UnusedArgument
            {
              action_name;
              argument_name = _;
              possible_arguments = [];
              loc = ploc;
            } ->
            let range = linoloc_of_textloc (Diagnosis.loc_of_ploc loc ploc) in
            ( Format.asprintf "Action %s takes no named arguments" action_name,
              range )
        | UnusedArgument
            { action_name; argument_name = _; possible_arguments; loc = ploc }
          ->
            let range = linoloc_of_textloc (Diagnosis.loc_of_ploc loc ploc) in
            ( Format.asprintf "Action %s only takes named arguments: %s"
                action_name
                (String.concat "', '" possible_arguments),
              range )
        | Parsing_failure { msg; loc = ploc } ->
            let range = linoloc_of_textloc (Diagnosis.loc_of_ploc loc ploc) in
            (msg, range)
      in
      [ Linol.Lsp.Types.Diagnostic.create ~message:(`String msg) ~range () ]
  | MissingID { id; loc } ->
      let range = linoloc_of_textloc loc in
      let msg = Format.asprintf "Id '%s' could not be found" id in
      [ Linol.Lsp.Types.Diagnostic.create ~message:(`String msg) ~range () ]
  | UnknownAttribute { attr; loc } ->
      let range = linoloc_of_textloc loc in
      let msg =
        Format.asprintf "Attribute '%s' is not known by slipshow" attr
      in
      [ Linol.Lsp.Types.Diagnostic.create ~message:(`String msg) ~range () ]
  | General _ -> (* TODO: do *) []
