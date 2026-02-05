val is_action : Brr.El.t -> bool

module AttributeActions : sig
  val do_ : mode:Fast.mode -> Universe.Window.t -> Brr.El.t -> unit Undoable.t
end

val all_action_selector : string
val setup_actions : Universe.Window.t -> unit -> unit Fut.t
val next : mode:Fast.mode -> Universe.Window.t -> unit -> unit Undoable.t option
