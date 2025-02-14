let do_watch _ _ =
  print_endline
    "Watching a file is not supported with the nodejs version. Use the native \
     version (recommended) or an external tool such as inotifywait";
  exit 1

let do_serve _ _ =
  print_endline
    "Serving a file is not supported with the nodejs version. Use the native \
     version (recommended) or external tools such as inotifywait and \
     node-livereload";
  exit 1
