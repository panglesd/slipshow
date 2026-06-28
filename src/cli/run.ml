let ( let+ ) a b = Result.map b a
let ( let* ) a b = Result.bind a b
let () = ignore ( let* )

module Io = struct
  let write filename content =
    try
      (* This test is just to give a better error message *)
      let directory = Fpath.parent filename |> Fpath.to_string in
      if not (Sys.is_directory directory) then
        Error (`Msg (directory ^ " is not a directory"))
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
    if Fpath.equal (Fpath.v "-") s then
      let+ res = Io.read `Stdin in
      Some res
    else
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
  let (html, warnings), used_files =
    let parent, file =
      match input with
      | `Stdin -> (Fpath.v "./", Fpath.v "-")
      | `File f -> Fpath.split_base f
    in
    with_read_file parent @@ fun read_file ->
    Slipshow.convert ~directory:parent ~has_speaker_view:true ~read_file file
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
    let res, war =
      let parent, input = Fpath.split_base input in
      with_read_file parent @@ fun read_file ->
      let result, warnings =
        Slipshow.Compile.compile_all ~directory:parent ~read_file
          Fpath.Map.empty input
      in
      let result' = Slipshow.delayed_from_units ~has_speaker_view:true result in
      let html = Slipshow.add_starting_state result' None in
      let+ () = Io.write output html in
      (* TODO: display warnings somehow *)
      (result, warnings)
    in
    let+ res = res in
    (res, war)
  in
  let () = Slipshow_server.do_serve ~port input compile in
  (* [do_serve] never ends! *)
  Ok ()

let markdown_compile ~input ~output =
  let parent, file =
    match input with
    | `Stdin -> (Fpath.v "./", Fpath.v "-")
    | `File f -> Fpath.split_base f
  in
  let md, _used_files =
    with_read_file parent @@ fun read_file ->
    Slipshow.convert_to_md ~directory:parent ~read_file file
  in
  match output with
  | `Stdout ->
      print_string md;
      Ok ()
  | `File output -> Io.write output md
