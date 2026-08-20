type t = Link of string | Path of Fpath.t

(** An LLM that reviewed my code nerd-sniped me into improving the detection of
    paths vs url...

    {{:https://www.rfc-editor.org/info/rfc3986/#section-3.1}RFC 3986 §3.1}:
    scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." ), *)
let is_alpha = function 'a' .. 'z' | 'A' .. 'Z' -> true | _ -> false

let is_scheme_char = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '+' | '-' | '.' -> true
  | _ -> false

let has_scheme s =
  match String.index_opt s ':' with
  | Some i when i >= 2 ->
      (* >= 2: for windows's "C:/" style paths that should not be a scheme *)
      is_alpha s.[0]
      && Astring.String.for_all is_scheme_char (String.sub s 1 (i - 1))
  | _ -> false

let is_external s =
  has_scheme s
  || String.starts_with ~prefix:"//" s
  || String.starts_with ~prefix:"#" s
  || String.starts_with ~prefix:"?" s

let of_string ~parent s =
  if is_external s then Ok (Link s)
  else
    match Fpath.of_string s with
    | Ok path -> Ok (Path (Fpath.normalize @@ Fpath.( // ) parent path))
    | Error _ as err -> err

let to_string = function Link s -> s | Path p -> Fpath.to_string p
