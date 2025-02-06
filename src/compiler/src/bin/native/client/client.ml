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

let previewer =
  let initial_stage =
    Brr.G.window |> Brr.Window.location |> Brr.Uri.fragment |> Jstr.to_string
    |> int_of_string_opt
  in
  let callback i =
    let old_uri = Brr.Window.location Brr.G.window in
    match Brr.Uri.scheme old_uri |> Jstr.to_string with
    | "about" -> ()
    | _ ->
        let history = Brr.Window.history Brr.G.window in
        let uri =
          let fragment = Jstr.v (string_of_int i) in
          Brr.Uri.with_uri ~fragment old_uri |> Result.get_ok
        in
        Brr.Window.History.replace_state ~uri history
  in
  Previewer.create_previewer ?initial_stage ~callback elem

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
