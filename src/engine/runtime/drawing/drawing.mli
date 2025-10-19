open Types
module Color = Color
module Width = Width
module Tool = Tool
module State = State
module Event = Event
module Action = Action
module Stroke = Stroke
module Tools = Tools

val setup : Brr.El.t -> unit
val send_all_strokes : unit -> unit
val receive_all_strokes : string list -> unit
