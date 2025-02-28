let ( let* ) a b = Result.map b a
let ( let+ ) a b = Result.bind a b
let ( let$ ) a b = Option.map b a
let ( let& ) a b = Option.bind a b
let _ = ( let* )
let _ = ( let& )
let _ = ( let$ )

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
      (* let ic = In_channel.open_text (Fpath.to_string f) in *)
      (* Ok In_channel.(input_all ic) *)
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

let to_asset s =
  if Astring.String.is_infix ~affix:"://" s || String.starts_with ~prefix:"//" s
  then Slipshow.Remote s
  else
    let fp = Fpath.v s in
    match Io.read (`File fp) with
    | Ok content ->
        let mime_type = mime_of_ext (Fpath.get_ext fp) in
        Local { mime_type; content }
    | Error (`Msg e) ->
        Logs.warn (fun f ->
            f "Could not read file: %s. Considering it as an URL. (%s)" s e);
        Remote s

let compile ~markdown_mode ~math_link ~slip_css_link ~slipshow_js_link ~input
    ~output ~watch ~serve =
  let math_link = Option.map to_asset math_link in
  let slip_css_link = Option.map to_asset slip_css_link in
  let slipshow_js_link = Option.map to_asset slipshow_js_link in
  let markdown_compile () =
    let+ content = Io.read input in
    let md =
      let md =
        Cmarkit.Doc.of_string ~heading_auto_ids:true ~strict:false content
      in
      Cmarkit_commonmark.of_doc ~include_attributes:false md
    in
    match output with
    | `Stdout ->
        print_string md;
        Ok ()
    | `File output ->
        let* () = Io.write output md in
        ()
  in
  let f () =
    let+ content = Io.read input in
    let html =
      Slipshow.convert ?math_link ?slip_css_link ?slipshow_js_link
        ~resolve_images:to_asset content
    in
    match output with
    | `Stdout ->
        print_string html;
        Ok html
    | `File output ->
        let* () = Io.write output html in
        html
  in
  let rec f2 () =
    let+ content = Io.read input in
    (* Logs.app (fun m -> *)
    (*     m "Here is what we have read %s" *)
    (*       (List.hd @@ String.split_on_char '\n' content)); *)
    if String.equal content "" then f2 ()
    else
      let result =
        Slipshow.delayed ?math_link ?slip_css_link ?slipshow_js_link
          ~resolve_images:to_asset content
      in
      (* let s = Slipshow.add_starting_state result None in *)
      (* let s = *)
      (*   match Astring.String.cut ~sep:"generalized-algebraic" s with *)
      (*   | None -> "NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO" *)
      (*   | Some (_, y) -> ( *)
      (*       match Astring.String.cut ~sep:"quick-intro" y with *)
      (*       | Some (x, _) -> x *)
      (*       | None -> "NAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA") *)
      (* in *)
      (* let () = print_endline s in *)
      Ok result
  in
  if markdown_mode then markdown_compile ()
  else if serve then Serve.do_serve input f2
  else if watch then Serve.do_watch input f
  else
    let+ _html = f () in
    Ok ()
(* do_serve *)
