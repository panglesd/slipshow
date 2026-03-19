type 'a versionned = { content : 'a; version : string }

module Marhsarializing = struct
  let to_string x = Marshal.to_string x [] |> Base64.encode_string

  let of_string s =
    let ( let* ) x f = match x with Ok x -> f x | Error _ -> None in
    let* x = Base64.decode s in
    try Some (Marshal.from_string x 0) with _ -> None
end

module Client_to_server = struct
  type t = Ping | UpdateFrom of string

  include Marhsarializing
end

module Server_to_client = struct
  type t = Pong | Update of (Slipshow.delayed * string) versionned

  include Marhsarializing
end
