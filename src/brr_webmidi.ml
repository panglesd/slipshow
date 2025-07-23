(*----------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr

module Midi = struct
  module Port = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let as_target = Ev.target_of_jv

    let open' p = Fut.of_promise ~ok:ignore @@ Jv.call p "open" [||]
    let close p = Fut.of_promise ~ok:ignore @@ Jv.call p "close" [||]

    let[@inline] get_nullable p prop =
      let v = Jv.get p prop in
      if Jv.is_none v then Jstr.empty else Jv.to_jstr v

    let id p = Jv.Jstr.get p "id"
    let name p = get_nullable p "name"
    let manufacturer p = get_nullable p "manufacturer"
    let version p = get_nullable p "version"
    let type' p = Jv.Jstr.get p "type'"
    let state p = Jv.Jstr.get p "state"
    let connection p = Jv.Jstr.get p "connection"

    let sub_of_port subp p =
      let t = type' p in
      if Jstr.equal t subp then p else
      let exp = Jstr.(v "Excepted " + subp + v " port but found: " + t) in
      Jv.throw (Jstr.append exp t)
  end

  module Input = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let as_target = Ev.target_of_jv
    let as_port = Port.of_jv
    let of_port p = Port.sub_of_port (Jstr.v "input") p
  end

  module Output = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let as_target = Ev.target_of_jv
    let as_port = Port.of_jv
    let of_port p = Port.sub_of_port (Jstr.v "output") p

    let send ?timestamp_ms o msg =
      let args = match timestamp_ms with
      | None -> [| Tarray.to_jv msg |]
      | Some t -> [| Tarray.to_jv msg; Jv.of_float t |]
      in
      match Jv.call o "send" args with
      | exception Jv.Error e -> Error e | s -> Ok()

    let clear o = ignore @@ Jv.call o "clear" [||]
  end

  module Access = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let inputs a f acc =
      let it = Jv.It.iterator (Jv.get a "inputs") in
      let f _ v acc = f v acc in
      Jv.It.fold_bindings ~key:Jv.to_jstr ~value:Output.of_jv f it acc

    let outputs a f acc =
      let it = Jv.It.iterator (Jv.get a "outputs") in
      let f _ v acc = f v acc in
      Jv.It.fold_bindings ~key:Jv.to_jstr ~value:Output.of_jv f it acc

    type opts = Jv.t
    let opts ?sysex ?software () =
      let o = Jv.obj [||] in
      Jv.Bool.set_if_some o "sysex" sysex;
      Jv.Bool.set_if_some o "software" software;
      o

    let of_navigator ?opts n =
      let args = match opts with None -> [||] | Some opts -> [| opts |] in
      Fut.of_promise ~ok:of_jv @@
      Jv.call (Navigator.to_jv n) "requestMIDIAccess" args
  end

  module Ev = struct
    module Message = struct
      type t = Jv.t
      let data e = Tarray.of_jv (Jv.get e "data")
    end
    let midimessage = Ev.Type.create (Jstr.v "midimessage")

    module Connection =  struct
      type t = Jv.t
      let port e = Port.of_jv (Jv.get e "port")
    end
    let statechange = Ev.Type.create (Jstr.v "statechange")
  end
end
