type config = Jv.t

let config ?start_version ?clientID () =
  let o = Jv.obj [||] in
  Jv.set_if_some o "startVersion" (Option.map Jv.of_int start_version);
  Jv.set_if_some o "clientID" (Option.map Jv.of_string clientID);
  o

let collab ?config () =
  let g = Jv.get Jv.global "__CM__collab" in
  let args = match config with None -> [||] | Some c -> [| c |] in
  let res = Jv.apply g args in
  Extension.of_jv res

module Update = struct
  type t = Jv.t

  let changes t = Jv.get t "changes" |> Editor.ChangeSet.of_jv
  let clientID t = Jv.get t "clientID" |> Jv.to_string

  let make changes clientID =
    let o = Jv.obj [||] in
    Jv.set o "changes" (Editor.ChangeSet.to_jv changes);
    Jv.set o "clientID" (Jv.of_string clientID);
    o
end

let receiveUpdates state updates =
  let g = Jv.get Jv.global "__CM__receiveUpdates" in
  let updates = Jv.of_list Fun.id updates in
  let res = Jv.apply g [| Editor.State.to_jv state; updates |] in
  Editor.State.Transaction.of_jv res

let sendableUpdates state =
  let g = Jv.get Jv.global "__CM__sendableUpdates" in
  let l = Jv.apply g [| Editor.State.to_jv state |] in
  Jv.to_list
    (fun x -> (x, Jv.get x "origin" |> Editor.State.Transaction.of_jv))
    l

(* let rebaseUpdates updates over = *)
(*   let g = Jv.get Jv.global "__CM__rebaseUpdates" in *)
(*   let l = Jv.apply g [| updates; over |] in *)
(*   Jv.to_list Fun.id l *)

let getSyncedVersion state =
  let g = Jv.get Jv.global "__CM__getSyncedVersion" in
  let l = Jv.apply g [| Editor.State.to_jv state |] in
  Jv.to_int l

let getClientID state =
  let g = Jv.get Jv.global "__CM__getClientID" in
  let l = Jv.apply g [| Editor.State.to_jv state |] in
  Jv.to_string l
