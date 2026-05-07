let ( let+ ) a b = Result.map b a
let ( let* ) a b = Result.bind a b
let _ = ( let+ )

module Io = struct
  let write filename content =
    try
      (* This test is just to give a better error message *)
      let directory = Fpath.parent filename |> Fpath.to_string in
      if not (Sys.is_directory directory) then
        Error (`Msg (directory ^ "is not a directory"))
      else
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

let with_read_file parent f =
  let l = ref Fpath.Set.empty in
  let read_file =
   fun s ->
    let ( // ) = Fpath.( // ) in
    let fp = Fpath.normalize @@ (parent // s) in
    let normalized = Fpath.normalize @@ (Fpath.v (Sys.getcwd ()) // fp) in
    l := Fpath.Set.add normalized !l;
    let+ res = Io.read (`File fp) in
    Some res
  in
  let res = f read_file in
  (res, !l)

let compile ~input ~output =
  let* content = Io.read input in
  let (html, warnings), used_files =
    let parent =
      match input with `Stdin -> Fpath.v "./" | `File f -> Fpath.parent f
    in
    let file = match input with `File f -> Some f | _ -> None in
    with_read_file parent @@ fun read_file ->
    Slipshow.convert ~has_speaker_view:true ?file ~read_file content
  in
  let () =
    List.iter
      (Format.printf "%a@.@."
         (Grace_ansi_renderer.pp_diagnostic ?config:None
            ~code_to_string:Diagnosis.to_code))
      warnings
  in
  match output with
  | `Stdout ->
      print_string html;
      Ok used_files
  | `File output -> (
      let+ () = Io.write output html in
      match input with
      | `Stdin -> used_files
      | `File f ->
          Fpath.Set.add
            (Fpath.normalize (Fpath.( // ) (Fpath.v (Sys.getcwd ())) f))
            used_files)

let watch ~input ~output =
  let input_fpath = input in
  let input = `File input and output = `File output in
  let compile () =
    Logs.app (fun m -> m "Compiling...");
    compile ~input ~output
  in
  let () = Slipshow_server.do_watch input_fpath compile in
  (* [do_watch] never ends! *)
  Ok ()

let serve ~input ~output ~port =
  let compile () =
    let* content = Io.read (`File input) in
    let (result, warnings), used_files =
      with_read_file (Fpath.parent input) @@ fun read_file ->
      Slipshow.delayed ~has_speaker_view:true ~read_file ~file:input content
    in
    let warnings =
      List.map
        (Format.asprintf "%a@.@."
           (Grace_ansi_renderer.pp_diagnostic ?config:None
              ~code_to_string:Diagnosis.to_code))
        warnings
    in
    let warnings = List.map (Ansi.process (Ansi.create ())) warnings in
    let warnings = warnings |> String.concat "" in
    let html = Slipshow.add_starting_state result None in
    let+ () = Io.write output html in
    ( (result, warnings),
      Fpath.Set.add
        (Fpath.normalize (Fpath.( // ) (Fpath.v (Sys.getcwd ())) input))
        used_files )
  in
  let () = Slipshow_server.do_serve ~port input compile in
  (* [do_serve] never ends! *)
  Ok ()

let markdown_compile ~input ~output =
  let* content = Io.read input in
  let md, _used_files =
    with_read_file
      (match input with `Stdin -> Fpath.v "./" | `File f -> Fpath.parent f)
    @@ fun read_file -> Slipshow.convert_to_md ~read_file content
  in
  match output with
  | `Stdout ->
      print_string md;
      Ok ()
  | `File output -> Io.write output md
