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
  val set_color : Color.t -> unit
  val set_width : Width.t -> unit
  val set_tool : Tool.t -> unit
end

val setup : Brr.El.t -> unit
