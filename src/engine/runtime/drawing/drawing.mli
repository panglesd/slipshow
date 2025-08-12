module Color : sig
  type t = Red | Blue | Green | Black | Yellow
end

module Width : sig
  type t = Small | Medium | Large
end

module Tool : sig
  type t = Pen | Highlighter | Eraser | Pointer
end

module State : sig
  type t

  val set_color : Color.t -> unit
  val set_width : Width.t -> unit
  val set_tool : Tool.t -> unit
  val get_tool : unit -> Tool.t
  val of_string : string -> t option
end

val setup : Brr.El.t -> unit
val clear : unit -> unit

(* val add_drawing : string -> (float * float) list -> unit *)
val end_shape_func : State.t -> unit
val start_shape_func : string -> State.t -> float * float -> unit
val continue_shape_func : State.t -> float * float -> unit
val clear_func : unit -> unit
