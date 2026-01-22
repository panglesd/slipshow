type loc = Cmarkit.Textloc.t

module Error = struct
  type t =
    | DuplicateID of { id : string; previous_occurrence : loc }
    | MissingFile of { file : string; previous_occurrence : loc }

  let pp ppf = function
    | DuplicateID id ->
        Format.fprintf ppf "Duplicate id: %s (other occurrence at %a)" id.id
          Cmarkit.Textloc.pp_ocaml id.previous_occurrence
    | MissingFile s ->
        Format.fprintf ppf "Missing file: %s (previous occurrence at %a)" s.file
          Cmarkit.Textloc.pp_ocaml s.previous_occurrence
end

type t = { error : Error.t; loc : loc }

let pp ppf v =
  Format.fprintf ppf "Error at %a:\n%a" Cmarkit.Textloc.pp v.loc Error.pp
    v.error
