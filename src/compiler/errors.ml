type loc = Cmarkit.Textloc.t

module Error = struct
  type t =
    | DuplicateID of { id : string; previous_occurrence : loc }
    | MissingFile of { file : string; error_msg : string }
    | WrongType of unit
    | ParsingError of { action : string; msg : string }

  let pp ppf = function
    | DuplicateID id ->
        Format.fprintf ppf "ID '%s' has already been given at %a." id.id
          Cmarkit.Textloc.pp_ocaml id.previous_occurrence
    | MissingFile s ->
        (* ignore s.previous_occurrence; *)
        Format.fprintf ppf "Missing file: %s, considering it as an URL. (%s)"
          s.file s.error_msg
    | WrongType () -> Format.fprintf ppf "Wrong type"
    | ParsingError { action; msg } ->
        Format.fprintf ppf
          "Parsing of the arguments of actions '%s' failed with '%s'" action msg
end

type t = { error : Error.t; loc : loc }

let to_grace source_map { error; loc } =
  match error with
  | DuplicateID { id; previous_occurrence } ->
      let open Grace in
      let range (loc : loc) =
        let source = source_map (Cmarkit.Textloc.file loc) in
        let start = Cmarkit.Textloc.first_byte loc in
        let stop = Cmarkit.Textloc.last_byte loc + 1 in
        Range.create ~source (Byte_index.of_int start) (Byte_index.of_int stop)
      in
      Some
        Diagnostic.(
          createf
            ~labels:
              Label.
                [
                  primaryf ~range:(range loc) "";
                  primaryf ~range:(range previous_occurrence) "";
                ]
            ~code:error Error "ID %s is assigned multiple times" id)
  | MissingFile _ -> None
  | WrongType _ -> None
  | ParsingError _ -> None

let pp ppf v =
  Format.fprintf ppf "Error at %a:\n%a" Cmarkit.Textloc.pp_ocaml v.loc Error.pp
    v.error

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
    let _ = clean_up in
    raise exn

let to_code = function
  | Error.DuplicateID _ -> "DupID"
  | MissingFile _ -> "File"
  | WrongType _ -> "WrongType"
  | ParsingError _ -> "ActionParsing"
