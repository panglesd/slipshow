module Msg = struct
  type msg = Communication.t

  let of_jv m : msg option = m |> Jv.to_string |> Communication.of_string
end

type previewer = { stage : int ref; index : int ref; panels : Brr.El.t array }

let ids = [| "slipshow-frame-1"; "slipshow-frame-2" |]

let create_previewer ?(initial_stage = 0) ?(callback = fun _ -> ()) root =
  let panel1 =
    Brr.El.find_first_by_selector ~root (Jstr.v "#right-panel1") |> Option.get
  in
  let panel2 =
    Brr.El.find_first_by_selector ~root (Jstr.v "#right-panel2") |> Option.get
  in
  let panels = [| panel1; panel2 |] in
  let index = ref 0 in
  let stage = ref initial_stage in
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
        | Some { payload = State (new_stage, _mode) }
          when String.equal source_name ids.(!index) ->
            callback new_stage;
            stage := new_stage
        | Some { payload = Ready } when String.equal source_name ids.(!index) ->
            ()
        | Some { payload = Ready } ->
            index := 1 - !index;
            Brr.El.set_class (Jstr.v "active_panel") true panels.(!index);
            Brr.El.set_class (Jstr.v "active_panel") false panels.(1 - !index)
        | _ -> ())
      (Brr.Window.as_target Brr.G.window)
  in
  { stage; index; panels }

let preview { stage; index; panels } source =
  let unused () = 1 - !index in
  let set_srcdoc slipshow =
    Jv.set (Brr.El.to_jv panels.(unused ())) "srcdoc" (Jv.of_string slipshow)
  in
  let starting_state = !stage in
  let slipshow = Slipshow.convert ~starting_state source in
  set_srcdoc slipshow

let preview_compiled { stage; index; panels } delayed =
  let unused () = 1 - !index in
  let set_srcdoc slipshow =
    Jv.set (Brr.El.to_jv panels.(unused ())) "srcdoc" (Jv.of_string slipshow)
  in
  let starting_state = Some !stage in
  let slipshow = Slipshow.add_starting_state delayed starting_state in
  set_srcdoc slipshow
