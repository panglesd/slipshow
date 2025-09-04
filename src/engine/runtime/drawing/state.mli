module Button : sig
  val tool : Types.Tool.t -> Brr.El.t
  val color : Types.Color.t -> Brr.El.t
  val width : Types.Width.t -> Brr.El.t
  val clear : unit -> Brr.El.t
end

type t = { color : Types.Color.t; width : Types.Width.t; tool : Types.Tool.t }

val of_string : string -> t option
val to_string : t -> string
val get_state : unit -> t
val set_color : Types.Color.t -> unit
val set_width : Types.Width.t -> unit
val set_tool : Types.Tool.t -> unit
val get_tool : unit -> Types.Tool.t

module Strokes : sig
  type t = (string, Brr.El.t * Types.Stroke.t) Hashtbl.t

  val all : t
  val remove_id : string -> unit
  val remove_el : Brr.El.t -> unit
end

type drawing_state =
  | Drawing of Brr.El.t * Types.Stroke.t * int
  | Erasing of (float * float)
  | Pointing

val current_drawing_state : drawing_state ref
