module Msg = struct
  type msg = Communication.t

  let of_jv m : msg option = m |> Jv.to_string |> Communication.of_string
end

let iframe = Brr.El.find_first_by_selector (Jstr.v "#ifra") |> Option.get

let _ =
  Brr.Ev.listen Brr_io.Message.Ev.message
    (fun event ->
      let source =
        Brr_io.Message.Ev.source (Brr.Ev.as_type event) |> Option.get
      in
      let source_name = Jv.get source "name" |> Jv.to_jstr in
      if not (Jstr.equal source_name (Jstr.v "slipshow_main_pres")) then ()
      else
        let raw_data : Jv.t = Brr_io.Message.Ev.data (Brr.Ev.as_type event) in
        let msg = Msg.of_jv raw_data in
        match msg with
        | Some { id = "hello"; payload = Open_speaker_notes } ->
            Brr.Console.(log [ "Receiving an order to open the speaker notes" ]);
            ()
        | Some { id = "hello"; payload = _ } ->
            Brr.Console.(log [ "azert" ]);
            ()
        | _ -> ())
    (Brr.Window.as_target Brr.G.window)

let () = Brr.Console.(log [ "yo" ])
let () = Speaker_notes.x
