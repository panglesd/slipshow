type config = Jv.t

let config ?start_version ?client_id () =
  let o = Jv.obj [||] in
  Jv.set_if_some o "startVersion" (Option.map Jv.of_int start_version);
  Jv.set_if_some o "clientID" (Option.map Jv.of_string client_id);
  o

let collab ?config () =
  let g = Jv.get Jv.global "__CM__collab" in
  let args = match config with None -> [||] | Some c -> [| c |] in
  let res = Jv.apply g args in
  Extension.of_jv res

module Update = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  let changes t = Jv.get t "changes" |> State.ChangeSet.of_jv
  let client_id t = Jv.get t "clientID" |> Jv.to_string

  let make ~changes ~client_id =
    let o = Jv.obj [||] in
    Jv.set o "changes" (State.ChangeSet.to_jv changes);
    Jv.set o "clientID" (Jv.of_string client_id);
    o
end

let receive_updates state updates =
  let g = Jv.get Jv.global "__CM__receiveUpdates" in
  let updates = Jv.of_list Fun.id updates in
  let res = Jv.apply g [| State.EditorState.to_jv state; updates |] in
  State.Transaction.of_jv res

let sendable_updates state =
  let g = Jv.get Jv.global "__CM__sendableUpdates" in
  let l = Jv.apply g [| State.EditorState.to_jv state |] in
  Jv.to_list (fun x -> (x, Jv.get x "origin" |> State.Transaction.of_jv)) l

let get_synced_version state =
  let g = Jv.get Jv.global "__CM__getSyncedVersion" in
  let l = Jv.apply g [| State.EditorState.to_jv state |] in
  Jv.to_int l

let get_client_id state =
  let g = Jv.get Jv.global "__CM__getClientID" in
  let l = Jv.apply g [| State.EditorState.to_jv state |] in
  Jv.to_string l
