let () =
  print_endline
  @@
  match Sys.argv.(1) with
  | "aarch64-unknown-linux-musl" | "x86_64-pc-linux-musl" ->
      "(-cclib -static -cclib -no-pie)"
  | _ -> "(-cclib -static -cclib -no-pie)"
