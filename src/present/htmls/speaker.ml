(* let uri typ = *)
(*   let uri = Brr.Window.location Brr.G.window in *)
(*   let uri = *)
(*     Brr.Uri.with_fragment_params uri (Brr.Uri.Params.of_jstr (Jstr.v "")) *)
(*   in *)
(*   let route_segment = *)
(*     let segment = match typ with `OnChange -> "onchange" | `Now -> "now" in *)
(*     [ Jstr.v segment ] *)
(*   in *)
(*   let uri = Brr.Uri.with_path_segments uri route_segment in *)
(*   uri |> Result.get_ok |> Brr.Uri.to_jstr *)

(* let elem = Brr.El.find_first_by_selector (Jstr.v "#iframes") |> Option.get *)

(* let previewer = *)
(*   let initial_stage = *)
(*     Brr.G.window |> Brr.Window.location |> Brr.Uri.fragment |> Jstr.to_string *)
(*     |> int_of_string_opt *)
(*   in *)
(*   let callback i = *)
(*     let old_uri = Brr.Window.location Brr.G.window in *)
(*     match Brr.Uri.scheme old_uri |> Jstr.to_string with *)
(*     | "about" -> () *)
(*     | _ -> *)
(*         let history = Brr.Window.history Brr.G.window in *)
(*         let uri = *)
(*           let fragment = Jstr.v (string_of_int i) in *)
(*           Brr.Uri.with_uri ~fragment old_uri |> Result.get_ok *)
(*         in *)
(*         Brr.Window.History.replace_state ~uri history *)
(*   in *)
(*   Previewer.create_previewer ?initial_stage ~callback ~include_speaker_view:true *)
(*     elem *)

(* let recv () = *)
(*   let open Lwt.Syntax in *)
(*   let _ : unit Lwt.t = *)
(*     let request_and_update typ = *)
(*       let+ x = Js_of_ocaml_lwt.XmlHttpRequest.get (uri typ |> Jstr.to_string) in *)
(*       let raw_data = x.content in *)
(*       let data = Slipshow.string_to_delayed raw_data in *)
(*       Previewer.preview_compiled previewer data *)
(*     in *)
(*     let rec recv () = *)
(*       let* () = request_and_update `OnChange in *)
(*       recv () *)
(*     in *)
(*     let* () = request_and_update `Now in *)
(*     recv () *)
(*   in *)
(*   () *)

(* let () = recv () *)

open Brr

let () = print_endline "yooooooooooooooooooo"

let uri typ =
  let uri = Brr.Window.location Brr.G.window in
  let uri =
    Brr.Uri.with_fragment_params uri (Brr.Uri.Params.of_jstr (Jstr.v ""))
  in
  let route_segment =
    let segment =
      match typ with
      | `OnChange -> "onchange"
      | `Now -> "now"
      | `Event -> "event"
    in
    [ Jstr.v segment ]
  in
  let uri = Brr.Uri.with_path_segments uri route_segment in
  uri |> Result.get_ok |> Brr.Uri.to_jstr

let receive_callback _ = ()

let recv () =
  let open Lwt.Syntax in
  let _ : unit Lwt.t =
    let request_and_update typ =
      let+ x = Js_of_ocaml_lwt.XmlHttpRequest.get (uri typ |> Jstr.to_string) in
      let raw_data = x.content in
      let data = Present_comm.from_string raw_data in
      match data with Some data -> receive_callback data | None -> ()
    in
    let rec recv () =
      let* () = request_and_update `OnChange in
      recv ()
    in
    let* () = request_and_update `Now in
    recv ()
  in
  ()

let ( !! ) = Jstr.v

let send_event c =
  let open Brr_io.Fetch in
  let body = c |> Present_comm.to_string |> ( !! ) |> Body.of_jstr in
  let init = Request.init ~body ~method':!!"post" () in
  let _ = Brr_io.Fetch.url ~init (uri `Event) in
  ()

module Msg = struct
  type msg = Communication.t

  let of_jv m : msg option = m |> Jv.to_string |> Communication.of_string
end

let _unlisten =
  Ev.listen Brr_io.Message.Ev.message
    (fun event ->
      let raw_data : Jv.t = Brr_io.Message.Ev.data (Brr.Ev.as_type event) in
      let msg = Msg.of_jv raw_data in
      match msg with
      | Some { payload = State (new_stage, mode); id = _ } ->
          Console.(log [ "New state:"; new_stage ]);
          let _ = send_event (Send_step (new_stage, mode)) in
          ()
      | Some { payload = Ready; id = _ } -> Console.(log [ "READY" ])
      | _ -> ())
    (Brr.Window.as_target Brr.G.window)

let () = recv ()
