type loc = Cmarkit.Textloc.t

module Error = struct
  type t =
    | DuplicateID of { id : string; previous_occurrence : loc }
    | MissingFile of { file : string; error_msg : string }

  let pp ppf = function
    | DuplicateID id ->
        Format.fprintf ppf "ID '%s' has already been given at %a." id.id
          Cmarkit.Textloc.pp_ocaml id.previous_occurrence
    | MissingFile s ->
        (* ignore s.previous_occurrence; *)
        Format.fprintf ppf "Missing file: %s, considering it as an URL. (%s)"
          s.file s.error_msg
end

type t = { error : Error.t; loc : loc }

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
