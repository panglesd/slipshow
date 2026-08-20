type t = Link of string | Path of Fpath.t

let of_string ~parent s =
  if
    Astring.String.is_infix ~affix:"://" s
    || String.starts_with ~prefix:"//" s
    || String.starts_with ~prefix:"data:" s
  then Link s
  else Path (Fpath.normalize @@ Fpath.( // ) parent (Fpath.v s))

let to_string = function Link s -> s | Path p -> Fpath.to_string p
