module Msg = struct
  type msg = Communication.t

  let of_jv m : msg option = m |> Jv.to_string |> Communication.of_string
end

type previewer = { stage : int ref; index : int ref; panels : Brr.El.t array }

let ids = [| "p1"; "p2" |]

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
        let source_name = Jv.get source "name" |> Jv.to_jstr in
        if not (Jstr.equal source_name (Jstr.v "frame")) then ()
        else
          let raw_data : Jv.t = Brr_io.Message.Ev.data (Brr.Ev.as_type event) in
          let msg = Msg.of_jv raw_data in
          match msg with
          | Some { id; payload = State new_stage } when id = ids.(!index) ->
              callback new_stage;
              stage := new_stage
          | Some { id = "p1"; payload = Ready } ->
              index := 0;
              Brr.El.set_class (Jstr.v "active_panel") true panels.(!index);
              Brr.El.set_class (Jstr.v "active_panel") false panels.(1 - !index)
          | Some { id = "p2"; payload = Ready } ->
              index := 1;
              Brr.El.set_class (Jstr.v "active_panel") true panels.(!index);
              Brr.El.set_class (Jstr.v "active_panel") false panels.(1 - !index)
          | _ -> ())
      (Brr.Window.as_target Brr.G.window)
  in
  { stage; index; panels }

let preview { stage; index; panels } source =
  let unused () = 1 - !index in
  let get_starting_state () = (!stage, ids.(unused ())) in
  let set_srcdoc slipshow =
    Jv.set (Brr.El.to_jv panels.(unused ())) "srcdoc" (Jv.of_string slipshow)
  in
  let starting_state = get_starting_state () in
  let slipshow = Slipshow.convert ~starting_state source in
  set_srcdoc slipshow

let preview_compiled { stage; index; panels } delayed =
  let unused () = 1 - !index in
  let get_starting_state () = (!stage, ids.(unused ())) in
  let set_srcdoc slipshow =
    Jv.set (Brr.El.to_jv panels.(unused ())) "srcdoc" (Jv.of_string slipshow)
  in
  let starting_state = Some (get_starting_state ()) in
  let slipshow = Slipshow.add_starting_state delayed starting_state in
  set_srcdoc slipshow
