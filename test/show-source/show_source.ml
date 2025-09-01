open Soup

let () =
  let content = read_file Sys.argv.(1) |> parse in
  let iframe = content $ "#slipshow__internal_iframe" in
  let a = R.attribute "srcdoc" iframe in
  print_endline a
