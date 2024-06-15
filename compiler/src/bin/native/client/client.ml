let uri typ =
  let uri = Brr.Window.location Brr.G.window in
  let uri =
    Brr.Uri.with_fragment_params uri (Brr.Uri.Params.of_jstr (Jstr.v ""))
  in
  let route_segment =
    let segment = match typ with `OnChange -> "onchange" | `Now -> "now" in
    [ Jstr.v segment ]
  in
  let uri = Brr.Uri.with_path_segments uri route_segment in
  uri |> Result.get_ok |> Brr.Uri.to_jstr

let elem = Brr.El.find_first_by_selector (Jstr.v "#iframes") |> Option.get
let previewer = Previewer.create_previewer elem

let recv () =
  let open Lwt.Syntax in
  let _ : unit Lwt.t =
    let request_and_update typ =
      let+ x = Js_of_ocaml_lwt.XmlHttpRequest.get (uri typ |> Jstr.to_string) in
      let raw_data = x.content in
      let data = Slipshow.string_to_delayed raw_data in
      Previewer.preview_compiled previewer data
    in
    let rec recv () =
      let* () = request_and_update `OnChange in
      recv ()
    in
    let* () = request_and_update `Now in
    recv ()
  in
  ()

let () = recv ()
