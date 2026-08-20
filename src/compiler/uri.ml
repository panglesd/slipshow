type t = Link of string | Path of Fpath.t

let of_string ~parent s =
  if
    Astring.String.is_infix ~affix:"://" s
    || String.starts_with ~prefix:"//" s
    || String.starts_with ~prefix:"data:" s
  then Ok (Link s)
  else
    match Fpath.of_string s with
    | Ok path -> Ok (Path (Fpath.normalize @@ Fpath.( // ) parent path))
    | Error _ as err -> err

let to_string = function Link s -> s | Path p -> Fpath.to_string p
