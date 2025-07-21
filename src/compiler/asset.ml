module Uri = struct
  type t = Link of string | Path of Fpath.t

  let of_string s =
    if
      Astring.String.is_infix ~affix:"://" s
      || String.starts_with ~prefix:"//" s
    then Link s
    else Path (Fpath.v s)
end

type t =
  | Local of { mime_type : string option; content : string; path : Fpath.t }
  | Remote of string

let mime_of_ext x = Magic_mime.lookup x

let of_uri ~read_file s =
  match s with
  | Uri.Link s -> Remote s
  | Path p -> (
      let fp = Fpath.normalize p in
      match read_file fp with
      | Ok (Some content) ->
          let mime_type = Some (mime_of_ext (Fpath.filename fp)) in
          Local { mime_type; content; path = fp }
      | Ok None -> Remote (Fpath.to_string p)
      | Error (`Msg e) ->
          Logs.warn (fun f ->
              f "Could not read file: %a. Considering it as an URL. (%s)"
                Fpath.pp p e);
          Remote (Fpath.to_string p))

let of_string ~read_file s = s |> Uri.of_string |> of_uri ~read_file
