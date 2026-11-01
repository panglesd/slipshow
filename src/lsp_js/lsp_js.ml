module Lsp =
  Lspishow.Make
    (Worker_io)
    (struct
      let sleep = Js_of_ocaml_lwt.Lwt_js.sleep
      let start_preview ~send_info:_ ~to_lsp_server:_ _roots = ()
    end)

let () =
  let ic = Worker_io.create_in_channel () in
  Lwt.async (fun () -> Lsp.run ic () ())
