open Brr

module Msg = struct
  type msg = Communication.t

  let of_jv m : msg option = m |> Jv.to_string |> Communication.of_string
end

type previewer = {
  stage : int ref;
  index : int ref;
  panels : Brr.El.t array;
  errors_el : Brr.El.t;
  preview_status : Brr.El.t;
  ids : string * string;
  include_speaker_view : bool;
}

let send_speaker_view oc panel =
  let payload =
    match oc with
    | `Open -> Communication.Open_speaker_notes
    | `Close -> Close_speaker_notes
  in
  let content_window w =
    Jv.get (Brr.El.to_jv w) "contentWindow" |> Window.of_jv
  in
  let window = content_window panel in
  let msg =
    (* Currently, the ID does not matter... *)
    { payload; id = "TODO" } |> Communication.to_string |> Jv.of_string
  in
  Window.post_message window ~msg

let () = Random.self_init ()

let css =
  {|
.right-panel1.active_panel, .right-panel2.active_panel {
  z-index: 1;
}
.right-panel1, .right-panel2 {
    z-index: 0;
    width:100%;
    position:absolute;
    top:0;
    bottom:0;
    left:0;
    right:0;
    border:0;
    height:100%
}
.preview-status-elem {
    position: absolute;
    top: 20px;
    right: 132px;
    width: 50px;
    height: 50px;
    z-index: 10;
    display: block;

    border: 5px solid rgba(150, 150, 150);
    border-top: 5px solid #3498db;
    border-radius: 50%;
    animation: spin 1s linear infinite;
}

/* Define the rotation */
@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

/* Hide when active */
.preview-status-elem.preview-status {
    display: none;
}|}

let preview_status_class = Jstr.v "preview-status"

let create_previewer ?(initial_stage = 0) ?(callback = fun _ -> ())
    ~include_speaker_view ~errors_el ~steal_focus root =
  let ( !! ) = Jstr.v in
  let name1 = Random.int 1000000 |> string_of_int |> fun s -> "id" ^ s in
  let name2 = Random.int 1000000 |> string_of_int |> fun s -> "id" ^ s in
  let ids = [| name1; name2 |] in
  let panel1 =
    El.iframe ~at:[ At.name !!name1; At.class' !!"right-panel1" ] []
  in
  let panel2 =
    El.iframe ~at:[ At.name !!name2; At.class' !!"right-panel2" ] []
  in
  let preview_status =
    El.div ~at:[ At.class' !!"preview-status-elem preview-status" ] []
  in
  let css = El.style [ El.txt' css ] in
  let () = El.append_children root [ panel1; panel2; css; preview_status ] in
  let panels = [| panel1; panel2 |] in
  let index = ref 0 in
  let stage = ref initial_stage in
  let is_speaker_view_open = ref false in

  let _ =
    Ev.listen Brr_io.Message.Ev.message
      (fun event ->
        let ( let> ) x f = Option.iter f x in
        let> source = Brr_io.Message.Ev.source (Ev.as_type event) in
        let source_name = Jv.get source "name" |> Jv.to_string in
        let raw_data : Jv.t = Brr_io.Message.Ev.data (Ev.as_type event) in
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
        | Some { payload = Ready; id = _ }
          when String.equal source_name ids.(1 - !index) ->
            Jv.set (El.to_jv panels.(!index)) "srcdoc" (Jv.of_string "");
            let () = El.set_class preview_status_class true preview_status in
            if !is_speaker_view_open then
              send_speaker_view `Open panels.(1 - !index);
            index := 1 - !index;
            El.set_class (Jstr.v "active_panel") true panels.(!index);
            let () =
              if steal_focus then
                let contentDocument el =
                  Jv.get (El.to_jv el) "contentDocument" |> Document.of_jv
                in
                (* Depending on whether a speaker view is possible, the focus
                   target is not accessible the same way *)
                let focus_target =
                  let d = contentDocument panels.(!index) in
                  match
                    Document.find_el_by_id d
                      (Jstr.v "slipshow__internal_iframe")
                  with
                  | Some iframe -> iframe
                  | None -> panels.(!index)
                in
                El.set_has_focus true focus_target
            in
            El.set_class (Jstr.v "active_panel") false panels.(1 - !index)
        | _ -> ())
      (Window.as_target G.window)
  in
  {
    stage;
    index;
    panels;
    ids = (name1, name2);
    include_speaker_view;
    errors_el;
    preview_status;
  }

let set_errors errors_el warnings =
  let innerhtml el v =
    let _ = Jv.set (El.to_jv el) "innerHTML" (Jv.of_string v) in
    ()
  in
  innerhtml errors_el warnings

let set_srcdoc { index; panels; errors_el; _ } (slipshow, warnings) =
  set_errors errors_el warnings;
  try Jv.set (El.to_jv panels.(1 - !index)) "srcdoc" (Jv.of_string slipshow)
  with _ -> Console.(log [ "XXX exception" ])

let preview ?slipshow_js ?frontmatter ?read_file previewer source =
  let () = El.set_class preview_status_class false previewer.preview_status in
  let starting_state = !(previewer.stage) in
  let has_speaker_view = previewer.include_speaker_view in
  let slipshow, warnings =
    Slipshow.convert ~file:"-" ~has_speaker_view ?slipshow_js ?frontmatter
      ?read_file ~autofocus:false ~starting_state source
  in
  let warnings =
    List.map
      (Format.asprintf "%a@.@."
         (Grace_ansi_renderer.pp_diagnostic ?config:None
            ~code_to_string:Diagnosis.to_code))
      warnings
    |> List.map (Ansi.process (Ansi.create ()))
    |> String.concat ""
  in
  set_srcdoc previewer (slipshow, warnings)

let preview_compiled previewer (delayed, warnings) =
  let () = El.set_class preview_status_class false previewer.preview_status in
  let starting_state = Some !(previewer.stage) in
  let slipshow = Slipshow.add_starting_state delayed starting_state in
  set_srcdoc previewer (slipshow, warnings)

let ids { ids; _ } = ids
