type loc = int * int
type 'a node = 'a * loc

let range (x, y) (l : 'a node list) : loc =
  let max = List.fold_left (fun max (_, (_, max')) -> Int.max max max') y l in
  (x, max)

type warnor =
  | UnusedArgument of {
      action_name : string;
      argument_name : string;
      possible_arguments : string list;
      loc : loc;
    }
  | Parsing_failure of { msg : string; loc : loc }

type 'a t = 'a * warnor list

let errors_acc : warnor list ref = ref []
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

module M = struct
  let ( let$ ) (x, warnings) f =
    let x, warnings' = f x in
    (x, warnings @ warnings')

  let ( let$+ ) (x, warnings) f =
    let x = f x in
    (x, warnings)
end

module RM = struct
  let ( let$$ ) x f =
    match x with
    | Error _ as e -> e
    | Ok (x, warnings) -> (
        match f x with
        | Error _ as e -> e
        | Ok (x, warnings') -> Ok (x, warnings @ warnings'))
end
