module Uri = struct
  type t = Link of string | Path of Fpath.t

  let of_string ~parent s =
    if
      Astring.String.is_infix ~affix:"://" s
      || String.starts_with ~prefix:"//" s
      || String.starts_with ~prefix:"data:" s
    then Link s
    else Path (Fpath.normalize @@ Fpath.( // ) parent (Fpath.v s))

  let to_string = function Link s -> s | Path p -> Fpath.to_string p
end

type t =
  | Local of {
      mime_type : string option;
      content : string option;
      path : Fpath.t;
    }
  | Remote of string

let mime_of_ext x = Magic_mime.lookup x

let of_uri ~read_file s =
  match s with
  | Uri.Link s -> Remote s
  | Path p -> (
      let fp = Fpath.normalize p in
      let mime_type = Some (mime_of_ext (Fpath.filename fp)) in
      match read_file fp with
      | Ok content -> Local { mime_type; content; path = fp }
      | Error (`Msg error_msg) ->
          let locs = [] in
          Diagnosis.add
            (MissingFile { file = Fpath.to_string fp; error_msg; locs });
          Local { mime_type; content = None; path = fp })

let of_string ~parent ~read_file s =
  s |> Uri.of_string ~parent |> of_uri ~read_file
