module Msg = struct
  type msg = Communication.t

  let of_jv m : msg option = m |> Jv.to_string |> Communication.of_string
end

type previewer = {
  stage : int ref;
  index : int ref;
  panels : Brr.El.t array;
  ids : string * string;
}

let send_speaker_view oc panel =
  let payload =
    match oc with
    | `Open -> Communication.Open_speaker_notes
    | `Close -> Close_speaker_notes
  in
  let content_window w =
    Jv.get (Brr.El.to_jv w) "contentWindow" |> Brr.Window.of_jv
  in
  let window = content_window panel in
  let msg =
    (* Currently, the ID does not matter... *)
    { payload; id = "TODO" } |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message window ~msg

let send_next panel =
  let payload = Communication.Next in
  let content_window w =
    Jv.get (Brr.El.to_jv w) "contentWindow" |> Brr.Window.of_jv
  in
  let window = content_window panel in
  let msg =
    (* Currently, the ID does not matter... *)
    { payload; id = "TODO" } |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message window ~msg

let send_previous panel =
  let payload = Communication.Previous in
  let content_window w =
    Jv.get (Brr.El.to_jv w) "contentWindow" |> Brr.Window.of_jv
  in
  let window = content_window panel in
  let msg =
    (* Currently, the ID does not matter... *)
    { payload; id = "TODO" } |> Communication.to_string |> Jv.of_string
  in
  Brr.Window.post_message window ~msg

let () = Random.self_init ()

let create_previewer ?(initial_stage = 0) ?(callback = fun _ -> ()) root =
  let ( !! ) = Jstr.v in
  let name1 = Random.int 1000000 |> string_of_int |> fun s -> "id" ^ s in
  let name2 = Random.int 1000000 |> string_of_int |> fun s -> "id" ^ s in
  let ids = [| name1; name2 |] in
  let panel1 =
    Brr.El.iframe ~at:[ Brr.At.name !!name1; Brr.At.class' !!"right-panel1" ] []
  in
  let panel2 =
    Brr.El.iframe ~at:[ Brr.At.name !!name2; Brr.At.class' !!"right-panel2" ] []
  in
  let () = Brr.El.append_children root [ panel1; panel2 ] in
  let panels = [| panel1; panel2 |] in
  let index = ref 0 in
  let stage = ref initial_stage in
  let is_speaker_view_open = ref false in

  let _ =
    Brr.Ev.listen Brr_io.Message.Ev.message
      (fun event ->
        let source =
          Brr_io.Message.Ev.source (Brr.Ev.as_type event) |> Option.get
        in
        let source_name = Jv.get source "name" |> Jv.to_string in
        let raw_data : Jv.t = Brr_io.Message.Ev.data (Brr.Ev.as_type event) in
        let msg = Msg.of_jv raw_data in
        match msg with
        | Some { payload = State (new_stage, _mode); id = _ }
          when String.equal source_name ids.(!index) ->
            callback new_stage;
            stage := new_stage
        | Some { payload = Open_speaker_notes; id = _ }
          when String.equal source_name ids.(!index) ->
            is_speaker_view_open := true
        | Some { payload = Close_speaker_notes; id = _ }
          when String.equal source_name ids.(!index) ->
            is_speaker_view_open := false
        | Some { payload = Ready; id = _ }
          when String.equal source_name ids.(!index) ->
            ()
        | Some { payload = Ready; id }
          when String.equal source_name ids.(1 - !index) ->
            Brr.Console.(log [ "Getting a strange input"; id ]);
            if !is_speaker_view_open then (
              send_speaker_view `Close panels.(!index);
              send_speaker_view `Open panels.(1 - !index));
            index := 1 - !index;
            Brr.El.set_class (Jstr.v "active_panel") true panels.(!index);
            (* let contentDocument el = *)
            (*   Jv.get (Brr.El.to_jv el) "contentDocument" |> Brr.Document.of_jv *)
            (* in *)
            (* let inner_iframe = *)
            (*   panels.(!index) |> contentDocument |> fun d -> *)
            (*   Brr.Document.find_el_by_id d (Jstr.v "slipshow__internal_iframe") *)
            (*   |> Option.get *)
            (* in *)
            (* let () = Brr.El.set_has_focus true inner_iframe in *)
            Brr.El.set_class (Jstr.v "active_panel") false panels.(1 - !index)
        | _ -> ())
      (Brr.Window.as_target Brr.G.window)
  in
  { stage; index; panels; ids = (name1, name2) }

let set_srcdoc { index; panels; _ } slipshow =
  try Jv.set (Brr.El.to_jv panels.(1 - !index)) "srcdoc" (Jv.of_string slipshow)
  with _ -> Brr.Console.(log [ "XXX exception" ])

let preview ?slipshow_js ?frontmatter ?read_file previewer source =
  let starting_state = !(previewer.stage) in
  let slipshow =
    Slipshow.convert ~include_speaker_view:false ?slipshow_js ?frontmatter
      ?read_file ~autofocus:false ~starting_state source
  in
  set_srcdoc previewer slipshow

let preview_compiled previewer delayed =
  let starting_state = Some !(previewer.stage) in
  let slipshow =
    Slipshow.add_starting_state ~include_speaker_view:false delayed
      starting_state
  in
  set_srcdoc previewer slipshow

let ids { ids; _ } = ids

let next (previewer : previewer) =
  let current_window = previewer.panels.(!(previewer.index)) in
  send_next current_window

let previous (previewer : previewer) =
  let current_window = previewer.panels.(!(previewer.index)) in
  send_previous current_window
