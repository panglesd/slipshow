val actualize : int -> unit
val go_next : send_message:bool -> Universe.Window.t -> Fast.mode -> unit Fut.t
val go_prev : send_message:bool -> Universe.Window.t -> Fast.mode -> unit Fut.t

val go_to :
  mode:Fast.mode -> send_message:bool -> int -> Universe.Window.t -> unit Fut.t
