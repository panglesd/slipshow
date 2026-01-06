val is_action : Brr.El.t -> bool

module AttributeActions : sig
  val do_ : Brr.Window.t -> Universe.Window.t -> Brr.El.t -> unit Undoable.t
end

val all_action_selector : string
val setup_actions : Brr.Window.t -> Universe.Window.t -> unit -> unit Fut.t
val next : Brr.Window.t -> Universe.Window.t -> unit -> unit Undoable.t option
