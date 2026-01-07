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

let read_file parent () =
  let l = ref Fpath.Set.empty in
  ( l,
    fun s ->
      let ( // ) = Fpath.( // ) in
      let fp = Fpath.normalize @@ (parent // s) in
      let normalized = Fpath.normalize @@ (Fpath.v (Sys.getcwd ()) // fp) in
      l := Fpath.Set.add normalized !l;
      let+ res = Io.read (`File fp) in
      Some res )

let compile ~input ~output ~cli_frontmatter =
  let asset_files, to_asset =
    let used_files, read_file = read_file (Fpath.v "./") () in
    (used_files, Slipshow.Asset.of_string ~read_file)
  in
  let cli_frontmatter =
    Slipshow.Frontmatter.resolve cli_frontmatter ~to_asset
  in
  let* content = Io.read input in
  let used_files, read_file =
    read_file
      (match input with `Stdin -> Fpath.v "./" | `File f -> Fpath.parent f)
      ()
  in
  let html =
    Slipshow.convert ~include_speaker_view:true ~frontmatter:cli_frontmatter
      ~read_file content
  in
  let all_used_files = Fpath.Set.union !asset_files !used_files in
  match output with
  | `Stdout ->
      print_string html;
      Ok all_used_files
  | `File output -> (
      let+ () = Io.write output html in
      match input with
      | `Stdin -> !used_files
      | `File f ->
          Fpath.Set.add
            (Fpath.normalize (Fpath.( // ) (Fpath.v (Sys.getcwd ())) f))
            all_used_files)

let watch ~input ~output ~cli_frontmatter =
  let input = `File input and output = `File output in
  let compile () =
    Logs.app (fun m -> m "Compiling...");
    compile ~input ~output ~cli_frontmatter
  in
  Slipshow_server.do_watch compile

let serve ~input ~output ~cli_frontmatter ~port =
  let compile () =
    let asset_files, to_asset =
      let used_files, read_file = read_file (Fpath.v "./") () in
      (used_files, Slipshow.Asset.of_string ~read_file)
    in
    let cli_frontmatter =
      Slipshow.Frontmatter.resolve cli_frontmatter ~to_asset
    in
    let* content = Io.read (`File input) in
    let used_files, read_file = read_file (Fpath.parent input) () in
    let result =
      Slipshow.delayed ~frontmatter:cli_frontmatter ~read_file content
    in
    let all_used_files = Fpath.Set.union !asset_files !used_files in
    let html =
      Slipshow.add_starting_state ~include_speaker_view:true result None
    in
    let+ () = Io.write output html in
    ( result,
      Fpath.Set.add
        (Fpath.normalize (Fpath.( // ) (Fpath.v (Sys.getcwd ())) input))
        all_used_files )
  in
  Slipshow_server.do_serve ~port compile

let markdown_compile ~input ~output =
  let* content = Io.read input in
  let _used_files, read_file =
    read_file
      (match input with `Stdin -> Fpath.v "./" | `File f -> Fpath.parent f)
      ()
  in
  let md = Slipshow.convert_to_md ~read_file content in
  match output with
  | `Stdout ->
      print_string md;
      Ok ()
  | `File output -> Io.write output md
