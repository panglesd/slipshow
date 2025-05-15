val up : Universe.Window.window -> Brr.El.t -> unit Undoable.t
val down : Universe.Window.window -> Brr.El.t -> unit Undoable.t
val center : Universe.Window.window -> Brr.El.t -> unit Undoable.t
val enter : Universe.Window.window -> Brr.El.t -> unit Undoable.t
val exit : Universe.Window.window -> unit -> unit Undoable.t
val unstatic : Brr.El.t list -> unit Undoable.t
val static : Brr.El.t list -> unit Undoable.t
val focus : Universe.Window.window -> Brr.El.t list -> unit Undoable.t
val unfocus : Universe.Window.window -> unit -> unit Undoable.t
val reveal : Brr.El.t list -> unit Undoable.t
val unreveal : Brr.El.t list -> unit Undoable.t
val emph : Brr.El.t list -> unit Undoable.t
val unemph : Brr.El.t list -> unit Undoable.t
val scroll : Universe.Window.window -> Brr.El.t -> unit Undoable.t
