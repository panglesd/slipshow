type 'a versionned = { content : 'a; version : string }
type t = Pong | Update of string versionned

let to_string x = Marshal.to_string x [] |> Base64.encode_string

let of_string s =
  let ( let* ) x f = match x with Ok x -> f x | Error _ -> None in
  let* x = Base64.decode s in
  try Some (Marshal.from_string x 0) with _ -> None
