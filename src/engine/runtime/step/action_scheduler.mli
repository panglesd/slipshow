val is_action : Brr.El.t -> bool

module AttributeActions : sig
  val do_ : Universe.Window.t -> Brr.El.t -> unit Undoable.t
end

val all_action_selector : string
val setup_actions : Universe.Window.t -> unit -> unit Fut.t

val next : ?init:bool -> Universe.Window.t -> unit -> unit Undoable.t option
(** [init] tells whether to update the history: Set true only for the first
    advance *)
