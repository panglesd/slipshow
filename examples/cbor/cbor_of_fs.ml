
module C = CBOR.Simple

let rec fs_to_cbor ~path (f:string) : C.t =
  let file = Filename.concat path f in
  if not @@ Sys.file_exists file then `Text "<not found>"
  else if Sys.is_directory file then (
    try
      let dir = Sys.readdir file in
      `Map [
        `Text f,
        `Array (Array.map (fs_to_cbor ~path:file) dir |> Array.to_list)
      ]
    with e ->
      `Text (Printf.sprintf "<exn for dir %S: %s>" f (Printexc.to_string e))
  ) else (
    let content =
      try
        let s = CCIO.with_in file CCIO.read_all in
        if CCUtf8_string.is_valid s then `Text s else `Bytes s
      with _e ->
        `Text "<read error>"
      in
    `Map [ `Text f, content ]
  )

let () =
  let out = ref "" in
  let dirs = ref [] in
  Arg.parse (Arg.align [
      "-o", Arg.Set_string out, " output file";
    ]) (fun x -> dirs := x :: !dirs) "cbor_of_fs -o <out> <dir>+";
  if !out = "" then failwith "-o is required";
  if !dirs = [] then failwith "please provide at least one directory to pack";
  let cs = List.map (fs_to_cbor ~path:"") !dirs in
  let c = match cs with [x] -> x | _ -> `Array cs in
  Format.printf "write CBOR to %s@." (Filename.quote !out);
  CCIO.with_out !out
    (fun oc -> output_string oc @@ C.encode c)

