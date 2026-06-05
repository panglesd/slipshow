module Io = struct
  let read input =
    try Bos.OS.File.read input
    with exn -> Error (`Msg (Printexc.to_string exn))
end

let with_ file source s =
  if Fpath.equal file s then Ok (Some source) else Ok None

let fs parent =
 fun s ->
  let ( // ) = Fpath.( // ) in
  let ( let+ ) a b = Result.map b a in
  let fp = Fpath.normalize @@ (parent // s) in
  let+ res = Io.read fp in
  Some res

let combine read_file_1 read_file_2 =
 fun fp ->
  match read_file_1 fp with Ok (Some _) as res -> res | _ -> read_file_2 fp

module Syntax = struct
  let ( ||| ) = combine
end
