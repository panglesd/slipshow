let ( let+ ) a b = Result.map b a
let ( let* ) a b = Result.bind a b
let _ = ( let+ )

module Io = struct
  let write filename content =
    try
      Out_channel.with_open_text (Fpath.to_string filename) @@ fun oc ->
      Out_channel.output_string oc content;
      Ok ()
    with exn -> Error (`Msg (Printexc.to_string exn))

  let read input =
    try
      match input with
      | `Stdin -> Ok In_channel.(input_all stdin)
      | `File f -> Bos.OS.File.read f
    with exn -> Error (`Msg (Printexc.to_string exn))
end

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

let to_asset input () =
  let l = ref Fpath.Set.empty in
  let parent = Fpath.parent input in
  ( l,
    fun s ->
      if
        Astring.String.is_infix ~affix:"://" s
        || String.starts_with ~prefix:"//" s
      then Slipshow.Remote s
      else
        let fp = Fpath.normalize @@ Fpath.( // ) parent @@ Fpath.v s in
        match Io.read (`File fp) with
        | Ok content ->
            l := Fpath.Set.add fp !l;
            let mime_type = mime_of_ext (Fpath.get_ext fp) in
            Local { mime_type; content }
        | Error (`Msg e) ->
            Logs.warn (fun f ->
                f "Could not read file: %s. Considering it as an URL. (%s)" s e);
            Remote s )

let parse_theme to_asset theme =
  match Themes.of_string theme with
  | Some theme -> `Builtin theme
  | None -> `External (to_asset theme)

let compile ~input ~output ~math_link ~css_links ~theme =
  let used_files, to_asset =
    to_asset (match input with `Stdin -> Fpath.v "./" | `File f -> f) ()
  in
  let math_link = Option.map to_asset math_link in
  let css_links = List.map to_asset css_links in
  let theme = Option.map (parse_theme to_asset) theme in
  let* content = Io.read input in
  let html =
    Slipshow.convert ?math_link ~resolve_images:to_asset ~css_links ?theme
      content
  in
  match output with
  | `Stdout ->
      print_string html;
      Ok !used_files
  | `File output -> (
      let+ () = Io.write output html in
      match input with
      | `Stdin -> !used_files
      | `File f -> Fpath.Set.add f !used_files)

let watch ~input ~output ~math_link ~css_links ~theme =
  let input = `File input and output = `File output in
  let compile () =
    Logs.app (fun m -> m "Compiling...");
    compile ~input ~output ~math_link ~css_links ~theme
  in
  Slipshow_server.do_watch compile

let serve ~input ~output ~math_link ~css_links ~theme =
  let _recorded_assets, to_asset = to_asset input () in
  let input_f = `File input and output = `File output in
  let math_link_asset = Option.map to_asset math_link in
  let f () =
    let* content = Io.read input_f in
    let* used_files =
      compile ~input:input_f ~output ~math_link ~css_links ~theme
    in
    let theme = Option.map (parse_theme to_asset) theme in
    let result =
      Slipshow.delayed ?math_link:math_link_asset ?theme
        ~resolve_images:to_asset content
    in
    Ok (result, used_files)
  in
  Slipshow_server.do_serve input f

let markdown_compile ~input ~output =
  let* content = Io.read input in
  let md = Slipshow.convert_to_md content in
  match output with
  | `Stdout ->
      print_string md;
      Ok ()
  | `File output -> Io.write output md
