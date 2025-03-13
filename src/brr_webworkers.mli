(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Web and Service Worker APIs. *)

open Brr

(** Web workers.

    See the {{:https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API}
    Web Workers API}. *)
module Worker : sig

  (** {1:enums Enumerations} *)

  (** The worker type enum. *)
  module Type : sig
    type t = Jstr.t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Worker/Worker#Parameters}worker type} values. *)

    val classic : t
    val module' : t
  end

  (** {1:workers Workers} *)

  type opts
  (** The type for worker options. *)

  val opts :
    ?type':Type.t -> ?credentials:Brr_io.Fetch.Request.Credentials.t ->
    ?name:Jstr.t -> unit -> opts
 (** [opts ~type' ~credentials ~name ()] are worker options
     with given parameters. See {{:https://developer.mozilla.org/en-US/docs/Web/API/Worker/Worker#Parameters}here} for defaults and semantics. *)

  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Worker/Worker}
      [Worker]} objects. *)

  val create : ?opts:opts -> Jstr.t -> t
  (** [create ~opts uri]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Worker/Worker}
      creates} a worker that executes the script [uri]. This may
      throw a {!exception:Jv.Error} exception. *)

  external as_target : t -> Ev.target = "%identity"
  (** [as_target w] is [w] as an event target. *)

  val terminate : t -> unit
  (** [terminate w]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Worker/terminate}
      terminates} worker [w]. *)

  val post : ?opts:Brr_io.Message.opts -> t -> 'a -> unit
  (** [post ~opts w v]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Worker/postMessage}
      posts} value [v] on port [p] with options [opts] (the
      [target_origin] option is meaningless in this case). *)

  (** {1:shared Shared workers} *)

  (** Shared workers. *)
  module Shared : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/SharedWorker}
        [SharedWorker]} objects. *)

    val create : ?opts:opts -> Jstr.t -> t
    (** [create ~opts uri]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/SharedWorker/SharedWorker} creates} a shared worker that executes the script [uri]. This may
        throw a {!exception:Jv.Error} exception. *)

    external as_target : t -> Ev.target = "%identity"
    (** [as_target w] is [w] as an event target. *)

    val port : t -> Brr_io.Message.Port.t
    (** [port w] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/SharedWorker/port}
        port} of [w]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** {1:worker_funs Worker context}

      These APIs are used by the workers. *)

  val ami : unit -> bool
  (** [ami ()] is [true] if we are executing in a worker context. *)

  (** Worker global functions *)
  module G : sig

    val import_scripts : Jstr.t list -> unit
    (** [import_scripts uris] synchronously
        {{:https://developer.mozilla.org/en-US/docs/Web/API/WorkerGlobalScope/importScripts}imports} the given scripts in the worker. *)

    val post : ?opts:Brr_io.Message.opts -> 'a -> unit
    (** [post ~opts v]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Worker/postMessage}
        posts} value [v] on the global object with options [opts] (the
        [target_origin] option is meaningless in this case). *)

    val close : unit -> unit
    (** [close ()] {{:https://developer.mozilla.org/en-US/docs/Web/API/DedicatedWorkerGlobalScope/close}closes} this worker scope. *)
  end

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** Service workers.

    See the {{:https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API}Service Worker API}.

    The fetch caches and events are in {!Brr_io.Fetch}. *)
module Service_worker : sig

  (** {1:registration Registration}

      These APIs are used by the web page to install the service worker.
      Start your journey with {!Service_worker.Container.of_navigator}. *)

  (** Update via cache enum. *)
  module Update_via_cache : sig
    type t = Jstr.t
    (** The type for {{:https://w3c.github.io/ServiceWorker/#enumdef-serviceworkerupdateviacache}update via cache} values. *)

    val imports : t
    val all : t
    val none : t
  end

  (** State enum. *)
  module State : sig
    type t = Jstr.t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerState}state} values. *)

    val parsed : t
    val installing : t
    val installed : t
    val activating : t
    val activated : t
    val redundant : t
  end

  type t
  (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorker}ServiceWorker} objects. *)

  type service_worker = t
  (** See {!t}. *)

  external as_worker : t -> Worker.t = "%identity"
  (** [as_worker w] is [w] as a worker. *)

  external as_target : t -> Ev.target = "%identity"
  (** [as_target w] is [w] as an event target. *)

  val script_url : t -> Jstr.t
  (** [script_url w] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorker/scriptURL}script URL} specified during registration for [w]. *)

  val state : t -> State.t
  (** [state w] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorker/state}state} of [w]. *)

  (** Ressources preloading *)
  module Navigation_preload_manager : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/NavigationPreloadManager}[NavigationPreload]} objects. *)

    val enable : t -> unit Fut.or_error
    (** [enable p] {{:https://developer.mozilla.org/en-US/docs/Web/API/NavigationPreloadManager#Methods}enables} navigation preloading. *)

    val disable : t -> unit Fut.or_error
    (** [disables p] {{:https://developer.mozilla.org/en-US/docs/Web/API/NavigationPreloadManager#Methods}disables} navigation preloading. *)

    val set_header_value : t -> Jstr.t -> unit Fut.or_error
    (** [set_header_value p v] {{:https://developer.mozilla.org/en-US/docs/Web/API/NavigationPreloadManager#Methods}sets} the value of the header. *)

    val get_state : t -> (bool * Jstr.t) Fut.or_error
    (** [get_state p] {{:https://developer.mozilla.org/en-US/docs/Web/API/NavigationPreloadManager#Methods}indicates} whether preload is enabled and
        the value of the header. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Service registration objects. *)
  module Registration : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration}[ServiceWorkerRegistration]} objects. *)

    external as_target : t -> Ev.target = "%identity"
    (** [as_target r] is [r] as an event target. *)

    val update : t -> unit Fut.or_error
    (** [update r] attempts to {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/update}update} the service worker of [r]. *)

    val unregister : t -> bool Fut.or_error
    (** [unregister r]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/unregister}unregisters} the service worker registration. This is [false]
        if no registration was false. *)

    val show_notification :
      ?opts:Brr_io.Notification.opts -> t -> Jstr.t -> unit Fut.or_error
    (** [show_notification r title ~opts]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/showNotification}displays} a notification with title [title] an options
        [opts]. *)

    val get_notifications :
      ?tag:Jstr.t -> t -> Brr_io.Notification.t list Fut.or_error
    (** [get_notifications r ~tag] are {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/getNotifications}notifications} created via [r] and tagged with [tag] (or all of them if unspecified). *)

    (** {1:props Properties} *)

    val installing : t -> service_worker option
    (** [installing r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/installing}installing} service worker of [r]. *)

    val waiting : t -> service_worker option
    (** [waiting r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/waiting}installed} service worker of [r]. *)

    val active : t -> service_worker option
    (** [active r] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/active}active} service worker of [r]. *)

    val navigation_preload : t -> Navigation_preload_manager.t
    (** [navigation_preload r] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/navigationPreload}
        navigation preload manager} of [r]. *)

    val scope : t -> Jstr.t
    (** [scope r] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/scope}scope} of [r]. *)

    val update_via_cache : t -> Update_via_cache.t
    (** [update_via_cache r] is the update via cache property of [r]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Service worker containers. *)
  module Container : sig

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerContainer}ServiceWorkerContainer} objects. *)

    val of_navigator : Navigator.t -> t
    (** [of_navigator n] is the service worker container of
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Navigator/serviceWorker}navigator} [n]. *)

    external as_target : t -> Ev.target = "%identity"
    (** [as_target c] is [c] as an event target. *)

    val controller : t -> service_worker option
    (** [controller c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerContainer/controller}active} service worker if any. *)

    val ready : t -> Registration.t Fut.or_error
    (** [ready c] is a future that resolves when a service worker is
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerContainer/ready}active}. *)

    type register_opts
    (** The type for worker registration options. *)

    val register_opts :
      ?scope:Jstr.t -> ?type':Worker.Type.t ->
      ?update_via_cache:Update_via_cache.t -> unit -> register_opts
    (** [register_opts ~scope ~type ~update_via_cache] ()
        are registration options with given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerContainer/register#Parameters}properties}. *)

    val register :
      ?register_opts:register_opts -> t -> Jstr.t -> Registration.t Fut.or_error
    (** [register c script_uri ~register_opts] {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerContainer/register}creates or updates} a
        registration with [script_url]. *)

    val get_registration :
      t -> Jstr.t option -> Registration.t option Fut.or_error
    (** [get_registration c url] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerContainer/getRegistration}registration} for
        [url] (if any). *)

    val get_registrations : t -> Registration.t list Fut.or_error
    (** [get_registrations c] are {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerContainer/getRegistrations}all} the registration fo [c]. *)

    val start_messages : t -> unit
    (** [start_messages c]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerContainer/startMessages}starts} the flow of messages from the service worker to the
        pages. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** {1:worker_funs Service worker context}

      These APIs are used by the service worker. *)

  (** Client objects. *)
  module Client : sig

    (** {1:enum Enumerations} *)

    (** Visibility state enum. *)
    module Visibility_state : sig
      type t = Jstr.t
      (** The type for visibility state values. *)

      val hidden : t
      val visible : t
    end

    (** Client type enum. *)
    module Type : sig
      type t = Jstr.t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/Client/type#Value}
          client type} values.  *)

      val window : t
      val worker : t
      val sharedworker : t
      val all : t
    end

    (** Frame type enum. *)
    module Frame_type : sig
      type t = Jstr.t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/Client/frameType}
          frame type} values. *)

      val auxiliary : t
      val top_level : t
      val nested : t
      val none : t
    end

    (** {1:clients Clients} *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Client}[Client]}
        objects. *)

    type client = t
    (** See {!t}. *)

    val url : t ->  Jstr.t
    (** [url c] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Client/url}URL}
        of [c]. *)

    val frame_type : t ->  Frame_type.t
    (** [frame_type c] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Client/frameType}
        frame type} of [c]. *)

    val id : t ->  Jstr.t
    (** [id c] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Client/id}id}
        of [c]. *)

    val type' : t -> Type.t
    (** [type' c] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Client/type}type}
        of [c]. *)

    val post : ?opts:Brr_io.Message.opts -> t -> 'a -> unit
    (** [post ~opts c v]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Client/postMessage} posts} value [v] to client [c] with options [opts] (the [target_origin]
        option is meaningless in this case). *)

    (** {1:window Window clients} *)

    (** Window clients. *)
    module Window : sig
        type t
        (** The type for
            {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowClient}
            [WindowClient]} objects. *)

        external as_client : t -> client = "%identity"
        (** [as_client w] is [w] as a client. *)

        val visibility_state : t -> Visibility_state.t
        (** [visibility_state w] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowClient/visibilityState}visibility} state of [w]. *)

        val focused : t ->  bool
        (** [focused w] {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowClient/focused}indicates} if [w] is focused. *)

        val ancestor_origins : t -> Jstr.t list
        (** [ancestor_origins w] are the {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowClient/ancestorOrigins}ancestor origins} of [w]. *)

        val focus : t ->  t Fut.or_error
        (** [focus w] {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowClient/focus}focuses} [w]. *)

        val navigate : t -> Jstr.t -> t Fut.or_error
        (** [navigate w uri] {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowClient/navigate}loads} [uri] in [w]. *)

        (**/**)
        include Jv.CONV with type t := t
        (**/**)
      end
    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Clients objects. *)
  module Clients : sig

    type query_opts
    (** The type for query options. *)

    val query_opts :
      ?include_uncontrolled:bool -> ?type':Client.Type.t -> unit -> query_opts
    (** [query_opts ~include_uncontrolled ~type' ()] are query options
        with the given {{:https://developer.mozilla.org/en-US/docs/Web/API/Clients/matchAll#Parameters}properties}. *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Clients}[Clients]}
        objects. *)

    val get : t -> Jstr.t -> Client.t option Fut.or_error
    (** [get cs id] is a client {{:https://developer.mozilla.org/en-US/docs/Web/API/Clients/get}matching} [id] (if any). *)

    val match_all : ?query_opts:query_opts -> t -> Client.t list Fut.or_error
    (** [match_all cs ~query_opts] are clients {{:https://developer.mozilla.org/en-US/docs/Web/API/Clients/matchAll}matching} [query_opts]. *)

    val open_window : t -> Jstr.t -> Client.Window.t option Fut.or_error
    (** [open_window cs uri] {{:https://developer.mozilla.org/en-US/docs/Web/API/Clients/openWindow}opens} a window on [uri]. *)

    val claim : t -> unit Fut.or_error
    (** [claim cs]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Clients/claim}sets}
        the calling service worker as a controller for all clients in
        its scope. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Service worker global properties and functions. *)
  module G : sig

    (** See also {!Brr.G} and {!Brr_io.Fetch.caches}. *)

    val clients : Clients.t
    (** [clients] are the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerGlobalScope/clients}clients} associated with the service worker. *)

    val registration : Registration.t
    (** [registration] is the service worker
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerGlobalScope/registration}registration}. *)

    val service_worker : t
    (** [service_worker] is the service worker. *)

    val skip_waiting : unit -> unit Fut.or_error
    (** [skip_waiting ()]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerGlobalScope/skipWaiting}forces} the waiting service to become
        the active service worker. *)
  end

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end
