let version =
  Scanf.sscanf Sys.ocaml_version "%d.%d" (fun major minor -> (major, minor))

let ic =
  if Array.length Sys.argv = 1 then (
    Printf.eprintf
      "Usage: %s <input-file>\n\
       Expecting a filename as argument.\n"
      Sys.argv.(0);
    exit 1
  ) else if not (Sys.file_exists Sys.argv.(1)) then (
    Printf.eprintf
      "Usage: %s <input-file>\n\
       Cannot find file %S.\n"
      Sys.argv.(0)
      Sys.argv.(1);
    exit 1
  ) else
    open_in_bin Sys.argv.(1)

let () =
  let enable_output = ref true in
  let change_output v =
    print_newline ();
    enable_output := v
  in
  try
    while true do
      match input_line ic with
      | "(*BEGIN LETOP*)"       -> change_output (version >= (4, 08))
      | "(*BEGIN INJECTIVITY*)" -> change_output (version >= (4, 12))
      | "(*ELSE*)"              -> change_output (not !enable_output)
      | "(*END*)"               -> change_output true
      | line -> if !enable_output then print_endline line
    done
  with End_of_file -> ()
