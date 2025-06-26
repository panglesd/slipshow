val actualize : unit -> unit
val go_next : Universe.Window.t -> int -> unit Fut.t
val go_prev : 'a -> int -> unit Fut.t
val goto : int -> Universe.Window.t -> unit Fut.t
