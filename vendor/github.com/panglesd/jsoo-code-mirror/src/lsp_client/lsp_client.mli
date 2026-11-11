open Code_mirror

module LSPClientConfig : sig
  type t

  include Jv.CONV with type t := t

  val create :
    ?root_uri:string ->
    ?workspace:(Jv.t -> Jv.t) ->
    ?timeout:int ->
    ?sanitize_html:(string -> string) ->
    ?highlight_language:(string -> Jv.t option) ->
    ?notification_handlers:(string * (Jv.t -> Jv.t -> bool)) list ->
    ?unhandled_notification:(Jv.t -> string -> Jv.t -> unit) ->
    ?extensions:Extension.t list ->
    unit ->
    t
end

module Transport : sig
  type t

  include Jv.CONV with type t := t

  val create :
    send:(Jstr.t -> unit) ->
    subscribe:((Jstr.t -> unit) -> unit) ->
    unsubscribe:((Jstr.t -> unit) -> unit) ->
    t
end

module Workspace : sig
  type t

  include Jv.CONV with type t := t

  val display_file : t -> uri:string -> View.EditorView.t option Fut.or_error
end

module LSPClient : sig
  type t

  include Jv.CONV with type t := t

  val create : ?config:LSPClientConfig.t -> unit -> t
  val connect : t -> Transport.t -> t
  val disconnect : t -> unit

  val plugin :
    t -> file_uri:string -> ?language_id:string -> unit -> Extension.t

  val initializing : t -> unit Fut.or_error
  val notification : t -> method_:string -> params:Jv.t -> unit
  val request : t -> method_:string -> params:Jv.t -> Jv.t Fut.or_error
  val connected : t -> bool
  val workspace : t -> Workspace.t
end

module LSPPlugin : sig
  type t

  include Jv.CONV with type t := t

  val client : t -> LSPClient.t
  val uri : t -> string
  val view : t -> View.EditorView.t
  val get : View.EditorView.t -> t option

  val from_position : t -> pos:Jv.t -> ?doc:State.Text.t -> unit -> int
end

module Extensions : sig
  val language_server_extensions : unit -> Extension.t list
  val jump_to_definition_keymap : Keymap.t
end
