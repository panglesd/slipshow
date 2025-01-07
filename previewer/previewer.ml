module Msg = struct
  type msg = Communication.t

  let of_jv m : msg = m |> Jv.to_string |> Communication.of_string
end

type previewer = {
  stage : int (* list *) ref;
  index : int ref;
  panels : Brr.El.t array;
}

let string_of_stage stage = string_of_int stage
let ids = [| "p1"; "p2" |]

let create_previewer root =
  let panel1 =
    Brr.El.find_first_by_selector ~root (Jstr.v "#right-panel1") |> Option.get
  in
  let panel2 =
    Brr.El.find_first_by_selector ~root (Jstr.v "#right-panel2") |> Option.get
  in
  let panels = [| panel1; panel2 |] in
  let index = ref 0 in
  let stage = ref 0 in
  let _ =
    Brr.Ev.listen Brr_io.Message.Ev.message
      (fun event ->
        Brr.Console.(log [ "event is "; event ]);
        let source =
          Brr_io.Message.Ev.source (Brr.Ev.as_type event) |> Option.get
        in
        let source_name = Jv.get source "name" |> Jv.to_jstr in
        Brr.Console.(log [ "name is "; source_name ]);
        if not (Jstr.equal source_name (Jstr.v "frame")) then ()
        else
          let raw_data : Jv.t = Brr_io.Message.Ev.data (Brr.Ev.as_type event) in
          let msg = Msg.of_jv raw_data in
          match msg with
          | { id; payload = State new_stage } when id = ids.(!index) ->
              print_endline @@ "updating stage from: " ^ string_of_stage !stage
              ^ " to new stage: " ^ string_of_stage new_stage;
              stage := new_stage
          | { id = "p1"; payload = Ready } ->
              Brr.Console.(log [ "p1 is ready" ]);
              index := 0;
              Brr.El.set_class (Jstr.v "active_panel") true panels.(!index);
              Brr.El.set_class (Jstr.v "active_panel") false panels.(1 - !index)
          | { id = "p2"; payload = Ready } ->
              Brr.Console.(log [ "p2 is ready" ]);
              index := 1;
              Brr.El.set_class (Jstr.v "active_panel") true panels.(!index);
              Brr.El.set_class (Jstr.v "active_panel") false panels.(1 - !index)
          | _ -> ())
      (Brr.Window.as_target Brr.G.window)
  in
  { stage; index; panels }

let preview { stage; index; panels } source =
  let unused () = 1 - !index in
  let get_starting_state () =
    print_endline @@ "Get_starting_state = " ^ string_of_stage !stage ^ "; "
    ^ ids.(unused ());
    (!stage, ids.(unused ()))
  in
  let set_srcdoc slipshow =
    print_endline @@ "Set_srcdoc = " ^ ids.(unused ());
    Jv.set (Brr.El.to_jv panels.(unused ())) "srcdoc" (Jv.of_string slipshow)
  in
  let starting_state = get_starting_state () in
  let slipshow = Slipshow.convert ~starting_state source in
  set_srcdoc slipshow

let preview_compiled { stage; index; panels } delayed =
  let unused () = 1 - !index in
  let get_starting_state () =
    print_endline @@ "Get_starting_state = " ^ string_of_stage !stage ^ "; "
    ^ ids.(unused ());
    (!stage, ids.(unused ()))
  in
  let set_srcdoc slipshow =
    print_endline @@ "Set_srcdoc = " ^ ids.(unused ());
    Jv.set (Brr.El.to_jv panels.(unused ())) "srcdoc" (Jv.of_string slipshow)
  in
  let starting_state = Some (get_starting_state ()) in
  let slipshow = Slipshow.add_starting_state delayed starting_state in
  set_srcdoc slipshow
