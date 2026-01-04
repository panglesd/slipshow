module ChangeSet : sig
  type t

  val toJSON : t -> Brr.Json.t
  val fromJSON : Brr.Json.t -> t

  include Jv.CONV with type t := t
end

module State : sig
  type t

  include Jv.CONV with type t := t

  module Config : sig
    type t

    (* TODO: Add selection *)
    val create :
      ?doc:Jstr.t ->
      ?selection:Jv.t ->
      ?extensions:Extension.t array ->
      unit ->
      t
  end

  module Transaction : sig
    type state := t
    type t

    val startState : t -> state
    val changes : t -> ChangeSet.t
    val scrollIntoView : t -> bool
    val newDoc : t -> Text.t
    val state : t -> state
    val docChanged : t -> bool
    val reconfigured : t -> bool

    include Jv.CONV with type t := t
  end

  module type Facet = sig
    type t

    include Jv.CONV with type t := t

    type input
    type output

    val of_ : t -> input -> Extension.t
  end

  module FacetMaker : functor
    (I : sig
       type t

       include Jv.CONV with type t := t
     end)
    -> Facet with type input = I.t

  type ('i, 'o) facet =
    | Facet :
        (module Facet with type input = 'i and type output = 'o and type t = 'a)
        * 'a
        -> ('i, 'o) facet

  val create : ?config:Config.t -> unit -> t
  val doc : t -> Text.t
end

module View : sig
  type t
  (** Editor view *)

  include Jv.CONV with type t := t

  type opts
  (** Configurable options for the editor view *)

  (* TODO: Dispatch function *)
  val opts :
    ?state:State.t ->
    ?parent:Brr.El.t ->
    ?root:Brr.El.document ->
    ?dispatch:Jv.t ->
    unit ->
    opts

  val create : ?opts:opts -> unit -> t
  (** Create a new view *)

  val dispatch : t -> State.Transaction.t list -> Jv.t

  val state : t -> State.t
  (** Current editor state *)

  val set_state : t -> State.t -> unit

  module Update : sig
    type t

    val state : t -> State.t
    val changes : t -> ChangeSet.t
    val docChanged : t -> bool

    include Jv.CONV with type t := t
  end

  module ViewPlugin : sig
    type plugin_value = { update : Update.t -> unit; destruct : unit -> unit }

    val define : (t -> plugin_value) -> Extension.t
  end

  val dom : t -> Brr.El.t
  val update_listener : unit -> (Update.t -> unit, Jv.t) State.facet
  val line_wrapping : unit -> Extension.t
end
