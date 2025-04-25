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
  | Local of { mime_type : string option; content : string }
  | Remote of string

(* https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types#image_types *)
let mime_of_ext = function
  | "apng" -> Some "image/apng" (* Animated Portable Network Graphics (APNG) *)
  | "avif" -> Some "image/avif" (*  AV1 Image File Format (AVIF) *)
  | "gif" -> Some "image/gif" (* Graphics Interchange Format (GIF) *)
  | "jpeg" ->
      Some "image/jpeg" (* Joint Photographic Expert Group image (JPEG) *)
  | "png" -> Some "image/png" (* Portable Network Graphics (PNG) *)
  | "svg+xml" -> Some "image/svg+xml" (* Scalable Vector Graphics (SVG) *)
  | "webp" -> Some "image/webp" (* Web Picture format (WEBP) *)
  | _ -> None

let of_uri ~read_file s =
  match s with
  | Uri.Link s -> Remote s
  | Path p -> (
      let fp = Fpath.normalize p in
      match read_file fp with
      | Ok (Some content) ->
          let mime_type = mime_of_ext (Fpath.get_ext fp) in
          Local { mime_type; content }
      | Ok None -> Remote (Fpath.to_string p)
      | Error (`Msg e) ->
          Logs.warn (fun f ->
              f "Could not read file: %a. Considering it as an URL. (%s)"
                Fpath.pp p e);
          Remote (Fpath.to_string p))

let of_string ~read_file s = s |> Uri.of_string |> of_uri ~read_file
