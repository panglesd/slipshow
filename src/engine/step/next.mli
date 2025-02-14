val actualize : unit -> unit
val go_next : Universe.Window.window -> int -> unit Fut.t
val go_prev : 'a -> int -> unit Fut.t
val goto : int -> Universe.Window.window -> unit Fut.t
