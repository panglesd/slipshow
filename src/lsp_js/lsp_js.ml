module Lsp = Lspishow.Make (Worker_io)

let () =
  let ic = Worker_io.create_in_channel () in
  let res = Lsp.run ic () () in
  match res with Ok _ -> () | Error _ -> ()
