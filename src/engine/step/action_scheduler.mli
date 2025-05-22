val is_action : Brr.El.t -> bool
val all_action_selector : string
val setup_pause_ancestors : unit -> unit Undoable.t
val next : Universe.Window.window -> unit -> unit Undoable.t option
