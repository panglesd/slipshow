(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Clipboard, Form, Fetch, Geolocation, Media and Storage APIs. *)

open Brr

(** Clipboard access

    See the {{:https://developer.mozilla.org/en-US/docs/Web/API/Clipboard}
    Clipboard API}. *)
module Clipboard : sig

  (** Clipboard items. *)
  module Item : sig

    (** Presentation style enum. *)
    module Presentation_style : sig
      type t = Jstr.t
      (** The type for
          {{:https://w3c.github.io/clipboard-apis/#enumdef-presentationstyle}
          presentation} style values. *)

      val unspecified : t
      val inline : t
      val attachment : t
    end

    type opts
    (** The type for
        {{:https://w3c.github.io/clipboard-apis/#dictdef-clipboarditemoptions}
        [ClipboardItemOptions]}. *)

    val opts : ?presentation_style:Presentation_style.t -> unit -> opts
    (** [opts ~presentation_style ()] are options for clipboard item
        objects. *)

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ClipboardItem}[ClipboardItem]} objects. *)

    val create : ?opts:opts -> (Jstr.t * Blob.t) list -> t
    (** [create ~opts data] is {{:https://developer.mozilla.org/en-US/docs/Web/API/ClipboardItem/ClipboardItem}clipboard item} with MIME types and associated
        values [data] and options [opts]. *)

    val presentation_style : t -> Presentation_style.t
    (** [presentation_style i] is the {{:https://w3c.github.io/clipboard-apis/#dom-clipboarditem-presentationstyle}presentation style} of [i]. *)

    val last_modified_ms : t -> int
    (** [last_modified_ms i] is the
        {{:https://w3c.github.io/clipboard-apis/#dom-clipboarditem-lastmodified}
        last modified time} in ms from the epoch of [i]. *)

    val delayed : t -> bool
    (** [delayed i] is the
        {{:https://w3c.github.io/clipboard-apis/#dom-clipboarditem-delayed}delayed} property of [i]. *)

    val types : t -> Jstr.t list
    (** [types i] is the array of MIME types {{:https://developer.mozilla.org/en-US/docs/Web/API/ClipboardItem/types}available} for [i]. *)

    val get_type : t -> Jstr.t -> Brr.Blob.t Fut.or_error
    (** [get_type i t] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ClipboardItem/getType}blob object} with MIME type [t] for item [i]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  type t
  (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Clipboard}[Clipboard]} objects. *)

  val of_navigator : Navigator.t -> t
  (** [of_navigator n] is a clipboard object for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Navigator/clipboard}navigator} [n]. *)

  val as_target : t -> Ev.target
  (** [as_target c] is [c] as an event target. *)

  (** {1:rw Reading and writing} *)

  val read : t -> Item.t list Fut.or_error
  (** [read c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/read}content} of [c]. *)

  val read_text : t -> Jstr.t Fut.or_error
  (** [read_text c] is the clipboard {{:https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/readText}textual content} of [c]. *)

  val write : t -> Item.t list -> unit Fut.or_error
  (** [write c is]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/write}
      writes} the items [is] to [c]. *)

  val write_text : t -> Jstr.t -> unit Fut.or_error
  (** [write_text c s]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText}
      writes} the string [s] to [c]. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** Form elements and form data. *)
module Form : sig

  (** {1:element Element} *)

  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement}
      [HTMLFormElement]} objects. *)

  val of_el : El.t -> t
  (** [of_el e] is a form from element [e]. This throws a JavaScript
      error if [e] is not a form element. *)

  val to_el : t -> El.t
  (** [to_el f] is [f] as an an element. *)

  val name : t -> Jstr.t
  (** [name f] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/name}name} of [f]. *)

  val method' : t -> Jstr.t
  (** [method' f] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/method}method} of [f]. *)

  val target : t -> Jstr.t
  (** [target f] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/target}target} of [f]. *)

  val action : t -> Jstr.t
  (** [action f] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/action}action} of [f]. *)

  val enctype : t -> Jstr.t
  (** [enctype f] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/enctype}enctype} of [f]. *)

  val accept_charset : t -> Jstr.t
  (** [accept_charset f] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/acceptCharset}charset accepted} by [f]. *)

  val autocomplete : t -> Jstr.t
  (** [autocomplete f] refelects the value of the {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#attr-autocomplete}autocomplete} attribute
      of [f]. *)

  val no_validate : t -> bool
  (** [no_validate f] refelects the value of the {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#attr-novalidate}novalidate} attribute
      of [f]. *)

  val check_validity : t -> bool
  (** [check_validity f] is [true] if the form's children controls
      all satisfy their
      {{:https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/HTML5/Constraint_validation}validation constraints}. *)

  val report_validity : t -> bool
  (** [report_validity f] is like {!check_validity} but also
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/reportValidity}reports} problems to the user. *)

  val request_submit : t -> El.t option -> unit
  (** [request_submist f el] requests the form to be
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/requestSubmit}submited} using button [el] or the form itself if unspecified. *)

  val reset : t -> unit
  (** [reset f]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/reset}
      resets} the form. *)

  val submit : t -> unit
  (** [submit f] {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit}submits} the form. *)

  (** {1:data Data} *)

  (** Form data. *)
  module Data : sig
    type form = t
    (** See {!Brr_io.Form.t}. *)

    type entry_value = [ `String of Jstr.t | `File of File.t ]
    (** The type for form data entry values. *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FormData}FormData}
        objects. *)

    val create : unit -> t
    (** [create ()] is new, empty, form data. *)

    val of_form : form -> t
    (** [of_form f] is a form data from the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FormData/FormData#Parameters}current key-values} of form [f]. *)

    val is_empty : t -> bool
    (** [is_empty d] is [true] if [d] has no entries. *)

    val has_file_entry : t -> bool
    (** [has_file_entry d] is [true] iff [d] has a file entry. *)

    val mem : t -> Jstr.t -> bool
    (** [mem d k] is [true] if [d]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FormData/has}has}
        key [k]. *)

    val find : t -> Jstr.t -> entry_value option
    (** [find d k] is the first value associated to [k] in [d] (if any). *)

    val find_all : t -> Jstr.t -> entry_value list
    (** [find_all d k] are all the values associated to [k] in [d]. *)

    val fold : (Jstr.t -> entry_value  -> 'a -> 'a) -> t -> 'a -> 'a
    (** [fold f d acc] folds over all key/value entries in [d] with [f]
        starting with [k]. *)

    val set : t -> Jstr.t -> Jstr.t -> unit
    (** [set d k v]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FormData/set}
        sets} the value of [k] to [v] in [d]. *)

    val set_blob : ?filename:Jstr.t -> t -> Jstr.t -> Blob.t -> unit
    (** [set d k b ~filename]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FormData/set}
        sets} the value of [k] to [b] in [d]. [filename] can
        specify the filename of [b]. *)

    val append : t -> Jstr.t -> Jstr.t -> unit
    (** [append d k v]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FormData/append}
        appends} value [v] to the value of [k] in [d]. *)

    val append_blob : ?filename:Jstr.t -> t -> Jstr.t -> Blob.t -> unit
    (** [append d k b ~filename]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FormData/append}
        appends} blob [b] to the value of [k] in [d]. [filename] can
        specify the filename of [b]. *)

    val delete : t -> Jstr.t -> unit
    (** [delete d k]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FormData/delete}
        deletes} the values of key [k] in [d]. *)

    (** {1:convert Converting} *)

    val of_assoc : (Jstr.t * entry_value) list -> t
    (** [of_assoc l] is form data from assoc [l], data is {!append}ed. *)

    val to_assoc : t -> (Jstr.t * entry_value) list
    (** [to_assoc l] is the form data as an association list. *)

    val of_uri_params : Uri.Params.t -> t
    (** [of_uri_params p] is a form data for [p]. *)

    val to_uri_params : t -> Uri.Params.t
    (** [to_uri_params t] is the form data as URI query parameters.

        {b Note.} If your form has file inputs this will map their keys
        to something like ["[Object File]"], {!has_file_entry} indicates
        whether the form data has a file entry. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** {1:events Events} *)

  (** Form events *)
  module Ev : sig

    (** Form data events *)
    module Data : sig

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/FormDataEvent}
          [FormDataEvent]} objects. *)

      val form_data : t -> Data.t
      (** [form_data e] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/FormDataEvent/formData}form data} when the event was fired. *)
    end

    val formdata : Data.t Ev.type'
    (** [formadata] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/formdata_event}[formdata]} event. *)

    (** Submit events *)
    module Submit : sig
      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/SubmitEvent}
          [SubmitEvent]} objects. *)

      val submitter : t -> El.t option
      (** [submitter e] is
          {{:https://developer.mozilla.org/en-US/docs/Web/API/SubmitEvent}
          the element} which triggered the submission. *)
    end

    val submit : Submit.t Ev.type'
    (** [submit] is the type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit_event}submit} events. *)
  end

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** Fetching resources.

    See the {{:https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API}
    Fetch API}. *)
module Fetch : sig

  (** Body specification and interface. *)
  module Body : sig

    (** {1:init Specification} *)

    type init
    (** The type for specifying bodies. *)

    val of_jstr : Jstr.t -> init
    (** [of_jstr s] is a body from string [s]. *)

    val of_uri_params : Brr.Uri.Params.t -> init
    (** [of_uri_params p] is a body from URI params [p]. *)

    val of_form_data : Form.Data.t -> init
    (** [of_form_data d] is a body from form data [d]. *)

    val of_blob : Brr.Blob.t -> init
    (** [of_blob b] is a body from blob [b]. *)

    val of_array_buffer : Brr.Tarray.Buffer.t -> init
    (** [of_array_buffer b] is a body from array buffer [b]. *)

    (** {1:interface Interface} *)

    type t
    (** The type for objects implementing the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Body}[Body]}
        interface. *)

    val body_used : t -> bool
    (** [body_used b] indicates
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Body/bodyUsed}
        indicates} if [b] was used. *)

    val body : t -> Jv.t option
    (** [body b] is [b] as a
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Body/body}
        stream}. *)

    val array_buffer : t -> Tarray.Buffer.t Fut.or_error
    (** [array_buffer b]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Body/arrayBuffer}
        reads} [b] into an array buffer. *)

    val blob : t -> Blob.t Fut.or_error
    (** [blob b]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Body/blob}
        reads} [b] as a blob. *)

    val form_data : t -> Form.Data.t Fut.or_error
    (** [form_data b]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Body/formData}
        reads} [b] as form data. *)

    val json : t -> Json.t Fut.or_error
    (** [json b]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Body/json}
        reads} [b] and parses it as JSON data. *)

    val text : t -> Jstr.t Fut.or_error
    (** [text b]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Body/text}reads}
        [b] and UTF-8 decodes it to a string. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Request and response headers.

      {b Warning.} We left out mutable operations out of the interface
      but remember these objects may mutate under your feet. *)
  module Headers : sig
    (** {1:headers Headers} *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Headers}[Headers]}
        objects. *)

    val mem : Jstr.t -> t -> bool
    (** [mem h hs] is [true] iff header [h] has a value in [hs].
        The lookup is case insensitive. *)

    val find : Jstr.t -> t -> Jstr.t option
    (** [find h hs] is the value of header [h] in [hs] (if any).
        The lookup is case insensitive. *)

    val fold : (Jstr.t -> Jstr.t -> 'a -> 'a) -> t -> 'a -> 'a
    (** [fold f hs acc] folds the headers [h] of [hs] and their value
        [v] with [f h v] starting with [acc]. It's unclear but
        header names are likely lowercased. *)

    (** {1:convert Converting} *)

    val of_obj : Jv.t -> t
    (** [of_obj o] uses the keys and values of object [o] to define
        headers and their value. *)

    val of_assoc : ?init:t -> (Jstr.t * Jstr.t) list -> t
    (** [of_assoc ~init assoc] are the headers from [init] (default si
        empty) to which the header value pairs of [assoc] are
        appended. If a header is defined more than once this either
        overwrites the previous definition, or appends to the value if
        if the value can be multi-valued. *)

    val to_assoc : t -> (Jstr.t * Jstr.t) list
    (** [to_assoc hs] are the headres [hs] as an assoc list.
        It's unclear but header names are likely lowercased. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Resource requests. *)
  module Request : sig

    (** {1:enums Enumerations} *)

    (** Request cache mode enum. *)
    module Cache : sig
      type t = Jstr.t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/cache#Value}[RequestCache]} values. *)

      val default : t
      val force_cache : t
      val no_cache : t
      val no_store : t
      val only_if_cached : t
      val reload : t
    end

    (** Request credentials mode enum. *)
    module Credentials : sig
      type t = Jstr.t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials#Value}[RequestCredentials]} values. *)

      val include' : t
      val omit : t
      val same_origin : t
    end

    (** Request destination enum. *)
    module Destination : sig
      type t = Jstr.t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/RequestDestination}[RequestDestination]} values. *)

      val audio : t
      val audioworklet : t
      val document : t
      val embed : t
      val font : t
      val frame : t
      val iframe : t
      val image : t
      val manifest : t
      val object' : t
      val paintworklet : t
      val report : t
      val script : t
      val sharedworker : t
      val style : t
      val track : t
      val video : t
      val worker : t
      val xslt : t
    end

    (** Request mode enum. *)
    module Mode : sig
      type t = Jstr.t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/mode#Value}
          [RequestMode]} values. *)

      val cors : t
      val navigate : t
      val no_cors : t
      val same_origin : t
    end

    (** Request redirect enum. *)
    module Redirect : sig
      type t = Jstr.t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/redirect#Value}
          [RequestRedirect]} values. *)

      val error : t
      val follow : t
      val manual : t
    end

    (** {1:req Requests} *)

    type init
    (** The type for request initialisation objects. *)

    val init :
      ?body:Body.init -> ?cache:Cache.t -> ?credentials:Credentials.t ->
      ?headers:Headers.t -> ?integrity:Jstr.t -> ?keepalive:bool ->
      ?method':Jstr.t ->  ?mode:Mode.t -> ?redirect:Redirect.t ->
      ?referrer:Jstr.t -> ?referrer_policy:Jstr.t ->
      ?signal:Abort.Signal.t -> unit -> init
    (** [init ()] is a request initialisation object with given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/Request#Parameters}parameters}. *)

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Request}[Request]} objects. *)

    val v : ?init:init -> Jstr.t -> t
    (** [v ~init uri] is a request on [uri] with parameters [init]. *)

    val of_request : ?init:init -> t -> t
    (** [of_request ~init r] is a copy of [r] updated by [init]. *)

    external as_body : t -> Body.t = "%identity"
    (** [as_body r] is the {!Body} interface of [r]. *)

    (** {1:props Properties} *)

    val cache : t -> Cache.t
    (** [cache r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/cache}
        cache} behaviour of [r]. *)

    val credentials : t -> Credentials.t
    (** [credentials r] are the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials}
        credentials} of [r]. *)

    val destination : t -> Destination.t
    (** [destination r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/destination}
        destination} of [r]. *)

    val headers : t -> Headers.t
    (** [headers r] are the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/headers}
        headers} of [r]. *)

    val integrity : t -> Jstr.t
    (** [integrity r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/integrity}
        integrity} of [r]. *)

    val is_history_navigation : t -> bool
    (** [is_history_navigation r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/isHistoryNavigation}
        [isHistoryNavigation]} property of [r]. *)

    val is_reload_navigation : t -> bool
    (** [is_reload_navigation r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/isReloadNavigation}
        [isReloadNavigation]} property of [r]. *)

    val keepalive : t -> bool
    (** [keepalive r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/keepalive}
        keepalive} behaviour of [r]. *)

    val method' : t -> Jstr.t
    (** [method' r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/method}
        method} of [r]. *)

    val mode : t -> Mode.t
    (** [mode r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/mode}
        mode} of [r]. *)

    val redirect : t -> Redirect.t
    (** [redirect r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/redirect}
        redirect} behaviour of [r]. *)

    val referrer : t -> Jstr.t
    (** [referrer r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/referrer}
        referrer} of [r]. *)

    val referrer_policy : t -> Jstr.t
    (** [referrer_policy r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/referrerPolicy}
        referrer policy} of [r]. *)

    val signal : t -> Abort.Signal.t option
    (** [signal r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/signal}
        abort signal} of [r]. *)

    val url : t -> Jstr.t
    (** [url r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Request/url}
        url} of [r]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Request responses. *)
  module Response : sig

    (** {1:enums Enumerations} *)

    (** Response type enum. *)
    module Type : sig
      type t = Jstr.t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Response/type#Value}[ResponseType]} values. *)

      val basic : t
      val cors : t
      val default : t
      val error : t
      val opaque : t
      val opaqueredirect : t
    end

    (** {1:resp Responses} *)

    type init
    (** The type for response initialisation objects. *)

    val init :
      ?headers:Headers.t -> ?status:int -> ?status_text:Jstr.t -> unit -> init
    (** [init ()] is a response initialisation object with given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Response/Response#Parameters}parameters}. *)

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Response}[Response]} objects. *)


    val v : ?init:init -> ?body:Body.init -> unit -> t
    (** [v ~init ~body] is a response with parameters [init] and body
        [body]. *)

    val of_response : t -> t
    (** [of_response r] is a copy of [r]. *)

    val error : unit -> t
    (** [error] is a
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Response/error}
        network error response}. *)

    val redirect : ?status:int -> Jstr.t -> t
    (** [redirect ~status url] is a
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Response/redirect}
        redirect response} to [url] with status [status]. *)

    external as_body : t -> Body.t = "%identity"
    (** [as_body r] is the {{!Body}body interface} of [r]. *)

    (** {1:props Properties} *)

    val headers : t -> Headers.t
    (** [headers r] are the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Response/headers}
        headers} of [r]. *)

    val ok : t -> bool
    (** [ok r] is [true] if the response [r] is
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Response/ok}
        successful}. *)

    val redirected : t -> bool
    (** [redirected r] is [true] if the reponse is the result of a
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Response/redirected}
        redirection}. *)

    val status : t -> int
    (** [status r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Response/status}
        status} of [r]. *)

    val status_text : t -> Jstr.t
    (** [status_text r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Response/statusText}
        status text} of [r]. *)

    val url : t -> Jstr.t
    (** [url r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Response/url}
        [url]} of [r]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Fetch caches. *)
  module Cache : sig

    type query_opts
    (** The type for query options. *)

    val query_opts :
      ?ignore_search:bool -> ?ignore_method:bool -> ?ignore_vary:bool ->
      ?cache_name:Jstr.t -> unit -> query_opts
    (** [query_opts ~ignore_search ~ignore_method ~ignore_vary ~cache_name ()]
        are query options with given {{:https://developer.mozilla.org/en-US/docs/Web/API/CacheStorage/match#Parameters}parameters}. *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Cache}Cache}
        objects. *)

    val match' :
      ?query_opts:query_opts -> t -> Request.t -> Response.t option Fut.or_error
    (** [match' c req] is a {{:https://developer.mozilla.org/en-US/docs/Web/API/Cache/match}stored response} for [req] in [c] (if any). *)

    val match_all :
      ?query_opts:query_opts -> t -> Request.t -> Response.t list Fut.or_error
    (** [match_all c req] is a list {{:https://developer.mozilla.org/en-US/docs/Web/API/Cache/matchAll}stored response} for [req] in [c]. *)

    val add : t -> Request.t -> unit Fut.or_error
    (** [add c req] fetches [req] and
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Cache/add}adds}
        the response to [c]. *)

    val add_all : t -> Request.t list -> unit Fut.or_error
    (** [add_all c reqs] fetches [reqs] and
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Cache/addAll}adds}
        their reponses to [c]. *)

    val put : t -> Request.t -> Response.t  -> unit Fut.or_error
    (** [put c req resp]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Cache/put}puts}
        the [req]/[resp] pair to the cache. *)

    val delete : ?query_opts:query_opts -> t -> Request.t -> bool Fut.or_error
    (** [delete c req] {{:https://developer.mozilla.org/en-US/docs/Web/API/Cache/delete}deletes} response to [req] from the cache. [false]
        is returned if [req] was not in the cache. *)

    val keys :
      ?query_opts:query_opts -> ?req:Request.t -> t ->
      Request.t list Fut.or_error
    (** [keys c] are the {{:https://developer.mozilla.org/en-US/docs/Web/API/Cache/keys}requests} cached by [c]. *)

    (** {1:cache_storage Cache storage} *)

    (** Cache storage objects. *)
    module Storage : sig

      type cache = t
      (** See {!t}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/CacheStorage}
          CacheStorage} objects. See {!Brr_io.Fetch.caches} to get one. *)

      val match' :
        ?query_opts:query_opts -> t -> Request.t ->
        Response.t option Fut.or_error
      (** [match' s req] is a {{:https://developer.mozilla.org/en-US/docs/Web/API/CacheStorage/match}stored response} for [req] in [s] (if any). *)

      val has : t -> Jstr.t -> bool Fut.or_error
      (** [has s n] is [true] if [n] matches a {{:https://developer.mozilla.org/en-US/docs/Web/API/CacheStorage/has}cache name} in [s]. *)

      val open' : t -> Jstr.t -> cache Fut.or_error
      (** [open' s n] {{:https://developer.mozilla.org/en-US/docs/Web/API/CacheStorage/open}opens} the cache named [n] of [s]. *)

      val delete : t -> Jstr.t -> bool Fut.or_error
      (** [delete s n] {{:https://developer.mozilla.org/en-US/docs/Web/API/CacheStorage/delete}deletes} the cache named [n] from [s]. [false] is returned
          if [n] did not exist. *)

      val keys : t -> Jstr.t list Fut.or_error
      (** [keys s] are the {{:https://developer.mozilla.org/en-US/docs/Web/API/CacheStorage/keys}cache names} in [s]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end
    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Fetch events. *)
  module Ev : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FetchEvent}
        [FetchEvent]} objects. *)

    val fetch : t Ev.type'
    (** [fetch] is the [fetch] event type. *)

    val as_extendable : t -> Ev.Extendable.t Ev.t
    (** [as_extendable e] is [e] as an extendable event. *)

    val request : t ->  Request.t
    (** [request e] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FetchEvent/request}
        request} being fetched. *)

    val preload_response : t -> Response.t option Fut.or_error
    (** [preload_response e] is a navigation response {{:https://developer.mozilla.org/en-US/docs/Web/API/FetchEvent/preloadResponse}preload} (if any). *)

    val client_id : t -> Jstr.t
    (** [client_id e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/FetchEvent/clientId}client id} of [e]. *)

    val resulting_client_id : t -> Jstr.t
    (** [resulting_client_id e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/FetchEvent/resultingClientId}resulting} client id. *)

    val replaces_client_id : t -> Jstr.t
    (** [replaces_client_id e] is the client id being
        {{:https://developer.mozilla.org/en-US/docs/Web/API/FetchEvent/replacesClientId}replaced}. *)

    val handled : t -> unit Fut.or_error
    (** [handled e] is obscure. *)

    val respond_with : t -> Response.t Fut.or_error -> unit
    (** [respond_with e resp] replace the browser's default fetch handling
        with the {{:https://developer.mozilla.org/en-US/docs/Web/API/FetchEvent/respondWith}
        response} [resp]. *)
  end

  val url : ?init:Request.init -> Jstr.t -> Response.t Fut.or_error
  (** [url ~init u] {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/fetch}fetches} URL [u] with the [init] request object. *)

  val request : Request.t -> Response.t Fut.or_error
  (** [request r] {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/fetch}fetches} request [r]. *)

  val caches : unit -> Cache.Storage.t
  (** [caches ()] is the global
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/caches}[caches]} object. *)
end

(** Access to device location.

    See {{:https://developer.mozilla.org/en-US/docs/Web/API/Geolocation_API}
    Geolocation API}. *)
module Geolocation : sig

  (** Position errors. *)
  module Error : sig

    (** {1:codes Codes} *)

    type code = int
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationPositionError/code#Value}error code} values. *)

    val permission_denied : code
    val position_unavailable : code
    val timeout : code

    (** {1:errors Errors} *)

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationPositionError}[GelocationPositionError]} objects. *)

    val code : t -> code
    (** [code e] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationPositionError/code}error code} of [e]. *)

    val message : t -> Jstr.t
    (** [message e] is a
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationPositionError/message}human readable} error message. For programmers, not for end
        users. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Positions. *)
  module Pos : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationPosition}[GeolocationPosition]} objects (and their
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationCoordinates}[GeolocationCoordinates]} member). *)

    val latitude : t -> float
    (** [latitude p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationCoordinates/latitude}latitude} in decimal degrees. *)

    val longitude : t -> float
    (** [longitude p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationCoordinates/longitude}longitude} in decimal degrees. *)

    val accuracy : t -> float
    (** [accuracy p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationCoordinates/accuracy}accuracy}, in meters, of the {!latitude}
        and {!longitude} in meters. *)

    val altitude : t -> float option
    (** [altitude p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationCoordinates/altitude}altitude} in meters relative to sea level. *)

    val altitude_accuracy : t -> float option
    (** [altitude_accuracy p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationCoordinates/altitudeAccuracy}altitude accuracy}, in meters,
        of the {!altitude}. *)

    val heading : t -> float option
    (** [heading p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationCoordinates/heading}direction} in degree with respect to true north
        (90° is east). If {!speed} is [0], this is [nan]. *)

    val speed : t -> float option
    (** [speed p] is the device {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationCoordinates/speed}velocity} in meters per seconds. *)

    val timestamp_ms : t -> float
    (** [timestamp_ms p] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/GeolocationPosition/timestamp}time} of measurement in [ms] since
        the epoch. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  type opts
  (** The type for geolocalisation options. *)

  val opts :
    ?high_accuracy:bool -> ?timeout_ms:int -> ?maximum_age_ms:int -> unit ->
    opts
  (** [opts ~high_accuracy ~maximum_age_ms ~timeout_ms ()] are geolocalisation
      {{:https://developer.mozilla.org/en-US/docs/Web/API/PositionOptions#Properties}options}. *)

  (** {1:geoloc Geolocalizing} *)

  type t
  (** The type for device {{:https://developer.mozilla.org/en-US/docs/Web/API/Geolocation}[Geolocation]} objects. *)

  val of_navigator : Navigator.t -> t
  (** [of_navigator n] is a device geolocalisation object for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Navigator/geolocation}navigator} [n]. *)

  val get : ?opts:opts -> t -> (Pos.t, Error.t) Fut.result
  (** [get l ~opts] is the position of [l]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/getCurrentPosition}determined}
      with options [opts]. *)

  type watch_id = int
  (** The type for watcher identifiers. *)

  val watch : ?opts:opts -> t -> ((Pos.t, Error.t) result -> unit) -> watch_id
  (** [watch l ~opts f] {{:https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/watchPosition}monitors} the position of [l] determined with [opts] by
      periodically calling [f]. Stop watching by calling {!unwatch} with
      the returned identifier. *)

  val unwatch : t -> watch_id -> unit
  (** [unwatch l id] {{:https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/clearWatch}unwatches} [id] as returned by a previous call to {!watch}. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** Access to media devices, streams and elements.

    Access to the {{:https://w3c.github.io/mediacapture-main}Media
    Capture and Streams} API, the
    {{:https://w3c.github.io/mediacapture-record/} MediaStream
    Recording} API and the
    {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement}
    [HTMLMediaElement]} interface. *)
module Media : sig

  (** {1:constrainable Constrainable pattern}

      The following little bureaucracy tries to expose
      the {{:https://w3c.github.io/mediacapture-main/#constrainable-interface}
      constrainable pattern} in a lean way.
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Media_Streams_API/Constraints}This introduction} on MDN may also be useful. *)

  (** Media objects properties, capabilities and constraints. *)
  module Prop : sig

    (** {1:range_constraits Ranges and constraints} *)

    (** [bool] constraints. *)
    module Bool : sig
      module Constraint : sig
        type t
        (** The type for [bool] constraints. *)

        val v : ?exact:bool -> ?ideal:bool -> unit -> t
      end
    end

    (** [int] ranges and constraints. *)
    module Int : sig
      module Range : sig
        type t
        (** The type for integer ranges. *)

        val v : ?min:int -> ?max:int -> unit -> t
        val min : t -> int option
        val max : t -> int option
        (**/**)
        include Jv.CONV with type t := t
        (**/**)
      end
      module Constraint : sig
        type t
        (** The type for integer range constraints. *)

        val v : ?min:int -> ?max:int -> ?exact:int -> ?ideal:int -> unit -> t

        (**/**)
        include Jv.CONV with type t := t
        (**/**)
      end
    end

    (** [float] ranges and constraints. *)
    module Float : sig
      module Range : sig
        type t
        (** The type for float ranges. *)

        val v : ?min:float -> ?max:float -> unit -> t
        val min : t -> float option
        val max : t -> float option
        (**/**)
        include Jv.CONV with type t := t
        (**/**)
      end
      module Constraint : sig
        type t
        (** The type for float range constraints. *)

        val v : ?min:float -> ?max:float -> ?exact:float -> ?ideal:float ->
          unit -> t

        (**/**)
        include Jv.CONV with type t := t
        (**/**)
      end
    end

    (** [Jstr] constraints. *)
    module Jstr : sig
      type t = Jstr.t
      module Constraint : sig
        type t
        (** The type for [bool] constraints. *)

        val v : ?exact:Jstr.t list -> ?ideal:Jstr.t list -> unit -> t

        (**/**)
        include Jv.CONV with type t := t
        (**/**)
      end
    end

    (** {1:props Properties} *)

    type ('a, 'b, 'c) t
    (** The type for properties of type ['a] whose capabilities
        are described by ['b] and which are constrained by ['c]. *)

    type bool_t = (bool, bool list, Bool.Constraint.t) t
    (** The type for boolean properties. *)

    val bool : Jstr.t -> bool_t
    (** [bool n] is a bool property named [n]. *)

    type int_t = (int, Int.Range.t, Int.Constraint.t) t
    (** The type for integer properties. *)

    val int : Jstr.t -> int_t
    (** [int n] is an integer property named [n]. *)

    type float_t = (float, Float.Range.t, Float.Constraint.t) t
    (** The type for floating point properties. *)

    val float : Jstr.t -> float_t
    (** [float n] is a float property named [n]. *)

    type jstr_t = (Jstr.t, Jstr.t, Jstr.Constraint.t) t
    (** The type for string properties. *)

    val jstr : Jstr.t -> jstr_t
    (** [jstr n] is a string property named [n]. *)

    type jstr_enum_t = (Jstr.t, Jstr.t list, Jstr.Constraint.t) t
    (** The type for string enumeration properties. *)

    val jstr_enum : Jstr.t -> jstr_enum_t
    (** [jstr n] is a string enumeration property named [n]. *)

    (** {1:low Low-level interface} *)

    type 'a conv = ('a -> Jv.t) * (Jv.t -> 'a)
    (** ['a conv] specifies encoding and decoding functions for JavaScript. *)

    val v : Jstr.t -> 'a conv -> 'b conv -> 'c conv -> ('a, 'b, 'c) t
    (** [v v_conv cap_conv constr_conv n] is a new property named [n] whose
        values are converted with [v_conv], capabilities with [cap_conv] and
        constraints with [constr_conv]. *)

    val name : ('a, 'b, 'c) t -> Jstr.t
    (** [name p] is the name of the property. *)

    val value_of_jv : ('a, 'b, 'c) t -> Jv.t -> 'a
    (** [of_jv p jv] is the property value of [p] from [jv]. *)

    val value_to_jv : ('a, 'b, 'c) t -> 'a -> Jv.t
    (** [to_jv p v] is the JavaScript value of [p] for [v]. *)

    val cap_of_jv : ('a, 'b, 'c) t -> Jv.t -> 'b
    (** [cap_of_jv p jv] is the property capability of [p] from [jv]. *)

    val cap_to_jv : ('a, 'b, 'c) t -> 'b -> Jv.t
    (** [cap_jv p v] is the capability value of [p] for [v]. *)

    val constr_of_jv : ('a, 'b, 'c) t -> Jv.t -> 'c
    (** [cap_of_jv p jv] is the property constraint of [p] from [jv]. *)

    val constr_to_jv : ('a, 'b, 'c) t -> 'c -> Jv.t
    (** [cap_jv p v] is the cosntraint value of [p] for [v]. *)
  end

  (** Supported property constraints.

      Indicates the media properties constraints the user agent
      understands. *)
  module Supported_constraints : sig

    type t
    (** The type for supported constraints. *)

    val mem : ('a, 'b, 'c) Prop.t -> t -> bool
    (** [supports p n] is true if property [p] can be constrained. *)

    val names : t -> Jstr.t list
    (** [supported s] is the list of supported constraints. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Property constraints specifications. *)
  module Constraints : sig
    type t
    (** The type for constraints. *)

    val empty : unit -> t
    (** [empty ()] is an empty set of constraints. *)

    val find : ('a, 'b, 'c) Prop.t -> t -> 'c option
    (** [find p s] is the constraint for [p] in [c] (if any). *)

    val set : ('a, 'b, 'c) Prop.t -> 'c -> t -> unit
    (** [set p v c] sets the constraint for [p] to [v] in [c]. *)

    val delete : ('a, 'b, 'c) Prop.t -> t -> unit
    (** [delete p c] deletes the constraint for [p] from [c]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Property capability specifications. *)
  module Capabilities : sig
    type t
    (** The type for capabilities. *)

    val find : ('a, 'b, 'c) Prop.t -> t -> 'b option
    (** [find p s] is the capability of [p] in [c] (if any). *)

    val set : ('a, 'b, 'c) Prop.t -> 'b -> t -> unit
    (** [set p v c] sets the capability of [p] to [v] in [c]. *)

    val delete : ('a, 'b, 'c) Prop.t -> t -> unit
    (** [delete p c] deletes the capability of [p] from [c]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Property values. *)
  module Settings : sig
    type t
    (** The type for settings. *)

    val get : ('a, 'b, 'c) Prop.t -> t -> 'a
    (** [get p s] is the value of [p] in [s]. *)

    val find : ('a, 'b, 'c) Prop.t -> t -> 'a option
    (** [find p s] is the value of [p] in [s] (if any). *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** {1:media Media devices, streams and tracks} *)

  (** Media stream tracks. *)
  module Track : sig

    (** {1:enum Enumerations and properties} *)

    (** Track state enumeration. *)
    module State : sig
      type t = Jstr.t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/readyState#Value}MediaStreamTrackState} values. *)

      val live : t
      val ended : t
    end

    (** Track kind enumeration. *)
    module Kind : sig
      type t = Jstr.t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/kind#Value}track kind} values. *)

      val audio : t
      val video : t
    end

    (** Track properties *)
    module Prop : sig

      val aspect_ratio : Prop.float_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/aspectRatio}[aspectRatio]} property. *)

      val auto_gain_control : Prop.bool_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/autoGainControl}[autoGainControl]} property. *)

      val channel_count : Prop.int_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/channelCount}[channelCount]} property. *)

      val cursor : Prop.jstr_enum_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/cursor}[cursor]} property. *)

      val device_id : Prop.jstr_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/deviceId}[deviceId]} property. *)

      val display_surface : Prop.jstr_enum_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/displaySurface}[displaySurface]} property. *)

      val echo_cancellation : Prop.bool_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/echoCancellation}[echoCancellation]} property. *)

      val facing_mode : Prop.jstr_enum_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/facingMode}[facingMode]} property. *)

      val frame_rate : Prop.float_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/frameRate}[frameRate]} property. *)

      val group_id : Prop.jstr_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/groupId}[groupId]} property. *)

      val height : Prop.int_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/height}[height]} property. *)

      val latency : Prop.float_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/latency}[latency]} property. *)

      val logical_surface : Prop.bool_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/logicalSurface}[logicalSurface]} property. *)

      val noise_suppresion : Prop.bool_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/noiseSuppression}[noiseSuppression]} property. *)

      val resize_mode : Prop.jstr_enum_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/resizeMode}[resizeMode]} property. *)

      val sample_rate : Prop.int_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/sampleRate}[sampleRate]} property. *)

      val sample_size : Prop.int_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/sampleSize}[sampleSize]} property. *)

      val width : Prop.int_t
      (** The {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/width}[width]} property. *)
    end

    (** {1:tracks Tracks} *)

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack}[MediaStreamTrack]} objects. *)

    external as_target : t -> Ev.target = "%identity"
    (** [as_target t] is [t] as an event target. *)

    val id : t -> Jstr.t
    (** [id t] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/id}unique identifier} of [t]. *)

    val isolated : t -> bool
    (** [isolated t] is the
        {{:https://w3c.github.io/webrtc-identity/#dfn-isolated}isolation status}
        of [t]. *)

    val kind : t -> Kind.t
    (** [kind] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/kind}kind} of [t]. *)

    val label : t -> Jstr.t
    (** [label t] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/label}label} of [t]. *)

    val muted : t -> bool
    (** [muted t] is [true] if [t] is
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/muted}muted}. Use {!set_enabled} to manually mute and unmute a track. Use events
        {!Ev.mute} and {!Ev.unmute} to monitor mute status. *)

    val ready_state : t -> State.t
    (** [ready_state t] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/readyState}status} of the track. Use event {!Ev.ended} to monitor ready state. *)

    val enabled : t -> bool
    (** [enabled t] is [true] if the track is {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/enabled}allowed} to render the source
        and [false] if it's not. Use {!set_enabled} to control this. *)

    val set_enabled : t -> bool -> unit
    (** [set_enabled t b] sets the track {!enabled} status to [b].
        If the track has been disconnected this has no effect. *)

    val get_capabilities : t -> Capabilities.t
    (** [get_capabilities t] are the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/getCapabilities}capabilities} of [t]. *)

    val get_constraints : t -> Constraints.t
    (** [get_constraints t] are the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints}constraints} of [t]. *)

    val apply_constraints : t -> Constraints.t option -> unit Fut.or_error
    (** [apply_contraints t] applies the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/applyConstraints}applies}
        the given contraints.  Constraints unspecified are restored to
        their default value.  If no contraints are given all
        contraints are restored to their defaults.  *)

    val get_settings : t -> Settings.t
    (** [get_settings t] are the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings}settings} of [t]. *)

    val stop : t -> unit
    (** [stop t] {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/stop}stops} the track. *)

    val clone : t -> t
    (** [clone t] creates a {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/clone}copy} of [t] equal to it except for its {!id}. *)

    (** {1:events Events} *)

    (** Track events. *)
    module Ev : sig

      (** {1:obj Track event object} *)

      type track = t
      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrackEvent} [MediaStreamTrackEvent]} objects. *)

      val track : t -> track
      (** [track e] is the track object associated to the event. *)

      (** {1:track_event Track events} *)

      val ended : Ev.void
      (** [ended] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/ended_event}ended} event. *)

      val isolationchange : Ev.void
      (** [isolationchange] is the
          {{:https://w3c.github.io/webrtc-identity/#event-isolationchange}
          isolationchange} event. *)

      val mute : Ev.void
      (** [mute] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/mute_event}[mute]} event. *)

      val unmute : Ev.void
      (** [ummute] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/unmute_event}unmute} event. *)
    end

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Media streams. *)
  module Stream : sig

    (** Media stream constraints. *)
    module Constraints : sig
      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamConstraints}[MediaStreamConstraints]}
          objects. *)

      type track = [ `No | `Yes of Constraints.t option ]
      (** The type for specifying track constraints. *)

      val v : ?audio:track -> ?video:track -> unit -> t
      (** [v ~audio ~video ()] are stream constraints with
          given arguments. If unspecified they default to [`No]. *)

      val av : unit -> t
      (** [av] says [`Yes None] to audio and video. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    type t
     (** The type for
         {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStream}[MediaStream]} objects. *)

    val create : unit -> t
    (** [create ()] is a stream without tracks. *)

    val of_stream : t -> t
    (** [of_stream s] is a new stream which shares its tracks with [s]. *)

    val of_tracks : Track.t list -> t
    (** [of_tracks ts] is a stream with tracks [ts]. *)

    external as_target : t -> Ev.target = "%identity"
    (** [as_target s] is [s] as an event target. *)

    val id : t -> Jstr.t
    (** [id s] is a {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStream/id}unique identifier} for [s]. *)

    val active : t -> bool
    (** [active s] is [true] if [s] is {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStream/active}active}.*)

    val get_audio_tracks : t -> Track.t list
    (** [get_audio_tracks s] is the list of
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStream/getAudioTracks}audio tracks} of [s]. *)

    val get_video_tracks : t -> Track.t list
    (** [get_video_tracks s] is the list of
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStream/getVideoTracks}video tracks} of [s]. *)

    val get_tracks : t -> Track.t list
    (** [get_tracks s] is the list of
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStream/getTracks}tracks} of [s]. *)

    val get_track_by_id : t -> Jstr.t -> Track.t option
    (** [get_track_by_id s id]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStream/getTrackById}finds} the track identified by [id] (if any). *)

    val add_track : t -> Track.t -> unit
    (** [add_track s t] {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStream/addTrack}adds} track [t] so [s]. If [t] was already in [s]
       nothing happens. *)

    val remove_track : t -> Track.t -> unit
    (** [remove_track s t] {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStream/removeTrack}removes} track [t] from [s]. If [t] was not in [s]
        nothing happens. *)

    val clone : t -> t
    (** [clone s] {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStream/clone}clones} the tracks of [s] and [s] itself. It has the same
        parameters except for [id]. *)

    (** {1:events Events} *)

    (** Stream events *)
    module Ev : sig
      val addtrack : Track.Ev.t Ev.type'
      (** [addtrack] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStream/onaddtrack}[addtrack]} event. *)

      val removetrack : Track.Ev.t Ev.type'
      (** [removetrack] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStream/onremovetrack}[removetrack]} event. *)
    end

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Media recorder.

      See the {{:https://w3c.github.io/mediacapture-record/}
      MediaStream Recording} API. *)
  module Recorder : sig

    (** {1:enums Enumerations} *)

    (** Bitrate mode enumeration. *)
    module Bitrate_mode : sig
      type t = Jstr.t
      (** The type for {{:https://w3c.github.io/mediacapture-record/#bitratemode}[BitrateMode]} values. *)

      val cbr : t
      val vbr : t
    end

    (** Recording state enumeration. *)
    module Recording_state : sig
      type t = Jstr.t
      (** The type for {{:https://w3c.github.io/mediacapture-record/#recordingstate}[RecordingState]} values. *)

      val inactive : t
      val recording : t
      val paused : t
    end

    (** {1:recorders Recorder} *)

    val is_type_supported : Jstr.t -> bool
    (** [is_type_supported t] is [true] if recording to MIME type
        [t] is {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/isTypeSupported}supported}. *)

    type init
    (** The type for initialisation objects. *)

    val init :
      ?type':Jstr.t -> ?audio_bps:int -> ?video_bps:int -> ?bps:int ->
      ?audio_bitrate_mode:Bitrate_mode.t -> unit -> init
    (** [init ()] is a media recorder initialisation object with given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/MediaRecorder#Parameters}parameters}. *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder}[MediaRecorder]} objects. *)

    val create : ?init:init -> Stream.t -> t
    (** [create ~init r] is a
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/MediaRecorder}recorder} for [s]. The function
        raises if the [type'] of the [init] object
        is not {{!is_type_supported}supported}. *)

    val stream : t -> Stream.t
    (** [stream r] *)

    val type' : t -> Jstr.t
    (** [type' r] is the stream's MIME type. *)

    val state : t -> Recording_state.t
    (** [state r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/state}recording state} of [r]. *)

    val video_bps : t -> int
    (** [video_bps r] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/videoBitsPerSecond}video encoding bit rate} of [s]. *)

    val audio_bps : t -> int
    (** [audio_bps r] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/audioBitsPerSecond}audio encoding bit rate} of [s]. *)

    val audio_bitrate_mode : t -> Bitrate_mode.t
    (** [audio_bps r] is the {{:https://w3c.github.io/mediacapture-record/#dom-mediarecorder-audiobitratemode}audio encoding mode} of [s]. *)

    val start : t -> timeslice_ms:int option -> (unit, Jv.Error.t) result
    (** [start r ~timeslice_ms]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/start}starts} [r]. [timeslice_ms] indicates the number of milliseconds to record in
    each blob. If not specified the whole duration is in a single blob,
        unless {!request_data} is invoked to drive the process. *)

    val stop : t -> unit
    (** [stop r] {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/stop}stops} [r]. *)

    val pause : t -> unit
    (** [pause r] {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/pause}pauses} [r]. *)

    val resume : t -> unit
    (** [resume r] {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/resume}resume} [r]. *)

    val request_data : t -> unit
    (** [request_data] {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/requestData}requests} the data of [r]. *)

    (** {1:events Events} *)

    module Ev : sig

      (** {1:obj Event objects} *)

      (** Blob events. *)
      module Blob : sig
      type t
      (** The type for
          {{:https://w3c.github.io/mediacapture-record/#blobevent-section}
          [BlobEvent]} objects. *)

      val data : t -> Blob.t
      (** [data e] is the requested data as a blob object. *)

      val timecode : t -> float
      (** [timecode e] is the difference between timestamp of the first
          chunk in {!data} and the one produced by the first chunk in the
          first blob event produced by the recorder (that one may not
          be zero). *)
    end

      (** Recorder errors. *)
      module Error : sig
        type t
        (** The type for
            {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorderErrorEvent} [MediaRecorderErrorEvent]} objects. *)

        val error : t -> Jv.Error.t
        (** [error e] is the event's {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorderErrorEvent/error}error}. *)
      end

      (** {1:events Recorder events} *)

      val start : Ev.void
      (** [start] is the recorder {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/onstart}[start]} event. *)

      val stop : Ev.void
      (** [stop] is the recorder {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/onstop}[stop]} event. *)

      val dataavailable : Blob.t Ev.type'
      (** [dataavailable] is the recorder {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/ondataavailable}[dataavailable]} event. *)

      val pause : Ev.void
      (** [pause] is the recorder {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/onpause}[pause]} event. *)

      val resume : Ev.void
      (** [resume] is the recorder {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/onresume}[resume]} event. *)

      val error : Error.t Ev.type'
      (** [error] is the recorder {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/onerror}[error]} event. *)
    end
  end

  (** Device kinds and information. *)
  module Device : sig

    (** Device kind enumeration. *)
    module Kind : sig
      type t = Jstr.t
      (** The type for
          {{:https://w3c.github.io/mediacapture-main/#dom-mediadevicekind}
          [MediaDeviceKind]} values. *)

      val audioinput : t
      val audiooutput : t
      val videoinput : t
    end

    (** Device information. *)
    module Info : sig
      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices}[MediaDeviceInfo]} objects. *)

      val device_id : t -> Jstr.t
      (** [device_id d] is the identifier of the device. *)

      val kind : t -> Kind.t
      (** [kind d] is the kind of device. *)

      val label : t -> Jstr.t
      (** [label d] is a label describing the device. *)

      val group_id : t -> Jstr.t
      (** [group_id d] is the group identifier of the device. Two devices
          have the same group identifier if they belong to the same physical
          device. *)

      val to_json : t -> Json.t
      (** [to_json d] is [d] as JSON data. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end
  end

  (** Media device enumeration. *)
  module Devices : sig

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices}[MediaDevices]} objects. *)

    val of_navigator : Navigator.t -> t
    (** [of_navigator n] provides access to media devices of [n]. *)

    external as_target : t -> Ev.target = "%identity"
    (** [as_target m] is [m] as an event target. *)

    val enumerate : t -> Device.Info.t list Fut.or_error
    (** [enumerate m]
    {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/enumerateDevices}determines}
    a list of connected media devices. Monitor changes by listening
    {!Ev.devicechange} on [m]. *)

    val get_supported_constraints : t -> Supported_constraints.t
    (** [get_supported_constraints m]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getSupportedConstraints}determines}
        the media constraints the user agent understands. *)

    val get_user_media : t -> Stream.Constraints.t -> Stream.t Fut.or_error
    (** [get_user_media m c]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia}prompts}
        the user to use a media input which can produce a media stream
        constrained by [c].
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia#Exceptions}These
        errors} can occur. In particular [Jv.Error.Not_allowed] and
        [Jv.Error.Not_found] should be reported to the user in a
        friendly way. In some browsers this call has to done
        in a user interface event handler. *)

    val get_display_media : t -> Stream.Constraints.t -> Stream.t Fut.or_error
    (** [get_display_media m c]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getDisplayMedia}prompts} the user to select and grant permission to capture the
        contents of a display as a media stream. A video
        track is unconditionally returned even if [c] says otherwise.
        In some browsers this call has to done in a user interface event
        handler.

        See this
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Screen_Capture_API/Using_Screen_Capture}MDN article} for more details. *)

    (** {1:events Events} *)

    (** Device events. *)
    module Ev : sig
      val devicechange : Ev.void
      (** [devicechange] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/devicechange_event}[devicechange]} event. Monitors
          media device additions and removals on [MediaDevice] objects. *)
    end

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** {1:el Media element interface} *)

  (** The HTML {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement}media element interface}.

      {b Warning.} This binding is incomplete, the modules
      {!El.Audio_track}, {!El.Video_track}, {!El.Text_track} are mostly
      empty. *)
  module El : sig

    (** {1:prelim Preliminaries} *)

    (** Media errors *)
    module Error : sig

      (** {1:codes Error codes} *)

      type code = int
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code#Value}error code} values. *)

      val aborted : code
      val network : code
      val decode : code
      val src_not_supported : code

      (** {1:obj Error objects} *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaError}
          [MediaError]} objects. *)

      val code : t -> code
      (** [code e] is the error
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code}
          code}. *)

      val message : t -> Jstr.t
      (** [message e] is the error {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaError/message}message}. *)
    end

    (** Can play enum. *)
    module Can_play : sig
      type t = Jstr.t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/canPlayType#Return_value}can play} values. *)

      val maybe : t
      val probably : t
    end

    (** Ready state codes. *)
    module Have : sig
      type t = int
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/readyState#Value}read state} values. *)

      val nothing : t
      val metadata : t
      val current_data : t
      val future_data : t
      val enought_data : t
    end

    (** Network state codes. *)
    module Network : sig
      type t = int
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/networkState#Value}network state} values. *)

      val empty : t
      val idle : t
      val loading : t
      val no_source : t
    end

    (** CORS settings *)
    module Cors : sig
      type t = Jstr.t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/crossorigin}CORS} values. *)

      val anonymous : t
      val use_credentials : t
    end

    (** Media providers. *)
    module Provider : sig
      type t
      (** The type for
          {{:https://html.spec.whatwg.org/multipage/media.html#mediaprovider}
          [MediaProvider]} objects. *)

      val of_media_stream : Stream.t -> t
      val of_blob : Blob.t -> t
      val of_media_source : Jv.t -> t
      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Audio tracks (incomplete). *)
    module Audio_track : sig
      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack}
          [AudioTrack]} objects. *)

      (** Audio track lists. *)
      module List : sig
        type t
        (** The type for
            {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioTrackList}
            [AudioTrackList]} objects. *)
        (**/**)
        include Jv.CONV with type t := t
        (**/**)
      end

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Video tracks (incomplete). *)
    module Video_track : sig
      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/VideoTrack}
          VideoTrack} objects. *)

      module List : sig
        type t
        (** The type for
            {{:https://developer.mozilla.org/en-US/docs/Web/API/VideoTrackList}
            [VideoTrackList]} objects *)

        (**/**)
        include Jv.CONV with type t := t
        (**/**)
      end

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Text tracks (incomplete). *)
    module Text_track : sig
      module Kind : sig
        type t = Jstr.t
      end

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/TextTrack}
          TextTrack} objects. *)

      (** Text track lists. *)
      module List : sig
        type t
        (** The type for
            {{:https://developer.mozilla.org/en-US/docs/Web/API/TextTrackList}
            [TextTrackList]} objects. *)

        (**/**)
        include Jv.CONV with type t := t
        (**/**)
      end

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Time ranges. *)
    module Time_ranges : sig
      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/TimeRanges}
          [TimeRange]} objects. *)

      val length : t -> int
      (** [length r] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/TimeRanges/length}length} of [r]. *)

      val start : t -> int -> float
      (** [start r i] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/TimeRanges/start}start} time of range [i] in [r]. *)

      val end' : t -> int -> float
      (** [end' r i] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/TimeRanges/end'}end} time of range [i] in [r]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** {1:iface Media interface} *)

    type t
    (** The type for elements satifying the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement}
        [HTMLMediaElement]} interface. *)

    val of_el : El.t -> t
    (** [of_el e] is the media interface of [e]. This throws a JavaScript
      error if [e] is not a {!Brr.El.audio} or {!Brr.El.video} element.  *)

    val to_el : t -> El.t
    (** [to_el m] is [m] as an an element. *)

    (** {1:error_state Error state} *)

    val error : t -> Error.t option
    (** [error m] is the most recent
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/error}error} of [m]. *)

    (** {1:network_state Network state} *)

    val src : t -> Jstr.t
    (** [src m] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/src}URI source} of the played media. *)

    val set_src : t -> Jstr.t -> unit
    (** [set_src m s] sets the {!src} of [m] to [s]. *)

    val src_object : t -> Provider.t option
    (** [src_object m s] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/srcObject}source object} of [m]. *)

    val set_src_object : t -> Provider.t option -> unit
    (** [set_src_object m o] sets the {!src_object} of [m] to [o]. *)

    val current_src : t -> Jstr.t
    (** [current_src m] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/currentSrc}current source} of [m]. *)

    val cross_origin : t -> Cors.t
    (** [cross_origin m] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/crossOrigin}CORS setting} of [m]. *)

    val set_cross_origin : t -> Cors.t -> unit
    (** [set_cross_origin m c] sets the {!cross_origin} of [m] to [c]. *)

    val network_state : t -> Network.t
    (** [network_state m] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/networkState}network state} of [m]. *)

    val preload : t -> Jstr.t
    (** [preload m] is the preload state of [m]. *)

    val set_preload : t -> Jstr.t -> unit
    (** [set_preload m p] sets the preload of [m] to [p]. *)

    val buffered : t -> Time_ranges.t
    (** [buffered m] are the ranges of media that
        are {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/buffered}buffered}: *)

    val load : t -> unit
    (** [load m] restarts
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/load}loading} [m]. *)

    val can_play_type : t -> Jstr.t -> Can_play.t
    (** [can_play_type m t] indicates if [m]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/canPlayType}can play} [t]. *)

    (** {1:ready_state Ready state} *)

    val ready_state : t -> Have.t
    (** [ready_state m] indicates the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/readyState}readiness} of [m]. *)

    val seeking : t -> bool
    (** [seeking m] indicates [m] is seeking a new position. *)

    (** {1:playback_state Playback state} *)

    val current_time_s : t -> float
    (** [current_time m] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/currentTime}current time} of [m]. *)

    val set_current_time_s : t -> float -> unit
    (** [set_current_time_s m t] sets the {!current_time_s} of [m] to [t]. *)

    val fast_seek_s : t -> float -> unit
    (** [fast_seek_s m t]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/fastSeek}seeks} [m] to [t]. *)

    val duration_s : t -> float
    (** [duration_s m] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/duration}duration} of [m]. *)

    val paused : t -> bool
    (** [paused m] indicates whether [m] is
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/paused}paused}. *)

    val default_playback_rate : t -> float
    (** [default_playback_rate m] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/defaultPlaybackRate}default playback rate} of [m]. *)

    val set_default_playback_rate : t -> float -> unit
    (** [set_default_playback_rate m] sets the {!default_playback_rate}
        of [m]. *)

    val playback_rate : t -> float
    (** [playback_rate m] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/playbackRate}playback rate} of [m]. *)

    val set_playback_rate : t -> float -> unit
    (** [set_playback_rate m] sets the {!playback_rate}
        of [m]. *)

    val played : t -> Time_ranges.t
    (** [played m] are the ranges that have been played. *)

    val seekable : t -> Time_ranges.t
    (** [seekable m] indicates the time ranges that are
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/seekable}seekable}.  *)

    val ended : t -> bool
    (** [ended m] is [true] if the media has
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/ended}finished} playing. *)

    val autoplay : t -> bool
    (** [autoplay m] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/autoplay}autoplay} behaviour of [m]. *)

    val set_auto_play : t -> bool -> unit
    (** [set_auto_play m b] sets {!autoplay} of [m] to [b]. *)

    val loop : t -> bool
    (** [loop m] inidicates if [m] is set to {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/loop}loop}. *)

    val set_loop : t -> bool -> unit
    (** [set_loop m b] sets the {!loop} of [m] to [b]. *)

    val play : t -> unit Fut.or_error
    (** [play m]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/play}plays} [m]. *)

    val pause : t -> unit
    (** [pause m]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/pause}pauses} [m]. *)

    (** {1:ctrls Controls} *)

    val controls : t -> bool
    (** [controls m] indicates if media controls are
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/controls}shown}. *)

    val set_controls : t -> bool -> unit
    (** [set_controls m b] sets the {!controls} of [m] to [b]. *)

    val volume : t -> float
    (** [volume m] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/volume}volume} of [m]. *)

    val set_volume : t -> float -> unit
    (** [set_volume m b] sets the {!volume} of [m] to [b]. *)

    val muted : t -> bool
    (** [muted m] indicates whether audio is {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/muted}muted}. *)

    val set_muted : t -> bool -> unit
    (** [set_muted m b] sets the {!muted} of [m] to [b]. *)

    val default_muted : t -> bool
    (** [default_muted m] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/defaultMuted}default muted} state. *)

    val set_default_muted : t -> bool -> unit
    (** [set_default_muted m b] sets the {!default_muted} of [m] to [b]. *)

    (** {1:tracks Tracks} *)

    val audio_track_list : t -> Audio_track.List.t
    (** [audio_track_list m] are the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/audioTracks}audio tracks} of [m]. *)

    val video_track_list : t -> Video_track.List.t
    (** [video_track_list m] are the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/videoTracks}video tracks} of [m]. *)

    val text_track_list : t -> Text_track.List.t
    (** [text_trac_list m] are the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/textTracks}text tracks} of [m]. *)

    val capture_stream : t -> Stream.t
    (** [capture_tream m] is a
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/captureStream}media stream} for [m]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end
end

(** Message events, ports, channels and broadcast channels. *)
module Message : sig

  type transfer
  (** The type for objects to transfer. *)

  val transfer : 'a -> transfer
  (** [transfer v] indicates valule [v] should be transfered, not just
      cloned, meaning they are no longer usable on the sending side. *)

  type opts
  (** The type for messaging options. *)

  val opts : ?target_origin:Jstr.t -> ?transfer:transfer list -> unit -> opts
  (** [opts ~target_origin ~transfer ()] are messaging options.
      See {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage#Syntax}here} for the semantics of [target_origin] and [transfer]. *)

  (** Message ports. *)
  module Port : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MessagePort}
        [MessagePort]} objects. *)

    external as_target : t -> Ev.target = "%identity"
    (** [as_target p] is [p] as an event target. *)

    val start : t -> unit
    (** [start p]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MessagePort/start}
        starts} [p]. *)

    val close : t -> unit
    (** [close p]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MessagePort/close}
        closes} [p]. *)

    val post : ?opts:opts -> t -> 'a -> unit
    (** [post ~opts p v]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MessagePort/postMessage} posts} value [v] on port [p] with options [opts] (the [target_origin]
        option is meaningless in this case). *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Message channels.

      See the {{:https://developer.mozilla.org/en-US/docs/Web/API/Channel_Messaging_API}Channel Messaging API}. *)
  module Channel : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MessageChannel}
        [MessageChannel]} objects. *)

    val create : unit -> t
    (** [create ()] is a {{:https://developer.mozilla.org/en-US/docs/Web/API/MessageChannel/MessageChannel}new} channel. *)

    val port1 : t -> Port.t
    (** [port c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MessageChannel/port1}first port} of [c]. The port attached to the context
        that created the channel. *)

    val port2 : t -> Port.t
    (** [port2 c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MessageChannel/port2}second port} of [c]. The port attached to the context
        at the other end of the channel. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Broadcast channels.

      See the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Broadcast_Channel_API}Broadcast Channel API}. *)
  module Broadcast_channel : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/BroadcastChannel}
        [BroadcastChannel]} objects. *)

    val create : Jstr.t -> t
    (** [create n] {{:https://developer.mozilla.org/en-US/docs/Web/API/BroadcastChannel/BroadcastChannel}creates} a channel named [n]. *)

    external as_target : t -> Ev.target = "%identity"
    (** [as_target b] is [b] as an event target. *)

    val name : t -> Jstr.t
    (** [name b] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/BroadcastChannel/name}name} of [b]. *)

    val close : t -> unit
    (** [close b] {{:https://developer.mozilla.org/en-US/docs/Web/API/BroadcastChannel/close}closes} [b]. *)

    val post : t -> 'a -> unit
    (** [post b v]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/BroadcastChannel/postMessage}sends} [v] to all listeners of {!Brr_io.Message.Ev.message}
        on [b]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  val window_post : ?opts:opts -> Window.t -> 'a -> unit
  (** [window_post w v ~opts]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage}
      posts} value [v] to window [w] with options [opts]. *)

  (** {1:events Events} *)

  (** Message events. *)
  module Ev : sig

    (** {1:obj Message event object} *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MessageEvent}
        [MessageEvent]} and
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ExtendableMessageEvent}[ExtendableMessageEvent]}
        objects. *)

    val as_extendable : t -> Ev.Extendable.t
    (** [as_extendable e] is [e] as an extendable event. {b Warning.}
        only for [ExtendableMessageEvents] objects. *)

    val data : t -> 'a
    (** [data e] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MessageEvent/data}
        data send} by the emitter. {b Warning.} Unsafe,
        make sure to constrain the result value to the right type. *)

    val origin : t -> Jstr.t
    (** [origin e] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MessageEvent/origin}
        origin} of the message emitter. *)

    val last_event_id : t -> Jstr.t
    (** [last_event_id e] is a
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MessageEvent/lastEventId}unique id} for the event. *)

    val source : t -> Jv.t option
    (** [source e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MessageEvent/source}message emitter}. *)

    val ports : t -> Port.t list
    (** [ports e] is a list of {{:https://developer.mozilla.org/en-US/docs/Web/API/MessageEvent/ports}ports} associated with the channel the message is being
        send through (if applicable). *)

    (** {1:events Events} *)

    val message : t Ev.type'
    (** [message] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/BroadcastChannel/message_event}[message]} event. *)

    val messageerror : t Ev.type'
    (** [messageerror] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/BroadcastChannel/messageerror_event}[messageerror]} event. *)

  end
end

(** Notifying users.

    See the {{:https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API}Notification API}. *)
module Notification : sig

  (** {1:perm Permission} *)

  (** Permission enum. *)
  module Permission : sig
    type t = Jstr.t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/permission#Return_Value}notification permission} values. *)

    val default : t
    val denied : t
    val granted : t
  end

  val permission : unit -> Permission.t
  (** [permission ()] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/permission}permission} granted by the user. *)

  val request_permission : unit -> Permission.t Fut.or_error
  (** [request_permission ()] {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/requestPermission}requests} permission to display
      notifications. *)

  (** {1:notifications Notifications} *)

  (** Direction enum. *)
  module Direction : sig
    type t = Jstr.t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/dir#Value}notification direction} values. *)

    val auto : t
    val ltr : t
    val rtl : t
  end

  (** Actions. *)
  module Action : sig

    val max : unit -> int
    (** [max] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/maxActions}maximum number} of actions supported. *)

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/NotificationAction}[NotificationAction]} objects. *)

    val v : ?icon:Jstr.t -> action:Jstr.t -> title:Jstr.t -> unit -> t
    (** [v ~action ~title ~icon ()] is an action with given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/NotificationAction#Properties}properties}. *)

    val action : t -> Jstr.t
    (** [action a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/NotificationAction#Properties}action name} of [a]. *)

    val title : t -> Jstr.t
    (** [title a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/NotificationAction#Properties}title} of [a]. *)

    val icon : t -> Jstr.t option
    (** [icon a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/NotificationAction#Properties}icon} of [a]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  type opts
  (** The type for notification options. *)

  val opts :
    ?dir:Direction.t -> ?lang:Jstr.t -> ?body:Jstr.t -> ?tag:Jstr.t ->
    ?image:Jstr.t -> ?icon:Jstr.t -> ?badge:Jstr.t -> ?timestamp_ms:int ->
    ?renotify:bool -> ?silent:bool -> ?require_interaction:bool -> ?data:'a ->
    ?actions:Action.t list -> unit -> opts

  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification}
      [Notification]} objects. *)

  type notification = t
  (** See {!t} . *)

  val create : ?opts:opts -> Jstr.t -> t
  (** [create title ~opts] is a
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/Notification}notification}
      with title [title] and options [opts]. *)

  val close : t -> unit
  (** [close n] {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/close}closes} [n]. *)

  external as_target : t -> Ev.target = "%identity"
  (** [as_target n] is [n] as an event target. *)

  (** {1:props Properties} *)

  val actions : t -> Action.t list
  (** [action n] are the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/actions}
      actions} of [n]. *)

  val badge : t -> Jstr.t
  (** [badge n] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/badge}
      badge} of [n]. *)

  val body : t -> Jstr.t
  (** [body n] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/body}
      body} of [n]. *)

  val data : t -> 'a
  (** [data n] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/data}
      data} of [n]. {b Warning.} This is unsafe, constrain the result type.*)

  val dir : t -> Direction.t
  (** [dir n] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/dir}
      dir} of [n]. *)

  val lang : t -> Jstr.t
  (** [lang n] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/lang}
      lang} of [n]. *)

  val tag : t -> Jstr.t
  (** [tag n] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/tag}
      tag} of [n]. *)

  val icon : t -> Jstr.t
  (** [icon n] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/icon}
      icon} of [n]. *)

  val image : t -> Jstr.t
  (** [image n] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/image}
      image} of [n]. *)

  val renotify : t -> bool
  (** [renotify n]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/renotify}
      indicates} [n] replaces an old notification. *)

  val require_interaction : t -> bool
  (** [require_interaction n]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/requireInteraction} indicates} [n] requires interaction. *)

  val silent : t -> bool
  (** [silent n]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/silent} indicates} [n] should be silent. *)

  val timestamp_ms : t -> int
  (** [timestamp_ms n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/timestamp}timestamp} of [n]. *)

  val title : t -> Jstr.t
  (** [title n] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Notification/title}
      title} of [n]. *)

  (** {1:events Events} *)

  (** Notification events. *)
  module Ev : sig

    (** {1:obj Notification event object} *)

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/NotificationEvent}[NotificationEvent]} objects. *)

    val as_extendable : t -> Ev.Extendable.t Ev.t
    (** [as_extendable e] is [e] as an extendable event. *)

    val notification : t -> notification
    (** [notification e] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/NotificationEvent/notification}notification} of [e]. *)

    val action : t -> Jstr.t
    (** [action e] is the notification {{:https://developer.mozilla.org/en-US/docs/Web/API/NotificationEvent/action}action} clicked. *)

    (** {1:evs Notification events} *)

    val notificationclick : t Ev.type'
  (** [notificationclick] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerGlobalScope/notificationclick_event}[notificationclick]} event. *)

    val notificationclose : t Ev.type'
    (** [notificationclick] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerGlobalScope/notificationclose_event}[notificationclose]} event. *)
  end

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end


(** [Storage] objects.

    See {{:https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API}
    Web Storage API} *)
module Storage : sig

  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Storage}[Storage]}
      objects. *)

  val local : Window.t -> t
  (** [local w] is the storage {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage}saved accross page sessions} for the
      window's {{:https://html.spec.whatwg.org/multipage/origin.html#concept-origin}origin}. *)

  val session : Window.t -> t
  (** [session w] is the storage {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/sessionStorage}cleared when the page session} ends for the window's {{:https://html.spec.whatwg.org/multipage/origin.html#concept-origin}origin}. *)

  val length : t -> int
  (** [length s] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Storage/length}
      number of items} in [s]. *)

  val key : t -> int -> Jstr.t option
  (** [key s i] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Storage/key}name}
      of the [i]th key. (N.B. local storage can race with other tabs) *)

  val get_item : t -> Jstr.t -> Jstr.t option
  (** [get_item s k] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Storage/getItem}
      value} of [k] in [s]. *)

  val set_item : t -> Jstr.t -> Jstr.t -> (unit, Jv.Error.t) result
  (** [set_item s k v]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Storage/setItem}sets}
      the value of [k] to [v] in [s]. An error is returned if the value could
      not be set (no permission or quota exceeded). *)

  val remove_item : t -> Jstr.t -> unit
  (** [remove_item s k]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Storage/removeItem}
      removes} the value of [k] from [s]. If [k] has no
      value this does nothing. *)

  val clear : t -> unit
  (** [clear s]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Storage/clear}
      removes} all keys from [s]. *)

  (** {1:events Events} *)

  (** Storage event. *)
  module Ev : sig

    (** {1:obj Storage event object} *)

    type storage_area = t
    (** See {!Brr_io.Storage.t} . *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/StorageEvent}
        [StorageEvent]} objects. *)

    val key : t -> Jstr.t option
    (** [key e] is the key of the item being changed. *)

    val old_value : t -> Jstr.t option
    (** [old_value e] is the old value of the key. *)

    val new_value : t -> Jstr.t option
    (** [new_value e] is the new value of the key. *)

    val url : t -> Jstr.t
    (** [url e] is the URL of the document whose storage item changed. *)

    val storage_area : t -> storage_area option
    (** [storage_area e] is the storage object. *)

    (** {1:events Storage event} *)

    val storage : t Ev.type'
    (** [storage] is the type for [storage] event fired on {!Brr.Window}s
        on storage changes. *)
  end

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** [Websocket] objects.

    See {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API}
    Web Sockets API}.

    {b XXX} Add a bit of future convenience. *)
module Websocket : sig

  (** Binary type enum. *)
  module Binary_type : sig
    type t = Jstr.t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/binaryType#Value}binary type} values. *)

    val blob : t
    val arraybuffer : t
  end

  (** Ready state enum. *)
  module Ready_state : sig
    type t = int
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/readyState#Value}ready state} values. *)

    val connecting : t
    val open' : t
    val closing : t
    val closed : t
  end

  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket}[WebSocket]}
      objects. *)

  val create : ?protocols:Jv.Jstr.t list -> Jstr.t -> t
  (** [create ~protocols url]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/WebSocket}
      creates} a new socket connected to [url]. *)

  external as_target : t -> Brr.Ev.target = "%identity"
  (** [as_target s] is [s] as an event target. *)

  val binary_type : t -> Binary_type.t
  (** [binary_type s] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/binaryType}
      type} of binary data received. *)

  val set_binary_type : t -> Binary_type.t -> unit
  (** [set_binary_type s t] sets the {!binary_type} of [s] to [t]. *)

  val close : ?code:int -> ?reason:Jstr.t -> t -> unit
  (** [close s]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/close}
      closes} [s].  *)

  (** {1:props Properties} *)

  val url : t -> Jstr.t
  (** [url s] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/url}url} of [s]. *)

  val ready_state : t -> Ready_state.t
  (** [ready_state s] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/readyState}state} of the connection. *)

  val buffered_amount : t -> int
  (** [buffered_amount s] is the sent {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/bufferedAmount}buffered amount} of [s]. *)

  val extensions : t -> Jstr.t
  (** [extensions s] are the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/extensions}
      extensions} selected by the server. *)

  val protocol : t -> Jstr.t
  (** [protocol s] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/protocol}
      protocol} selected by the server. *)

  (** {1:send Sending} *)

  val send_string : t -> Jstr.t -> unit
  (** [send_string s d]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/send}
      sends} the UTF-8 encoding of [d] on [s]. *)

  val send_blob : t -> Blob.t -> unit
  (** [send_blob s d]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/send}
      sends} the binary content of [d] on [s]. *)

  val send_array_buffer : t -> Tarray.Buffer.t -> unit
  (** [send_blob s d]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/send}
      sends} the binary content of [d] on [s]. *)

  val send_tarray : t -> ('a, 'b) Tarray.t -> unit
  (** [send_blob s d]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/send}
      sends} the binary content of [d] on [s]. *)

  (** {1:events Events} *)

  (** Websocket events. *)
  module Ev : sig

    (** Close events. *)
    module Close : sig
      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent}
          [CloseEvent]} objects. *)

      val was_clean : t -> bool
      (** [was_clean e] is [true] if closure was {{:https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent#Properties}clean}. *)

      val code : t -> int
      (** [code e] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent#Properties}close} code sent by the server. *)

      val reason : t -> Jstr.t
      (** [reason e] is the closure {{:https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent#Properties}reason}. *)

    end

    val close : Close.t Ev.type'
    (** [close] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/close_event}[close]} event. *)
  end

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end
