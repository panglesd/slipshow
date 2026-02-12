open Brr

let ( !! ) = Jstr.v
let () = print_endline "yooooooooooooooooooo"
let current_step = ref 0
let current_vote_result = ref Present_comm.StringMap.empty
let has_voted = Hashtbl.create 10

let uri typ =
  let uri = Brr.Window.location Brr.G.window in
  let uri =
    Brr.Uri.with_fragment_params uri (Brr.Uri.Params.of_jstr (Jstr.v ""))
  in
  let route_segment =
    let segment =
      match typ with `OnChange -> "onchange" | `Event -> "event"
    in
    [ Jstr.v segment ]
  in
  let uri = Uri.with_path_segments uri route_segment |> Result.get_ok in
  let params =
    Uri.Params.of_assoc
      [
        (!!"current_step", !!(string_of_int !current_step));
        ( !!"current_votes",
          !!(string_of_int (Present_comm.total_votes !current_vote_result)) );
      ]
  in
  let uri = Uri.with_query_params uri params in
  uri |> Brr.Uri.to_jstr

let iframe = El.find_first_by_selector !!"#presentation" |> Option.get

let iframe_window =
  Jv.get (Brr.El.to_jv iframe) "contentWindow" |> Brr.Window.of_jv

let slipshow_iframe =
  let root = Window.document iframe_window |> Document.body in
  El.find_first_by_selector ~root !!"iframe" |> Option.get

let receive_callback event =
  match event with
  | Present_comm.Send_step (i, mode) ->
      current_step := i;
      let payload = Communication.Set_state (i, mode) in
      let msg_ =
        (* Currently, the ID does not matter... *)
        { payload; id = "TODO" } |> Communication.to_string |> Jv.of_string
      in
      Console.(log [ "sending"; msg_ ]);
      Brr.Window.post_message iframe_window ~msg:msg_
  | Poll_truth poll ->
      Console.(log [ "YYYYYYYYYYYYYYYYYYYYYYYYYYYY" ]);
      current_vote_result := poll;
      let () =
        let slipshow_window =
          Jv.get (Brr.El.to_jv slipshow_iframe) "contentWindow"
          |> Brr.Window.of_jv
        in
        let slipshow_body = Window.document slipshow_window |> Document.body in
        let root = slipshow_body in
        Present_comm.StringMap.fold
          (fun poll_id results () ->
            Console.(log [ "finding in "; root; "elements with id"; poll_id ]);
            let poll = El.find_first_by_selector ~root !!("#" ^ poll_id) in
            poll
            |> Option.iter @@ fun poll ->
               let children = El.children ~only_els:true poll in
               List.iteri
                 (fun i child ->
                   let result = Present_comm.IntMap.find_opt i results in
                   result
                   |> Option.iter @@ fun result ->
                      let poll =
                        El.find_first_by_selector ~root:child !!".poll-result"
                      in
                      match poll with
                      | None -> ()
                      | Some poll ->
                          let r = El.span [ El.txt' (string_of_int result) ] in
                          El.set_children poll [ r ])
                 children)
          poll ()
      in
      ()
  | Present_comm.Vote _ -> ()

let recv () =
  let open Lwt.Syntax in
  let _ : unit Lwt.t =
    let request_and_update typ =
      let+ x = Js_of_ocaml_lwt.XmlHttpRequest.get (uri typ |> Jstr.to_string) in
      let raw_data = x.content in
      Console.(log [ "YYYYYYYYYYYYYYYYYYYYYYYYYYYY1"; raw_data ]);
      let data = Present_comm.from_string raw_data in
      Console.(log [ "YYYYYYYYYYYYYYYYYYYYYYYYYYYY2" ]);
      match data with Some data -> receive_callback data | None -> ()
    in
    let rec recv () =
      let* () = request_and_update `OnChange in
      recv ()
    in
    recv ()
  in
  ()

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
      (* | Some { payload = State (new_stage, _mode); id = _ } -> *)
      (*     Console.(log [ "New state:"; new_stage ]); *)
      (*     let _ = send_event (`Send_step new_stage) in *)
      (*     () *)
      | Some { payload = Ready; id = _ } ->
          let payload = Communication.Stop_moving in
          let msg_ =
            (* Currently, the ID does not matter... *)
            { payload; id = "TODO" } |> Communication.to_string |> Jv.of_string
          in
          Console.(log [ "sending"; msg_ ]);
          Brr.Window.post_message iframe_window ~msg:msg_
      | Some { payload = Poll_vote { id; vote }; id = _ } ->
          if Hashtbl.mem has_voted id then ()
          else (
            Hashtbl.add has_voted id true;
            let event = Present_comm.Vote { id; vote } in
            send_event event
            (* let payload = Communication.Stop_moving in *)
            (* let msg_ = *)
            (*   (\* Currently, the ID does not matter... *\) *)
            (*   { payload; id = "TODO" } |> Communication.to_string |> Jv.of_string *)
            (* in *)
            (* Console.(log [ "sending"; msg_ ]); *)
            (* Brr.Window.post_message iframe_window ~msg:msg_ *))
      | _ -> ())
    (Brr.Window.as_target Brr.G.window)

let () = recv ()
