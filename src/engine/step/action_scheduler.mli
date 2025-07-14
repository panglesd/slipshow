val is_action : Brr.El.t -> bool
val all_action_selector : string
val setup_pause_ancestors : Universe.Window.t -> unit -> unit Undoable.t

val next : ?init:bool -> Universe.Window.t -> unit -> unit Undoable.t option
(** [init] tells whether to update the history: Set true only for the first
    advance *)
