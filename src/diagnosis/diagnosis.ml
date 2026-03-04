type loc = Cmarkit.Textloc.t

let loc_of_ploc loc (idx, idx') =
  let open Cmarkit.Textloc in
  let file = file loc in
  let first_line = first_line loc in
  let last_line = first_line in
  let first_byte = first_byte loc + idx in
  let last_byte = first_byte + idx' - idx - 1 in
  v ~file ~first_line ~last_line ~first_byte ~last_byte

type t =
  | DuplicateID of { id : string; occurrences : loc list }
  | MissingFile of { file : string; error_msg : string; locs : loc list }
  | WrongType of { loc_reason : loc; loc_block : loc; expected_type : string }
  | ParsingError of { action : string; msg : string; loc : loc }
  | ParsingWarnor of { warnor : Actions_arguments.W.warnor; loc : loc }
  | MissingID of { id : string; loc : loc }
  | UnknownAttribute of { attr : string; loc : loc }
  | General of {
      code : string;
      msg : string;
      labels : (string * loc) list;
      notes : string list;
    }

(* This is currently used to render issues on things that don't have location:
   mostly CLI input. CLI input have much less errors they can raise, so it's OK
   if (most) of them are not great messages. But I still keep all of those here
   since this function will have some things to be taken for LSP integration. *)
let pp ppf = function
  | DuplicateID id ->
      Format.fprintf ppf "ID '%s' has already been given at %a." id.id
        (Fmt.list Cmarkit.Textloc.pp_ocaml)
        id.occurrences
  | MissingFile s ->
      Format.fprintf ppf "Missing file: %s, considering it as an URL. (%s)"
        s.file s.error_msg
  | WrongType { loc_reason = _; loc_block = _; expected_type } ->
      Format.fprintf ppf "Wrong type: expected type '%s'" expected_type
  | ParsingError { action; msg; loc = _ } ->
      Format.fprintf ppf
        "Parsing of the arguments of actions '%s' failed with '%s'" action msg
  | ParsingWarnor
      { warnor = UnusedArgument { action_name; argument_name; _ }; loc = _ } ->
      Format.fprintf ppf "Action '%s' does not accept argument '%s'" action_name
        argument_name
  | ParsingWarnor { warnor = Parsing_failure { msg; loc = _ }; loc = _ } ->
      Format.fprintf ppf "Action argument parsing failure: %s" msg
  | MissingID { id; loc = _ } ->
      Format.fprintf ppf "Id '%s' could not be found" id
  | General { msg; labels = _; notes = _; code = _ } ->
      Format.fprintf ppf "%s" msg (* TODO: improve *)
  | UnknownAttribute { attr; loc = _ } ->
      Format.fprintf ppf
        "Attribute '%s' is neither a standard HTML attribute nor a slipshow \
         specific one"
        attr

let with_range source_map loc f =
  let open Grace in
  let range (loc : loc) =
    let source = source_map (Cmarkit.Textloc.file loc) in
    let start = Cmarkit.Textloc.first_byte loc in
    let stop = Cmarkit.Textloc.last_byte loc + 1 in
    Range.create ~source (Byte_index.of_int start) (Byte_index.of_int stop)
  in
  try
    let range = range loc in
    Some (f ~range)
  with _ -> None

let to_grace source_map error =
  let open Grace in
  let with_range = with_range source_map in
  match error with
  | DuplicateID { id; occurrences } ->
      let labels =
        List.filter_map
          (fun occ -> with_range occ @@ Diagnostic.Label.primaryf "")
          occurrences
      in
      Some
        (Diagnostic.createf ~labels Warning "ID %s is assigned multiple times"
           id)
  | MissingFile { file; error_msg; locs } ->
      let labels =
        List.filter_map
          (fun loc -> with_range loc @@ Diagnostic.Label.primaryf "")
          locs
      in
      Some
        (Diagnostic.createf ~labels Warning "file '%s' could not be read: %s"
           file error_msg)
  | WrongType { loc_reason; loc_block; expected_type } ->
      let labels =
        List.filter_map Fun.id
          [
            with_range loc_reason
            @@ Diagnostic.Label.primaryf "This expects the id of a %s"
                 expected_type;
            with_range loc_block
            @@ Diagnostic.Label.primaryf "This is not a %s" expected_type;
          ]
      in
      Some (Diagnostic.createf ~labels Warning "Wrong type")
  | ParsingError { action; msg; loc } ->
      let labels =
        List.filter_map Fun.id
          [ with_range loc @@ Diagnostic.Label.primaryf "%s" msg ]
      in
      Some
        (Diagnostic.createf ~labels Warning
           "Action %s arguments could not be parsed" action)
  | ParsingWarnor
      {
        warnor =
          UnusedArgument
            { action_name; argument_name; loc = parse_loc; possible_arguments };
        loc;
      } ->
      let loc = loc_of_ploc loc parse_loc in
      let labels =
        List.filter_map Fun.id
          [
            with_range loc
            @@ Diagnostic.Label.primaryf
                 "Action '%s' does not take argument '%s'" action_name
                 argument_name;
          ]
      in
      let notes =
        match possible_arguments with
        | [] ->
            [
              Diagnostic.Message.createf "'%s' accepts no arguments" action_name;
            ]
        | _ ->
            [
              Diagnostic.Message.createf "'%s' accepts arguments '%s'"
                action_name
                (String.concat "', '" possible_arguments);
            ]
      in
      Some (Diagnostic.createf ~labels ~notes Warning "Invalid action argument")
  | ParsingWarnor { warnor = Parsing_failure { msg; loc = parse_loc }; loc } ->
      let loc = loc_of_ploc loc parse_loc in
      let labels =
        List.filter_map Fun.id
          [ with_range loc @@ Diagnostic.Label.primaryf "%s" msg ]
      in
      Some (Diagnostic.createf ~labels Warning "Failed to parse")
  | MissingID { id; loc } ->
      let labels =
        List.filter_map Fun.id
          [
            with_range loc
            @@ Diagnostic.Label.primaryf
                 "This should be an ID present in the document";
          ]
      in
      Some
        (Diagnostic.createf ~labels Warning "No element with id '%s' was found"
           id)
  | General { msg; labels; notes; code = _ } ->
      let labels =
        List.filter_map
          (fun (msg, loc) ->
            with_range loc @@ Diagnostic.Label.primaryf "%s" msg)
          labels
      in
      let notes =
        List.map (fun msg -> Diagnostic.Message.createf "%s" msg) notes
      in
      Some (Diagnostic.createf ~labels ~notes Warning "%s" msg)
  | UnknownAttribute { attr; loc } ->
      let labels =
        List.filter_map Fun.id
          [ with_range loc @@ Diagnostic.Label.primaryf "" ]
      in
      Some
        (Diagnostic.createf ~labels Warning "Non standard attribute: '%s'" attr)

let errors_acc = ref []
let add x = errors_acc := x :: !errors_acc

let with_ f =
  let old_errors = !errors_acc in
  errors_acc := [];
  let clean_up () =
    let errors = !errors_acc in
    errors_acc := old_errors;
    errors
  in
  try
    let res = f () in
    (res, clean_up ())
  with exn ->
    let _ = clean_up () in
    raise exn

let to_code = function
  | DuplicateID _ -> "DupID"
  | MissingFile _ -> "FSError"
  | WrongType _ -> "WrongType"
  | ParsingError _ -> "ActionParsing"
  | ParsingWarnor _ -> "ActionParsing"
  | MissingID _ -> "IDNotFound"
  | UnknownAttribute _ -> "UnknownAttribute"
  | General { code; _ } -> code

let report_no_src fmt x =
  let msg = Format.asprintf "%a" pp x in
  let msg = Grace.Diagnostic.createf ~labels:[] ~code:x Warning "%s" msg in
  Format.fprintf fmt "%a@.@."
    (Grace_ansi_renderer.pp_diagnostic ?config:None ~code_to_string:to_code)
    msg
