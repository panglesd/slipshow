(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr
open Brr_io

module Worker = struct
  module Type = struct
    type t = Jstr.t
    let classic = Jstr.v "classic"
    let module' = Jstr.v "module"
  end
  type opts = Jv.t
  let opts ?type' ?credentials ?name () =
    let o = Jv.obj' [||] in
    Jv.Jstr.set_if_some o "type" type';
    Jv.Jstr.set_if_some o "credentials" credentials;
    Jv.Jstr.set_if_some o "name" name;
    o

  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
  let worker = Jv.get Jv.global "Worker"
  let create ?(opts = Jv.undefined) uri =
    Jv.new' worker Jv.[| of_jstr uri; opts |]

  external as_target : t -> Ev.target = "%identity"
  let terminate w = ignore @@ Jv.call w "terminate" [||]
  let post ?opts w v =
    let opts = match opts with None -> Jv.undefined | Some o -> Obj.magic o in
    ignore @@ Jv.call w "postMessage" [|Jv.repr v; opts|]

  module Shared  = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let shared = Jv.get Jv.global "SharedWorker"
    let create ?(opts = Jv.undefined) uri =
      Jv.new' shared Jv.[| of_jstr uri; opts |]

    external as_target : t -> Ev.target = "%identity"
    let port w = Message.Port.of_jv @@ Jv.get w "port"
  end

  let ami () = Jv.has "WorkerGlobalScope" Jv.global
  module G = struct
    let import_scripts uris =
      ignore @@ Jv.call Jv.global "importScripts" [|Jv.of_jstr_list uris|]

    let post ?opts v =
      let opts = match opts with None -> Jv.undefined | Some o -> Obj.magic o in
      ignore @@ Jv.call Jv.global "postMessage" [| Jv.repr v; opts |]

    let close () = ignore @@ Jv.call Jv.global "close" [||]
  end

end

module Service_worker = struct
  module Update_via_cache = struct
    type t = Jstr.t
    let imports = Jstr.v "imports"
    let all = Jstr.v "all"
    let none = Jstr.v "none"
  end
  module State = struct
    type t = Jstr.t
    let parsed = Jstr.v "parsed"
    let installing = Jstr.v "installing"
    let installed = Jstr.v "installed"
    let activating = Jstr.v "activating"
    let activated = Jstr.v "activated"
    let redundant = Jstr.v "redundant"
  end
  type t = Jv.t
  type service_worker = t
  include (Jv.Id : Jv.CONV with type t := t)
  external as_worker : t -> Worker.t = "%identity"
  external as_target : t -> Ev.target = "%identity"
  let script_url w = Jv.to_jstr @@ Jv.get w "scriptURL"
  let state w = Jv.to_jstr @@ Jv.get w "state"

  module Navigation_preload_manager = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let enable p = Fut.of_promise ~ok:ignore @@ Jv.call p "enable" [||]
    let disable p = Fut.of_promise ~ok:ignore @@ Jv.call p "disable" [||]
    let set_header_value p v =
        Fut.of_promise ~ok:ignore @@ Jv.call p "setHeaderValue" Jv.[|of_jstr v|]

    let get_state p =
      let extract s = Jv.Bool.get s "enabled", Jv.Jstr.get s "headerValue" in
      Fut.of_promise ~ok:extract @@ Jv.call p "getState" [||]
  end

  module Registration = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    external as_target : t -> Ev.target = "%identity"
    let installing r = Jv.to_option Fun.id @@ Jv.get r "installing"
    let waiting r = Jv.to_option Fun.id @@ Jv.get r "waiting"
    let active r = Jv.to_option Fun.id @@ Jv.get r "active"
    let navigation_preload r =
      Navigation_preload_manager.of_jv @@ Jv.get r "navigationPreload"

    let scope r = Jv.Jstr.get r "scope"
    let update_via_cache r = Jv.Jstr.get r "updateViaCache"
    let update r = Fut.of_promise ~ok:ignore @@ Jv.call r "update" [||]
    let unregister r =
      Fut.of_promise ~ok:Jv.to_bool @@ Jv.call r "unregister" [||]

    let show_notification ?opts r title =
      let opts = Jv.of_option ~none:Jv.undefined Jv.repr opts in
      Fut.of_promise ~ok:ignore @@
      Jv.call r "showNotification" Jv.[| of_jstr title; opts |]

    let get_notifications ?tag r =
      let opts = match tag with
      | None -> Jv.undefined | Some tag -> Jv.obj [|"tag", Jv.of_jstr tag |]
      in
      Fut.of_promise ~ok:(Jv.to_list Notification.of_jv) @@
      Jv.call r "getNotifications" [| opts |]
  end

  module Container = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let of_navigator n = Jv.get (Navigator.to_jv n) "serviceWorker"
    external as_target : t -> Ev.target = "%identity"
    let controller c = Jv.to_option Fun.id (Jv.get c "controller")
    let ready c = Fut.of_promise ~ok:Registration.of_jv @@ Jv.get c "ready"

    type register_opts = Jv.t
    let register_opts ?scope ?type' ?update_via_cache () =
      let o = Jv.obj [||] in
      Jv.Jstr.set_if_some o "scope" scope;
      Jv.Jstr.set_if_some o "type" type';
      Jv.Jstr.set_if_some o "updateViaCache" update_via_cache;
      o

    let register ?(register_opts = Jv.undefined) c uri =
      Fut.of_promise ~ok:Registration.of_jv @@
      Jv.call c "register" Jv.[| of_jstr uri; register_opts |]

    let get_registration c uri =
      let uri = Jv.of_option ~none:Jv.undefined Jv.of_jstr uri in
      Fut.of_promise ~ok:(Jv.to_option Registration.of_jv) @@
      Jv.call c "getRegistration" [| uri |]

    let get_registrations c =
      Fut.of_promise ~ok:(Jv.to_list Registration.of_jv) @@
      Jv.call c "getRegistrations" [||]

    let start_messages c = ignore @@ Jv.call c "startMessages" [||]
  end

  module Client = struct
    module Visibility_state = struct
      type t = Jstr.t
      let hidden = Jstr.v "hidden"
      let visible = Jstr.v "visible"
    end
    module Type = struct
      type t = Jstr.t
      let window = Jstr.v "window"
      let worker = Jstr.v "worker"
      let sharedworker = Jstr.v "sharedworker"
      let all = Jstr.v "all"
    end
    module Frame_type = struct
      type t = Jstr.t
      let auxiliary = Jstr.v "auxiliary"
      let top_level = Jstr.v "top-level"
      let nested = Jstr.v "nested"
      let none = Jstr.v "none"
    end
    type t = Jv.t
    type client = t
    include (Jv.Id : Jv.CONV with type t := t)
    let url c = Jv.Jstr.get c "url"
    let frame_type c = Jv.Jstr.get c "frameType"
    let id c = Jv.Jstr.get c "id"
    let type' c = Jv.Jstr.get c "type"
    let post ?opts c v =
      let opts = match opts with None -> Jv.undefined | Some o -> Obj.magic o in
      ignore @@ Jv.call c "postMessage" [|Jv.repr v; opts|]

    module Window = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_client : t -> client = "%identity"
      let visibility_state w = Jv.Jstr.get w "visibilityState"
      let focused w = Jv.Bool.get w "focused"
      let ancestor_origins w =
        Jv.to_list Jv.to_jstr @@ Jv.get w "ancestorOrigins"
      let focus w = Fut.of_promise ~ok:Fun.id @@ Jv.call w "focus" [||]
      let navigate w url =
        Fut.of_promise ~ok:Fun.id @@ Jv.call w "focus" Jv.[| of_jstr url |]
    end
  end

  module Clients = struct
    type query_opts = Jv.t
    let query_opts ?include_uncontrolled ?type' () =
      let o = Jv.obj [||] in
      Jv.Bool.set_if_some o "includeUncontrolled" include_uncontrolled;
      Jv.Jstr.set_if_some o "type" type';
      o

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let get cs id =
      Fut.of_promise ~ok:(Jv.to_option Client.of_jv) @@
      Jv.call cs "get" [| Jv.of_jstr id |]

    let match_all ?(query_opts = Jv.undefined) cs =
      Fut.of_promise ~ok:(Jv.to_list Client.of_jv) @@
      Jv.call cs "matchAll" [| query_opts |]

    let open_window cs url =
      Fut.of_promise ~ok:(Jv.to_option Client.Window.of_jv) @@
      Jv.call cs "openWindow" [| Jv.of_jstr url |]

    let claim cs = Fut.of_promise ~ok:ignore @@ Jv.call cs "claim" [||]
  end

  module G = struct
    let clients = Clients.of_jv @@ Jv.get Jv.global "clients"
    let registration = Registration.of_jv @@ Jv.get Jv.global "registration"
    let service_worker = of_jv @@ Jv.get Jv.global "serviceWorker"
    let skip_waiting () =
      Fut.of_promise ~ok:ignore @@ Jv.call Jv.global "skipWaiting" [||]
  end
end
