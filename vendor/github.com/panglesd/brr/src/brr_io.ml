(*----------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr

module Clipboard = struct
  module Item = struct
    module Presentation_style = struct
      type t = Jstr.t
      let unspecified = Jstr.v "unspecified"
      let inline = Jstr.v "inline"
      let attachment = Jstr.v "attachement"
    end
    type opts = Jv.t
    let opts ?presentation_style () =
      let o = Jv.obj [||] in
      Jv.Jstr.set_if_some o "presentationStyle" presentation_style;
      o

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let item = Jv.get Jv.global "ClipboardItem"

    let create ?opts vs =
      ignore opts ;
      let o = Jv.obj [||] in
      let add_v (t, b) = Jv.set' o t (Blob.to_jv b) in
      List.iter add_v vs; Jv.new' item [|o|]

    let presentation_style i = Jv.Jstr.get i "presentationStyle"
    let last_modified_ms i = Jv.Int.get i "lastModified"
    let delayed i = Jv.Bool.get i "delayed"
    let types i = Jv.to_jstr_list @@ Jv.get i "types"
    let get_type i t =
      Fut.of_promise ~ok:Blob.of_jv @@ Jv.call i "getType" [| i; Jv.of_jstr t |]
  end
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
  let of_navigator n = Jv.get (Navigator.to_jv n) "clipboard"
  let as_target = Ev.target_of_jv
  let read c =
    let ok = Jv.to_list Item.of_jv in
    Fut.of_promise ~ok @@ Jv.call c "read" [||]

  let read_text c = Fut.of_promise ~ok:Jv.to_jstr @@ Jv.call c "readText" [||]
  let write c data =
    let args = [| Jv.of_list Item.to_jv data |] in
    Fut.of_promise ~ok:ignore @@ Jv.call c "write" args

  let write_text c data =
    Fut.of_promise ~ok:ignore @@ Jv.call c "writeText" [|Jv.of_jstr data |]
end

module Form = struct
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
  let of_el e =
    if El.has_tag_name El.Name.form e then El.to_jv e else
    let exp = Jstr.v "Expected form element but found: " in
    Jv.throw (Jstr.append exp (El.tag_name e))

  let to_el e = El.of_jv e
  let name f = Jv.Jstr.get f "name"
  let method' f = Jv.Jstr.get f "method"
  let target f = Jv.Jstr.get f "target"
  let action f = Jv.Jstr.get f "action"
  let enctype f = Jv.Jstr.get f "enctype"
  let accept_charset f = Jv.Jstr.get f "acceptCharset"
  let autocomplete f = Jv.Jstr.get f "autocomplete"
  let no_validate f = Jv.Bool.get f "noValidate"
  let check_validity f = Jv.to_bool @@ Jv.call f "checkValidity" [||]
  let report_validity f = Jv.to_bool @@ Jv.call f "reportValidity" [||]
  let request_submit f el =
    let args = match el with None -> [||] | Some e -> [| El.to_jv e |] in
    ignore @@ Jv.call f "requestSubmit" args

  let reset f = ignore @@ Jv.call f "reset" [||]
  let submit f = ignore @@ Jv.call f "submit" [||]

  module Data = struct
    type form = t
    type entry_value = [ `String of Jstr.t | `File of File.t ]
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let formdata = Jv.get Jv.global "FormData"
    let create () = Jv.new' formdata [||]
    let of_form f = Jv.new' formdata [| f |]
    let is_empty d = Jv.It.result_done (Jv.It.next (Jv.call d "entries" [||]))
    let mem d k = Jv.to_bool @@ Jv.call d "has" Jv.[| of_jstr k |]
    let has_file_entry d =
      let rec loop it =
        let r = Jv.It.next it in
        if Jv.It.result_done r then false else
        let v = Jv.Jarray.get (Jv.It.get_result_value r) 1 in
        if Jv.instanceof v ~cons:(Jv.get Jv.global "File") then true else
        loop it
      in
      loop (Jv.call d "entries" [||])

    let entry_value v =
      match Jv.instanceof v ~cons:(Jv.get Jv.global "File") with
      | true -> `File (File.of_jv v)
      | false -> `String (Jv.to_jstr v)

    let find d k = Jv.to_option entry_value @@ Jv.call d "get" [|Jv.of_jstr k|]
    let find_all d k =
      Jv.to_list entry_value @@ Jv.call d "getAll" [|Jv.of_jstr k|]

    let fold f d acc =
      let key = Jv.to_jstr in
      let value = entry_value in
      Jv.It.fold_bindings ~key ~value f (Jv.call d "entries" [||]) acc

    let set d k v = ignore @@ Jv.call d "set" Jv.[|of_jstr k; of_jstr v|]
    let set_blob ?filename:fn d k b =
      let fn = match fn with None -> Jv.undefined | Some f -> Jv.of_jstr f in
      ignore @@ Jv.call d "set" Jv.[|of_jstr k; Blob.to_jv b; fn|]

    let append d k v = ignore @@ Jv.call d "append" Jv.[|of_jstr k; of_jstr v|]
    let append_blob ?filename:fn d k b =
      let fn = match fn with None -> Jv.undefined | Some f -> Jv.of_jstr f in
      ignore @@ Jv.call d "append" Jv.[|of_jstr k; Blob.to_jv b; fn|]

    let delete d k = ignore @@ Jv.call d "delete" Jv.[| of_jstr k |]

    let of_assoc l =
      let d = create () in
      let app d (k, v) =
        let v, fn = match v with
        | `String s -> Jv.of_jstr s, Jv.undefined
        | `File f -> File.to_jv f, Jv.of_jstr (File.name f)
        in
        ignore (Jv.call d "append" Jv.[|of_jstr k; v; fn|])
      in
      List.iter (app d) l; d

    let to_assoc p = List.rev (fold (fun k v acc -> (k, v) :: acc) p [])

    let of_uri_params p =
      let add k v d = append d k v; d in
      Uri.Params.fold add p (create ())

    let to_uri_params p =
      let usp = Jv.get Jv.global "URLSearchParams" in
      Uri.Params.of_jv (Jv.new' usp [| p |])
  end

  module Ev = struct
    module Data = struct
      type t = Jv.t
      let form_data e = Data.of_jv @@ Jv.get e "formData"
    end
    let formdata = Ev.Type.create (Jstr.v "formdata")
    module Submit =  struct
      type t = Jv.t
      let submitter e = Jv.to_option El.of_jv @@ Jv.get e "submitter"
    end
    let submit = Ev.Type.create (Jstr.v "submit")
  end
end

module Fetch = struct
  module Body = struct
    type init = Jv.t
    let of_jstr = Jv.of_jstr
    let of_uri_params = Uri.Params.to_jv
    let of_form_data = Form.Data.to_jv
    let of_blob = Blob.to_jv
    let of_array_buffer = Tarray.Buffer.to_jv

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let body_used r = Jv.Bool.get r "bodyUsed"
    let body r = Jv.to_option Fun.id (Jv.get r "body")
    let array_buffer r =
      Fut.of_promise ~ok:Tarray.Buffer.of_jv (Jv.call r "arrayBuffer" [||])

    let blob r = Fut.of_promise ~ok:Blob.of_jv (Jv.call r "blob" [||])
    let form_data r =
      Fut.of_promise ~ok:Form.Data.of_jv (Jv.call r "formData" [||])

    let json r = Fut.of_promise ~ok:Fun.id (Jv.call r "json" [||])
    let text r = Fut.of_promise ~ok:Jv.to_jstr (Jv.call r "text" [||])
  end
  module Headers = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let headers = Jv.get Jv.global "Headers"
    let mem h hs = Jv.to_bool (Jv.call hs "has" [|Jv.of_jstr h|])
    let find h hs = Jv.to_option Jv.to_jstr (Jv.call hs "get" [|Jv.of_jstr h|])
    let fold f p acc =
      let key = Jv.to_jstr in
      let value = Jv.to_jstr in
      Jv.It.fold_bindings ~key ~value f (Jv.call p "entries" [||]) acc

    let of_obj o = Jv.new' headers [|o|]
    let of_assoc ?init l =
      let args = match init with None -> [||] | Some h -> [|h|] in
      let hs = Jv.new' headers args in
      let add hs (k, v) =
        ignore (Jv.call hs "append" Jv.[|of_jstr k; of_jstr v|])
      in
      List.iter (add hs) l; hs

    let to_assoc p = List.rev (fold (fun k v acc -> (k, v) :: acc) p [])
  end
  module Request = struct
    module Cache = struct
      type t = Jstr.t
      let default = Jstr.v "default"
      let force_cache = Jstr.v "force-cache"
      let no_cache = Jstr.v "no-cache"
      let no_store = Jstr.v "no-store"
      let only_if_cached = Jstr.v "only-if-cached"
      let reload = Jstr.v "reload"
    end
    module Credentials = struct
      type t = Jstr.t
      let include' = Jstr.v "include"
      let omit = Jstr.v "omit"
      let same_origin = Jstr.v "same-origin"
    end
    module Destination = struct
      type t = Jstr.t
      let audio = Jstr.v "audio"
      let audioworklet = Jstr.v "audioworklet"
      let document = Jstr.v "document"
      let embed = Jstr.v "embed"
      let font = Jstr.v "font"
      let frame = Jstr.v "frame"
      let iframe = Jstr.v "iframe"
      let image = Jstr.v "image"
      let manifest = Jstr.v "manifest"
      let object' = Jstr.v "object'"
      let paintworklet = Jstr.v "paintworklet"
      let report = Jstr.v "report"
      let script = Jstr.v "script"
      let sharedworker = Jstr.v "sharedworker"
      let style = Jstr.v "style"
      let track = Jstr.v "track"
      let video = Jstr.v "video"
      let worker = Jstr.v "worker"
      let xslt = Jstr.v "xslt"
    end
    module Mode = struct
      type t = Jstr.t
      let cors = Jstr.v "cors"
      let navigate = Jstr.v "navigate"
      let no_cors = Jstr.v "no-cors"
      let same_origin = Jstr.v "same-origin"
    end
    module Redirect = struct
      type t = Jstr.t
      let error = Jstr.v "error"
      let follow = Jstr.v "follow"
      let manual = Jstr.v "manual"
    end

    type init = Jv.t
    let init
        ?body ?cache ?credentials ?headers ?integrity ?keepalive ?method'
        ?mode ?redirect ?referrer ?referrer_policy ?signal ()
      =
      let o = Jv.obj [||] in
      Jv.set o "body" (Jv.of_option ~none:Jv.undefined Fun.id body);
      Jv.Jstr.set_if_some o "cache" cache;
      Jv.Jstr.set_if_some o "credentials" credentials;
      Jv.set_if_some o "headers" (Option.map Headers.to_jv headers);
      Jv.Jstr.set_if_some o "integrity" integrity;
      Jv.Bool.set_if_some o "keepalive" keepalive;
      Jv.Jstr.set_if_some o "method" method';
      Jv.Jstr.set_if_some o "mode" mode;
      Jv.Jstr.set_if_some o "redirect" redirect;
      Jv.Jstr.set_if_some o "referrer" referrer;
      Jv.Jstr.set_if_some o "referrerPolicy" referrer_policy;
      Jv.set o "signal"
        (Jv.of_option ~none:Jv.undefined Abort.Signal.to_jv signal);
      o

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let request = Jv.get Jv.global "Request"
    let v ?(init = Jv.obj [||]) url = Jv.new' request [| Jv.of_jstr url; init |]
    let of_request ?init r = match init with
    | None -> Jv.call r "clone" [||]
    | Some init -> Jv.new' request [| r; init |]

    external as_body : t -> Body.t = "%identity"
    let cache r = Jv.Jstr.get r "cache"
    let credentials r = Jv.Jstr.get r "credentials"
    let destination r = Jv.Jstr.get r "destination"
    let headers r = Headers.of_jv (Jv.get r "headers")
    let integrity r = Jv.Jstr.get r "integrity"
    let is_history_navigation r = Jv.Bool.get r "isHistoryNavigation"
    let is_reload_navigation r = Jv.Bool.get r "isReloadNavigation"
    let keepalive r = Jv.Bool.get r "keepalive"
    let method' r = Jv.Jstr.get r "method'"
    let mode r = Jv.Jstr.get r "mode"
    let redirect r = Jv.Jstr.get r "redirect"
    let referrer r = Jv.Jstr.get r "referrer"
    let referrer_policy r = Jv.Jstr.get r "referrerPolicy"
    let signal r = Jv.to_option Abort.Signal.of_jv (Jv.get r "signal")
    let url r = Jv.Jstr.get r "url"
  end

  module Response = struct
    module Type = struct
      type t = Jstr.t
      let basic = Jstr.v "basic"
      let cors = Jstr.v "cors"
      let default = Jstr.v "default"
      let error = Jstr.v "error"
      let opaque = Jstr.v "opaque"
      let opaqueredirect = Jstr.v "opaqueredirect"
    end
    type init = Jv.t
    let init ?headers ?status ?status_text () =
      let o = Jv.obj [||] in
      Jv.set_if_some o "headers" (Option.map Headers.to_jv headers);
      Jv.Int.set_if_some o "status" status;
      Jv.Jstr.set_if_some o "statusText" status_text;
      o

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let response = Jv.get Jv.global "Response"
    let v ?(init = Jv.obj [||]) ?body () =
      let body = Jv.of_option ~none:Jv.null Fun.id body in
      Jv.new' response [| body; init |]

    let of_response r = Jv.call r "clone" [||]
    let error () = Jv.call response "error" [||]
    let redirect ?status url =
      let args = match status with
      | None -> [|Jv.of_jstr url|]
      | Some status -> [|Jv.of_jstr url; Jv.of_int status |]
      in
      Jv.call response "redirect" args

    external as_body : t -> Body.t = "%identity"
    let headers r = Headers.of_jv (Jv.get r "headers")
    let ok r = Jv.Bool.get r "ok"
    let redirected r = Jv.Bool.get r "redirected"
    let status r = Jv.Int.get r "status"
    let status_text r = Jv.Jstr.get r "statusText"
    let url r = Jv.Jstr.get r "url"
  end

  module Cache = struct
    type query_opts = Jv.t
    let query_opts ?ignore_search ?ignore_method ?ignore_vary ?cache_name () =
      let o = Jv.obj [||] in
      Jv.Bool.set_if_some o "ignoreSearch" ignore_search;
      Jv.Bool.set_if_some o "ignoreMethod" ignore_method;
      Jv.Bool.set_if_some o "ignoreVary" ignore_vary;
      Jv.Jstr.set_if_some o "cacheName" cache_name;
      o

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    let match' ?(query_opts = Jv.undefined) c req =
      let ok = Jv.to_option Response.of_jv in
      let args = [| Request.to_jv req; query_opts |] in
      Fut.of_promise ~ok @@ Jv.call c "match" args

    let match_all ?(query_opts = Jv.undefined) c req =
      let ok = Jv.to_list Response.of_jv in
      let args = [| Request.to_jv req; query_opts |] in
      Fut.of_promise ~ok @@ Jv.call c "matchAll" args

    let add c req =
      Fut.of_promise ~ok:ignore @@ Jv.call c "add" [| Request.to_jv req |]

    let add_all c reqs =
      let args = [| Jv.of_list Request.to_jv reqs |] in
      Fut.of_promise ~ok:ignore @@ Jv.call c "addAll" args

    let put c req resp =
      let args = [| Request.to_jv req; Response.to_jv resp|] in
      Fut.of_promise ~ok:ignore @@ Jv.call c "put" args

    let delete ?(query_opts = Jv.undefined) c req =
      let args = [| Request.to_jv req; query_opts |] in
      Fut.of_promise ~ok:Jv.to_bool @@ Jv.call c "delete" args

    let keys ?(query_opts = Jv.undefined) ?(req = Jv.undefined) c =
      let args = [|req; query_opts |] in
      Fut.of_promise ~ok:(Jv.to_list Request.of_jv) @@ Jv.call c "keys" args

    module Storage = struct
      type cache = t
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)

      let match' ?(query_opts = Jv.undefined) s req =
        let ok = Jv.to_option Response.of_jv in
        let args = [| Request.to_jv req; query_opts |] in
        Fut.of_promise ~ok @@ Jv.call s "match" args

      let has s n =
        Fut.of_promise ~ok:Jv.to_bool @@ Jv.call s "has" Jv.[| of_jstr n |]

      let open' s n =
        Fut.of_promise ~ok:Fun.id @@ Jv.call s "open" Jv.[| of_jstr n |]

      let delete s n =
        Fut.of_promise ~ok:Jv.to_bool @@ Jv.call s "delete" Jv.[| of_jstr n |]

      let keys s =
        Fut.of_promise ~ok:Jv.to_jstr_list @@ Jv.call s "keys" [||]
    end
  end

  module Ev = struct
    type t = Jv.t
    let fetch = Ev.Type.create (Jstr.v "fetch")
    let as_extendable = Obj.magic
    let request e = Request.of_jv @@ Jv.get e "request"
    let preload_response e =
      let ok = Jv.to_option Response.of_jv in
      Fut.of_promise ~ok @@ Jv.get e "preloadResponse"

    let client_id e = Jv.Jstr.get e "clientId"
    let resulting_client_id e = Jv.Jstr.get e "resultingClientId"
    let replaces_client_id e = Jv.Jstr.get e "replacesClientId"
    let handled e = Fut.of_promise ~ok:ignore @@ Jv.get e "handled"
    let respond_with e fut =
      let args = [| Fut.to_promise ~ok:Response.to_jv fut |] in
      ignore @@ Jv.call e "respondWith" args
  end

  let fetch = Jv.get Jv.global "fetch"
  let url ?(init = Jv.obj [||]) url =
    Fut.of_promise ~ok:Response.of_jv @@ Jv.apply fetch [|Jv.of_jstr url; init|]

  let request r =
    Fut.of_promise ~ok:Response.of_jv @@ Jv.apply fetch [|Request.to_jv r|]

  let caches () = Jv.get Jv.global "caches"
end

(* Geolocation *)

module Geolocation = struct
  module Error = struct
    type code = int
    let permission_denied = 1
    let position_unavailable = 2
    let timeout = 3
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let code e = Jv.Int.get e "code"
    let message e = Jv.Jstr.get e "message"
  end
  module Pos = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let coords p = Jv.get p "coords"
    let latitude p = Jv.Float.get (coords p) "latitude"
    let longitude p = Jv.Float.get (coords p) "longitude"
    let altitude p = Jv.Float.find (coords p) "altitude"
    let accuracy p = Jv.Float.get (coords p) "accuracy"
    let altitude_accuracy p = Jv.Float.find (coords p) "altitudeAccuracy"
    let heading p = Jv.Float.find (coords p) "heading"
    let speed p = Jv.Float.find (coords p) "speed"
    let timestamp_ms p = Jv.Float.get p "timestamp"
  end
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
  let of_navigator n = Jv.get (Navigator.to_jv n) "geolocation"

  type opts = Jv.t
  let opts ?high_accuracy ?timeout_ms ?maximum_age_ms () =
    let o = Jv.obj [||] in
    Jv.Bool.set_if_some o "enableHighAccuracy" high_accuracy;
    Jv.Int.set_if_some o "timeout" timeout_ms;
    Jv.Int.set_if_some o "maximumAge" maximum_age_ms;
    o

  let get ?opts l =
    let fut, set_fut = Fut.create () in
    let pos p = set_fut (Ok p) and error e = set_fut (Error e) in
    let opts = Jv.of_option ~none:Jv.undefined Fun.id opts in
    let args = Jv.[| repr pos; repr error; opts |] in
    ignore @@ Jv.call l "getCurrentPosition" args;
    fut

  type watch_id = int
  let watch ?opts l f =
    let pos p = f (Ok p) and error e = f (Error e) in
    let opts = Jv.of_option ~none:Jv.undefined Fun.id opts in
    Jv.to_int @@ Jv.call l "watchPosition" Jv.[| repr pos; repr error; opts |]

  let unwatch l id = ignore @@ Jv.call l "clearWatch" [| Jv.of_int id |]
end

(* Media *)

module Media = struct
  module Prop = struct
    module Bool = struct
      module Constraint = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v ?exact ?ideal () =
          let o = Jv.obj [||] in
          Jv.Bool.set_if_some o "exact" exact;
          Jv.Bool.set_if_some o "ideal" ideal;
          o
      end
    end
    module Int = struct
      module Range = struct
        type t = Jv.t
        let v ?min ?max () =
          let o = Jv.obj [||] in
          Jv.Int.set_if_some o "min" min;
          Jv.Int.set_if_some o "max" max;
          o

        let min r = Jv.Int.find r "min"
        let max r = Jv.Int.find r "max"
        include (Jv.Id : Jv.CONV with type t := t)
      end
      module Constraint = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v ?min ?max ?exact ?ideal () =
          let o = Jv.obj [||] in
          Jv.Int.set_if_some o "min" min;
          Jv.Int.set_if_some o "max" max;
          Jv.Int.set_if_some o "exact" exact;
          Jv.Int.set_if_some o "ideal" ideal;
          o
      end
    end
    module Float = struct
      module Range = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v ?min ?max () =
          let o = Jv.obj [||] in
          Jv.Float.set_if_some o "min" min;
          Jv.Float.set_if_some o "max" max;
          o

        let min r = Jv.Float.find r "min"
        let max r = Jv.Float.find r "max"
      end
      module Constraint = struct
        type t = Jv.t
        let v ?min ?max ?exact ?ideal () =
          let o = Jv.obj [||] in
          Jv.Float.set_if_some o "min" min;
          Jv.Float.set_if_some o "max" max;
          Jv.Float.set_if_some o "exact" exact;
          Jv.Float.set_if_some o "ideal" ideal;
          o

        include (Jv.Id : Jv.CONV with type t := t)
      end
    end
    module Jstr = struct
      type t = Jstr.t
      module Constraint = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let v ?exact ?ideal () =
          let o = Jv.obj [||] in
          Jv.set_if_some o "exact" (Option.map Jv.of_jstr_list exact);
          Jv.set_if_some o "ideal" (Option.map Jv.of_jstr_list ideal);
          o
      end
    end

    type 'a conv = ('a -> Jv.t) * (Jv.t -> 'a)
    type ('a, 'b, 'c) t =
      { name : Jstr.t;
        value_to_jv : 'a -> Jv.t;
        value_of_jv : Jv.t -> 'a;
        cap_to_jv : 'b -> Jv.t;
        cap_of_jv : Jv.t -> 'b;
        constr_to_jv : 'c -> Jv.t;
        constr_of_jv : Jv.t -> 'c }

    let v
        name (value_to_jv, value_of_jv) (cap_to_jv, cap_of_jv)
        (constr_to_jv, constr_of_jv)
      =
      { name; value_to_jv; value_of_jv; cap_to_jv; cap_of_jv;
        constr_to_jv; constr_of_jv; }

    let name p = p.name
    let value_to_jv p = p.value_to_jv
    let value_of_jv p = p.value_of_jv
    let cap_to_jv p = p.cap_to_jv
    let cap_of_jv p = p.cap_of_jv
    let constr_to_jv p = p.constr_to_jv
    let constr_of_jv p = p.constr_of_jv

    type bool_t = (bool, bool list, Bool.Constraint.t) t
    let bool name =
      let value_conv = Jv.(of_bool, Jv.to_bool) in
      let cap_conv = Jv.(of_list of_bool, to_list to_bool) in
      let constr_conv = Bool.Constraint.(to_jv, of_jv) in
      v name value_conv cap_conv constr_conv

    type int_t = (int, Int.Range.t, Int.Constraint.t) t
    let int name =
      let value_conv = Jv.(of_int, to_int) in
      let cap_conv = Int.Range.(to_jv, of_jv) in
      let constr_conv = Int.Constraint.(to_jv, of_jv) in
      v name value_conv cap_conv constr_conv

    type float_t = (float, Float.Range.t, Float.Constraint.t) t
    let float name =
      let value_conv = Jv.(of_float, to_float) in
      let cap_conv = Float.Range.(to_jv, of_jv) in
      let constr_conv = Float.Constraint.(to_jv, of_jv) in
      v name value_conv cap_conv constr_conv

    type jstr_t = (Jstr.t, Jstr.t, Jstr.Constraint.t) t
    let jstr name =
      let value_conv = Jv.(of_jstr, to_jstr) in
      let cap_conv = value_conv in
      let constr_conv = Jstr.Constraint.(to_jv, of_jv) in
      v name value_conv cap_conv constr_conv

    type jstr_enum_t = (Jstr.t, Jstr.t list, Jstr.Constraint.t) t
    let jstr_enum name =
      let value_conv = Jv.(of_jstr, to_jstr) in
      let cap_conv = Jv.(of_jstr_list, to_jstr_list) in
      let constr_conv = Jstr.Constraint.(to_jv, of_jv) in
      v name value_conv  cap_conv constr_conv
  end

  module Supported_constraints = struct
    type t = Jv.t

    let mem p cs =
      let mem = Jv.get' cs (Prop.name p) in
      if Jv.is_none mem then false else Jv.to_bool mem

    let names cs =
      Jv.to_jstr_list @@ Jv.call (Jv.get Jv.global "Object") "keys" [| cs |]

    (**/**)
    include (Jv.Id : Jv.CONV with type t := t)
    (**/**)
  end

  module Constraints = struct
    type t = Jv.t
    let empty () = Jv.obj [||]
    let find p c = Jv.find_map' (Prop.constr_of_jv p) c (Prop.name p)
    let set p v c = Jv.set' c (Prop.name p) (Prop.constr_to_jv p v)
    let delete p c = Jv.delete' c (Prop.name p)
    include (Jv.Id : Jv.CONV with type t := t)
  end

  module Capabilities = struct
    type t = Jv.t
    let find p s = Jv.find_map' (Prop.cap_of_jv p) s (Prop.name p)
    let set p v s = Jv.set' s (Prop.name p) (Prop.cap_to_jv p v)
    let delete p s = Jv.delete' s (Prop.name p)
    include (Jv.Id : Jv.CONV with type t := t)
  end

  module Settings = struct
    type t = Jv.t
    let get p s = Prop.value_of_jv p @@ Jv.get' s (Prop.name p)
    let find p s = Jv.find_map' (Prop.value_of_jv p) s (Prop.name p)
    include (Jv.Id : Jv.CONV with type t := t)
  end

  module Track = struct
    module Prop = struct
      let aspect_ratio = Prop.float (Jstr.v "aspectRatio")
      let auto_gain_control = Prop.bool (Jstr.v "autoGainControl")
      let channel_count = Prop.int (Jstr.v "channelCount")
      let cursor = Prop.jstr_enum (Jstr.v "cursor")
      let device_id = Prop.jstr (Jstr.v "deviceId")
      let display_surface = Prop.jstr_enum (Jstr.v "displaySurface")
      let echo_cancellation = Prop.bool (Jstr.v "echoCancellation")
      let facing_mode = Prop.jstr_enum (Jstr.v "facingMode")
      let frame_rate = Prop.float (Jstr.v "frameRate")
      let group_id = Prop.jstr (Jstr.v "groupId")
      let height = Prop.int (Jstr.v "height")
      let latency = Prop.float (Jstr.v "latency")
      let logical_surface = Prop.bool (Jstr.v "logicalSurface")
      let noise_suppresion = Prop.bool (Jstr.v "noiseSuppresion")
      let resize_mode = Prop.jstr_enum (Jstr.v "resizeMode")
      let sample_rate = Prop.int (Jstr.v "sampleRate")
      let sample_size = Prop.int (Jstr.v "sampleSize")
      let width = Prop.int (Jstr.v "width")
    end

    module State = struct
      type t = Jstr.t
      let live = Jstr.v "live"
      let ended = Jstr.v "ended"
    end

    module Kind = struct
      type t = Jstr.t
      let audio = Jstr.v "audio"
      let video = Jstr.v "video"
    end

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)

    external as_target : t -> Ev.target = "%identity"
    let id t = Jv.Jstr.get t "id"
    let isolated t = Jv.Bool.get t "isolated"
    let kind t = Jv.Jstr.get t "kind"
    let label t = Jv.Jstr.get t "label"
    let muted t = Jv.Bool.get t "muted"
    let ready_state t = Jv.Jstr.get t "readyState"
    let enabled t = Jv.Bool.get t "enabled"
    let set_enabled t b = Jv.Bool.set t "enabled" b
    let get_capabilities t =
      Capabilities.of_jv @@ Jv.call t "getCapabilities" [||]

    let get_constraints t =
      Constraints.of_jv @@ Jv.call t "getConstraints" [||]

    let apply_constraints t c =
      let a = match c with None -> [||] | Some c -> [|Constraints.to_jv c|] in
      Fut.of_promise ~ok:(Fun.const ()) @@ Jv.call t "applyConstraints" a

    let get_settings t = Settings.of_jv @@ Jv.call t "getSettings" [||]
    let stop t = ignore @@ Jv.call t "stop" [||]
    let clone t = Jv.call t "clone" [||]

    module Ev = struct
      let ended = Ev.Type.void (Jstr.v "ended")
      let isolationchange = Ev.Type.void (Jstr.v "isolationchange")
      let mute = Ev.Type.void (Jstr.v "mute")
      let unmute = Ev.Type.void (Jstr.v "unmute")
      type track = t
      type t = Jv.t
      let track p = Jv.get p "track"
    end
  end

  module Stream = struct
    module Constraints = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      type track = [ `No | `Yes of Constraints.t option ]

      let v ?(audio = `No) ?(video = `No) () =
        let o = Jv.obj [||] in
        let set_track o n = function
        | `No -> Jv.Bool.set o n false
        | `Yes None -> Jv.Bool.set o n true
        | `Yes (Some c) -> Jv.set o n (Constraints.to_jv c)
        in
        set_track o "audio" audio;
        set_track o "video" video;
        o

      let av () = v ~audio:(`Yes None) ~video:(`Yes None) ()
    end

    type t = Jv.t
    let stream = Jv.get Jv.global "MediaStream"
    let create () = Jv.new' stream [||]
    let of_stream s = Jv.new' stream [| s |]
    let of_tracks ts = Jv.new' stream [|Jv.of_list Track.to_jv ts |]
    external as_target : t -> Ev.target = "%identity"
    let id s = Jv.Jstr.get s "id"
    let active s = Jv.Bool.get s "active"
    let get_audio_tracks s =
      Jv.to_list Track.of_jv @@ Jv.call s "getAudioTracks" [||]

    let get_video_tracks s =
      Jv.to_list Track.of_jv @@ Jv.call s "getVideoTracks" [||]

    let get_tracks s = Jv.to_list Track.of_jv @@ Jv.call s "getTracks" [||]
    let get_track_by_id s id =
      Jv.to_option Track.of_jv @@ Jv.call s "getTrackById" [| Jv.of_jstr id |]

    let add_track s t = ignore @@ Jv.call s "addTrack" [| Track.to_jv t |]
    let remove_track s t = ignore @@ Jv.call s "removeTrack" [| Track.to_jv t |]
    let clone s = Jv.call s "clone" [||]

    module Ev = struct
      let addtrack = Ev.Type.create (Jstr.v "addtrack")
      let removetrack = Ev.Type.create (Jstr.v "removetrack")
    end
    include (Jv.Id : Jv.CONV with type t := t)
  end

  module Recorder = struct
    module Bitrate_mode = struct
      type t = Jstr.t
      let cbr = Jstr.v "cbr"
      let vbr = Jstr.v "vbr"
    end

    module Recording_state = struct
      type t = Jstr.t
      let inactive = Jstr.v "inactive"
      let recording = Jstr.v "recording"
      let paused = Jstr.v "paused"
    end

    type init = Jv.t

    let init ?type' ?audio_bps ?video_bps ?bps ?audio_bitrate_mode () =
      let o = Jv.obj [||] in
      Jv.Jstr.set_if_some o "mimeType" type';
      Jv.Int.set_if_some o "audioBitsPerSecond" audio_bps;
      Jv.Int.set_if_some o "videoBitsPerSecond" video_bps;
      Jv.Int.set_if_some o "bitsPerSecond" bps;
      Jv.Jstr.set_if_some o "audioBitrateMode" audio_bitrate_mode;
      o

    let recorder = Jv.get Jv.global "MediaRecorder"
    let is_type_supported t =
      Jv.to_bool @@ Jv.call recorder "isTypeSupported" [| Jv.of_jstr t |]

    type t = Jv.t

    let create ?(init = Jv.obj [||]) s =
      Jv.new' recorder [| Stream.to_jv s; init |]

    let stream r = Stream.of_jv (Jv.get r "stream")
    let type' r = Jv.Jstr.get r "mimeType"
    let state r = Jv.Jstr.get r "state"
    let video_bps r = Jv.Int.get r "videoBitsPerSecond"
    let audio_bps r = Jv.Int.get r "audioBitsPerSecond"
    let audio_bitrate_mode r = Jv.Jstr.get r "audioBitrateMode"

    let start r ~timeslice_ms:ts =
      let args = match ts with None -> [||] | Some ms -> Jv.[| of_int ms |] in
      match Jv.call r "start" args with
      | exception Jv.Error e -> Error e | _ -> Ok ()

    let stop r = ignore @@ Jv.call r "stop" [||]
    let pause r = ignore @@ Jv.call r "pause" [||]
    let resume r = ignore @@ Jv.call r "resume" [||]
    let request_data r = ignore @@ Jv.call r "requestData" [||]

    module Ev = struct
      module Blob = struct
        type t = Jv.t
        let data e = Blob.of_jv @@ Jv.get e "data"
        let timecode e = Jv.Float.get e "timecode"
      end
      module Error = struct
        type t = Jv.t
        let error e = Jv.to_error @@ Jv.get e "error"
      end

      let start = Ev.Type.void (Jstr.v "start")
      let stop = Ev.Type.void (Jstr.v "stop")
      let dataavailable = Ev.Type.create (Jstr.v "dataavailable")
      let pause = Ev.Type.void (Jstr.v "pause")
      let resume = Ev.Type.void (Jstr.v "resume")
      let error = Ev.Type.create (Jstr.v "error")
    end
  end

  module Device = struct
    module Kind = struct
      type t = Jstr.t
      let audioinput = Jstr.v "audioinput"
      let audiooutput = Jstr.v "audiooutput"
      let videoinput = Jstr.v "videoinput"
    end
    module Info = struct
      type t = Jv.t
      let device_id d = Jv.Jstr.get d "deviceId"
      let kind d = Jv.Jstr.get d "kind"
      let label d = Jv.Jstr.get d "label"
      let group_id d = Jv.Jstr.get d "groupId"
      let to_json d = Jv.call d "toJSON" [||]
      include (Jv.Id : Jv.CONV with type t := t)
    end
  end

  module Devices = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    external as_target : t -> Ev.target = "%identity"

    let of_navigator n = Jv.get (Navigator.to_jv n) "mediaDevices"

    let enumerate m =
      let ok = Jv.to_list Device.Info.of_jv in
      Fut.of_promise ~ok @@ Jv.call m "enumerateDevices" [||]

    let get_supported_constraints m =
      Supported_constraints.of_jv @@
      Jv.call m "getSupportedConstraints" [||]

    let get_user_media m c =
      let ok = Stream.of_jv in
      Fut.of_promise ~ok @@ Jv.call m "getUserMedia" [| c |]

    let get_display_media m c =
      let ok = Stream.of_jv in
      Fut.of_promise ~ok @@ Jv.call m "getDisplayMedia" [| c |]

    module Ev = struct
      let devicechange = Ev.Type.void (Jstr.v "devicechange")
    end
  end

  (* Media element interface *)

  module El = struct
    module Error = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      type code = int
      let aborted = 1
      let network = 2
      let decode = 3
      let src_not_supported = 4
      let code e = Jv.Int.get e "code"
      let message e = Jv.Jstr.get e "message"
    end
    module Can_play = struct
      type t = Jstr.t
      let maybe = Jstr.v "maybe"
      let probably = Jstr.v "probably"
    end
    module Have = struct
      type t = int
      let nothing = 0
      let metadata = 1
      let current_data = 2
      let future_data = 3
      let enought_data = 4
    end
    module Network = struct
      type t = int
      let empty = 0
      let idle = 1
      let loading = 2
      let no_source = 3
    end
    module Cors = struct
      type t = Jstr.t
      let anonymous = Jstr.v "anonymous"
      let use_credentials = Jstr.v "use-credentials"
    end
    module Provider = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let of_media_stream = Fun.id
      let of_blob = Blob.to_jv
      let of_media_source = Fun.id
    end
    module Audio_track = struct
      module List = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
      end
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
    end
    module Video_track = struct
      module List = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
      end
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
    end
    module Text_track = struct
      module Kind = struct
        type t = Jstr.t
      end
      module List = struct
        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
      end
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
    end
    module Time_ranges = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let length r = Jv.Int.get r "length"
      let start r i = Jv.to_float @@ Jv.call r "start" Jv.[| of_int i |]
      let end' r i = Jv.to_float @@ Jv.call r "end" Jv.[| of_int i |]
    end

    (* Media interface *)

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let of_el e =
      if El.has_tag_name El.Name.video e then (El.to_jv e) else
      if El.has_tag_name El.Name.audio e then (El.to_jv e) else
      let exp = Jstr.v "Expected audio or video element but found: " in
      Jv.throw (Jstr.append exp (El.tag_name e))

    let to_el = El.of_jv
    let error m = Jv.to_option Error.of_jv (Jv.get m "error")

    (* Network state *)

    let src m = Jv.Jstr.get m "src"
    let set_src m s = Jv.Jstr.set m "src" s
    let src_object m = Jv.to_option Provider.of_jv (Jv.get m "srcObject")
    let set_src_object m o =
      Jv.set m "srcObject" (Jv.of_option ~none:Jv.null Provider.to_jv o)

    let current_src m = Jv.Jstr.get m "currentSrc"
    let cross_origin m = Jv.Jstr.get m "crossOrigin"
    let set_cross_origin m c = Jv.Jstr.set m "crossOrigin" c
    let network_state m = Jv.Int.get m "networkState"
    let preload m = Jv.Jstr.get m "preload"
    let set_preload m p = Jv.Jstr.set m "preload" p
    let buffered m = Time_ranges.of_jv @@ Jv.get m "buffered"
    let load m = ignore @@ Jv.call m "load" [||]
    let can_play_type m t =
      Jv.to_jstr @@ Jv.call m  "canPlayType" Jv.[|of_jstr t|]

    (* Ready state *)

    let ready_state m = Jv.Int.get m "readyState"
    let seeking m = Jv.Bool.get m "seeking"

    (* Playback state *)

    let current_time_s m = Jv.Float.get m "currentTime"
    let set_current_time_s m t = Jv.Float.set m "currentTime" t
    let fast_seek_s m t = ignore @@ Jv.call m "fastSeek" Jv.[|of_float t|]
    let duration_s m = Jv.Float.get m "duration"
    let paused m = Jv.Bool.get m "paused"
    let default_playback_rate m = Jv.Float.get m "defaultPlaybackRate"
    let set_default_playback_rate m r = Jv.Float.set m "defaultPlaybackRate" r
    let playback_rate m = Jv.Float.get m "playbackRate"
    let set_playback_rate m r = Jv.Float.set m "playbackRate" r
    let played m = Time_ranges.of_jv @@ Jv.get m "played"
    let seekable m = Time_ranges.of_jv @@ Jv.get m "seekable"
    let ended m = Jv.Bool.get m "ended"
    let autoplay m = Jv.Bool.get m "autoplay"
    let set_auto_play m b= Jv.Bool.set m "autoplay" b
    let loop m = Jv.Bool.get m "loop"
    let set_loop m b = Jv.Bool.set m "loop" b
    let play m = Fut.of_promise ~ok:ignore (Jv.call m "play" [||])
    let pause m = ignore (Jv.call m "pause" [||])

    (* Controls *)

    let controls m = Jv.Bool.get m "controls"
    let set_controls m b = Jv.Bool.set m "controls" b
    let volume m = Jv.Float.get m "volume"
    let set_volume m f = Jv.Float.set m "volume" f
    let muted m = Jv.Bool.get m "muted"
    let set_muted m b = Jv.Bool.set m "muted" b
    let default_muted m = Jv.Bool.get m "defaultMuted"
    let set_default_muted m b = Jv.Bool.set m "defaultMuted" b

    (* Tracks *)

    let audio_track_list m = Audio_track.List.of_jv @@ Jv.get m "audioTracks"
    let video_track_list m = Video_track.List.of_jv @@ Jv.get m "videoTracks"
    let text_track_list m = Text_track.List.of_jv @@ Jv.get m "textTracks"
    let capture_stream m = Stream.of_jv @@ Jv.call m "captureStream" [||]
  end
end

(* Messages *)

module Message = struct
  type transfer = Jv.t
  let transfer = Jv.repr
  type opts = Jv.t
  let opts ?target_origin ?transfer () =
    let o = Jv.obj [||] in
    Jv.Jstr.set_if_some o "targetOrigin" target_origin;
    Jv.set_if_some o "transfer" (Option.map Jv.of_jv_list transfer);
    o

  module Port = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    external as_target : t -> Ev.target = "%identity"
    let start p = ignore @@ Jv.call p "start" [||]
    let close p = ignore @@ Jv.call p "close" [||]
    let post ?(opts = Jv.undefined) p v =
      ignore @@ Jv.call p "postMessage" [|Jv.repr v; opts|]
  end

  module Channel = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let channel = Jv.get Jv.global "MessageChannel"
    let create () = Jv.new' channel [||]
    let port1 c = Port.of_jv @@ Jv.get c "port1"
    let port2 c = Port.of_jv @@ Jv.get c "port2"
  end

  module Broadcast_channel = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    external as_target : t -> Ev.target = "%identity"
    let broadcast = Jv.get Jv.global "BroadcastChannel"
    let create n = Jv.new' broadcast [| Jv.of_jstr n |]
    let name b = Jv.Jstr.get b "name"
    let close b = ignore @@ Jv.call b "close" [||]
    let post b v = ignore @@ Jv.call b "postMessage" [|Jv.repr v|]
  end

  let window_post ?(opts = Jv.undefined) w v =
    ignore @@ Jv.call (Window.to_jv w) "postMessage" [| Jv.repr v; opts |]

  module Ev = struct
    type t = Jv.t
    let message = Brr.Ev.Type.create (Jstr.v "message")
    let messageerror = Brr.Ev.Type.create (Jstr.v "messageerror")
    let as_extendable = Obj.magic
    let data e = Obj.magic @@ Jv.get e "data"
    let origin e = Jv.Jstr.get e "origin"
    let last_event_id e = Jv.Jstr.get e "lastEventId"
    let source e = Jv.to_option Fun.id (Jv.get e "source")
    let ports e = Jv.to_list Port.of_jv (Jv.get e "ports")
  end
end

(* Notification *)

module Notification = struct
  module Permission = struct
    type t = Jstr.t
    let default = Jstr.v "default"
    let denied = Jstr.v "denied"
    let granted = Jstr.v "granted"
  end
  let notification = Jv.get Jv.global "Notification"
  let permission () = Jv.Jstr.get notification "permission"
  let request_permission () =
    Fut.of_promise ~ok:Jv.to_jstr @@
    Jv.call notification "requestPermission" [||]

  module Direction = struct
    type t = Jstr.t
    let auto = Jstr.v "auto"
    let ltr = Jstr.v "ltr"
    let rtl = Jstr.v "rtl"
  end

  module Action = struct
    let max () = Jv.Int.get notification "maxActions"
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let v ?icon ~action ~title () =
      let o = Jv.obj [||] in
      Jv.Jstr.set o "action" action;
      Jv.Jstr.set o "title" title;
      Jv.Jstr.set_if_some o "icon" icon;
      o

    let action a = Jv.Jstr.get a "action"
    let title a = Jv.Jstr.get a "title"
    let icon a = Jv.Jstr.find a "icon"
  end

  (* type action = Jv.t *)
  type opts = Jv.t
  let opts
      ?dir ?lang ?body ?tag ?image ?icon ?badge ?timestamp_ms
      ?renotify ?silent ?require_interaction ?data ?(actions = []) ()
    =
    ignore tag ;
    let o = Jv.obj [||] in
    Jv.Jstr.set_if_some o "dir" dir;
    Jv.Jstr.set_if_some o "lang" lang;
    Jv.Jstr.set_if_some o "body" body;
    Jv.Jstr.set_if_some o "image" image;
    Jv.Jstr.set_if_some o "icon" icon;
    Jv.Jstr.set_if_some o "badge" badge;
    Jv.Int.set_if_some o "timestamp" timestamp_ms;
    Jv.Bool.set_if_some o "renotify" renotify;
    Jv.Bool.set_if_some o "silent" silent;
    Jv.Bool.set_if_some o "requireInteraction" require_interaction;
    Jv.set_if_some o "data" (Option.map Jv.repr data);
    Jv.set o "actions" (Jv.of_list Fun.id actions);
    o

  type t = Jv.t
  type notification = t
  include (Jv.Id : Jv.CONV with type t := t)
  let create ?(opts = Jv.undefined) title =
    Jv.new' notification [| Jv.of_jstr title; opts|]

  let close n = ignore @@ Jv.call n "close" [||]
  external as_target : t -> Ev.target = "%identity"
  let actions n = Jv.to_list Fun.id (Jv.get n "actions")
  let badge n = Jv.Jstr.get n "badge"
  let body n = Jv.Jstr.get n "body"
  let data n = Obj.magic @@ Jv.get n "data"
  let dir n = Jv.Jstr.get n "dir"
  let lang n = Jv.Jstr.get n "lang"
  let tag n = Jv.Jstr.get n "tag"
  let icon n = Jv.Jstr.get n "icon"
  let image n = Jv.Jstr.get n "image"
  (* let url n = Jv.Jstr.get n "url" *)
  let renotify n = Jv.Bool.get n "renotify"
  let require_interaction n = Jv.Bool.get n "requireInteraction"
  let silent n = Jv.Bool.get n "silent"
  let timestamp_ms n = Jv.Int.get n "timestamp"
  let title n = Jv.Jstr.get n "title"

  module Ev = struct
    type t = Jv.t
    let notificationclick = Ev.Type.create (Jstr.v "notificationclick")
    let notificationclose = Ev.Type.create (Jstr.v "notificationclose")
    let as_extendable = Obj.magic
    let notification e = of_jv @@ Jv.get e "notification"
    let action e = Jv.Jstr.get e "action"
  end
end

(* Storage *)

module Storage = struct
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)

  let local w = Jv.get (Window.to_jv w) "localStorage"
  let session w = Jv.get (Window.to_jv w) "sessionStorage"

  let length s = Jv.Int.get s "length"
  let key s i = Jv.to_option Jv.to_jstr @@ Jv.call s "key" Jv.[| of_int i |]
  let get_item s k =
    Jv.to_option Jv.to_jstr @@ Jv.call s "getItem" Jv.[| of_jstr k |]

  let set_item s k v =
    match Jv.to_jstr @@ Jv.call s "setItem" Jv.[| of_jstr k; of_jstr v |] with
    | exception Jv.Error e -> Error e
    | _ -> Ok ()

  let remove_item s k = ignore @@ Jv.call s "removeItem" Jv.[| of_jstr k |]
  let clear s = ignore @@ Jv.call s "clear" [||]

  module Ev = struct
    type storage_area = t
    type t = Jv.t
    let storage = Ev.Type.create (Jstr.v "storage")
    let key e = Jv.Jstr.find e "key"
    let old_value e = Jv.Jstr.find e "oldValue"
    let new_value e = Jv.Jstr.find e "newValue"
    let url e = Jv.Jstr.get e "url"
    let storage_area e = Jv.find e "storageArea"
  end
end

(* Websocket *)

module Websocket = struct

  module Binary_type = struct
    type t = Jstr.t
    let blob = Jstr.v "blob"
    let arraybuffer = Jstr.v "arraybuffer"
  end

  module Ready_state = struct
    type t = int
    let connecting = 0
    let open' = 1
    let closing = 2
    let closed = 3
  end

  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
  external as_target : t -> Ev.target = "%identity"

  let websocket = Jv.get Jv.global "WebSocket"
  let create ?protocols url =
    let protocols = match protocols with
    | None -> Jv.undefined | Some ps -> Jv.of_jstr_list ps
    in
    Jv.new' websocket Jv.[| of_jstr url; protocols |]

  let binary_type s = Jv.Jstr.get s "binaryType"
  let set_binary_type s t = Jv.Jstr.set s "binaryType" t
  let close ?code ?reason:r s =
    let code = match code with None -> Jv.undefined | Some c -> Jv.of_int c in
    let reason = match r with None -> Jv.undefined | Some s -> Jv.of_jstr s in
    ignore @@ Jv.call s "close" [|code; reason|]

  let url s = Jv.Jstr.get s "url"
  let ready_state s = Jv.Int.get s "readyState"
  let buffered_amount s = Jv.Int.get s "bufferedAmount"
  let extensions s = Jv.Jstr.get s "extensions"
  let protocol s = Jv.Jstr.get s "protocol"

  let send_string s d = ignore @@ Jv.call s "send" [| Jv.of_jstr d |]
  let send_blob s d = ignore @@ Jv.call s "send" [| Blob.to_jv d |]
  let send_tarray s d = ignore @@ Jv.call s "send" [| Tarray.to_jv d |]
  let send_array_buffer s d =
    ignore @@ Jv.call s "send" [| Tarray.Buffer.to_jv d |]

  module Ev = struct
    module Close = struct
      type t = Jv.t
      let was_clean e = Jv.Bool.get e "wasClean"
      let code e = Jv.Int.get e "code"
      let reason e = Jv.Jstr.get e "reason"
    end
    let close = Ev.Type.create (Jstr.v "close")
  end
end
