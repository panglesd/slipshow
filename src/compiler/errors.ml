type loc = Cmarkit.Textloc.t

module Error = struct
  type t =
    | DuplicateID of { id : string; previous_occurrence : loc }
    | MissingFile of { file : string (* ; previous_occurrence : loc *) }

  let pp ppf = function
    | DuplicateID id ->
        ignore id.previous_occurrence;
        Format.fprintf ppf "Duplicate id: %s" id.id
    | MissingFile s ->
        (* ignore s.previous_occurrence; *)
        Format.fprintf ppf "Missing file: %s" s.file
end

type t = { error : Error.t; loc : loc }

let pp ppf v =
  Format.fprintf ppf "Error at %a:\n%a" Cmarkit.Textloc.pp v.loc Error.pp
    v.error
